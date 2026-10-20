import XCTest
import UIKit
import Vision

private final class ClipboardTextResult: @unchecked Sendable {
    private let lock = NSLock()
    private var text: String?
    func store(_ value: String?) { lock.withLock { text = value } }
    func value() -> String? { lock.withLock { text } }
}

private final class ClipboardImageResult: @unchecked Sendable {
    private let lock = NSLock()
    private var image: UIImage?
    private var types: [String] = []

    func store(_ image: UIImage?, types: [String]) {
        lock.withLock { self.image = image; self.types = types }
    }
    func value() -> UIImage? { lock.withLock { image } }
    func typeDescription() -> String { lock.withLock { types.joined(separator: ", ") } }
}

// Dominant luminance band estimates the ground despite fine grain. A 1% tail
// avoids isolated extreme pixels and selects the text side in either appearance.
private func measuredContrast(_ image: CGImage) -> (ratio: Double, background: Double, text: Double)? {
    let width = image.width
    let height = image.height
    guard width > 0, height > 0, let space = CGColorSpace(name: CGColorSpace.sRGB) else { return nil }
    var pixels = [UInt8](repeating: 0, count: width * height * 4)
    let decoded = pixels.withUnsafeMutableBytes { memory -> Bool in
        guard let context = CGContext(data: memory.baseAddress, width: width, height: height,
                                      bitsPerComponent: 8, bytesPerRow: width * 4, space: space,
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue) else { return false }
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        return true
    }
    guard decoded else { return nil }
    func linear(_ byte: UInt8) -> Double {
        let value = Double(byte) / 255
        return value <= 0.04045 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
    }
    var luminances: [Double] = []
    var counts = [Int](repeating: 0, count: 16)
    var totals = [Double](repeating: 0, count: 16)
    luminances.reserveCapacity(width * height)
    for index in stride(from: 0, to: pixels.count, by: 4) {
        // A transparent image cannot establish the displayed background.
        guard pixels[index + 3] == 255 else { return nil }
        let value = 0.2126 * linear(pixels[index]) + 0.7152 * linear(pixels[index + 1]) + 0.0722 * linear(pixels[index + 2])
        luminances.append(value)
        let band = min(15, Int(value * 16))
        counts[band] += 1
        totals[band] += value
    }
    guard let dominant = counts.indices.max(by: { counts[$0] < counts[$1] }), counts[dominant] > 0 else { return nil }
    let background = totals[dominant] / Double(counts[dominant])
    luminances.sort()
    let tail = Int(Double(luminances.count - 1) * 0.01)
    let dark = luminances[tail]
    let light = luminances[luminances.count - 1 - tail]
    let text = abs(dark - background) >= abs(light - background) ? dark : light
    return ((max(background, text) + 0.05) / (min(background, text) + 0.05), background, text)
}
final class HarnessShellUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    func testActivitySheetSystemTextEvidence() throws {
        // No app-only largest-text override: both SwiftUI and UIKit inherit the system setting.
        let app = app(extra: fixedSpread, audit: true)
        scrollTo(app.buttons["draw-card-3"], in: app)
        tapWhenSettled(app.buttons["draw-card-3"])
        scrollTo(app.buttons["turn-over"], in: app)
        app.buttons["turn-over"].tap()
        captureSystemShareSheet(app, title: "The Star, upright", name: "03-reveal--share-sheet-system-text")
        XCTAssertEqual(app.staticTexts["card-name"].label, "The Star")
        scrollTo(app.buttons["see-meaning"], in: app)
        app.buttons["see-meaning"].tap()
        scrollTo(app.buttons["today-ask"], in: app)
        app.buttons["today-ask"].tap()
        makeQuestionReading(app, largest: true)
        let question = app.staticTexts["reading-question"].label
        captureSystemShareSheet(app, title: "Relationship reading", name: "09-reading--share-sheet-system-text")
        XCTAssertEqual(app.staticTexts["reading-question"].label, question)
        app.terminate()
    }

    private func captureSystemShareSheet(_ app: XCUIApplication, title: String, name: String) {
        scrollTo(app.buttons["share-image"], in: app)
        app.buttons["share-image"].tap()
        let heading = app.otherElements["LP.CaptionBar.TopCaption"]
        let close = app.buttons["Close"]
        XCTAssertTrue(heading.waitForExistence(timeout: 5))
        XCTAssertEqual(heading.label, title)
        XCTAssertTrue(close.isHittable)
        waitForSettled([heading, close])
        keepSystemScreenshot(name)
        let copy = app.cells["Copy"]
        let files = app.cells["Save to Files"]
        var copyWasReachable = copy.isHittable
        for stop in 0..<4 {
            if files.exists && files.isHittable && app.windows.firstMatch.frame.contains(files.frame) { break }
            app.swipeUp()
            waitForSettled([close])
            copyWasReachable = copyWasReachable || copy.isHittable
            keepSystemScreenshot("\(name)-scroll-\(stop)")
        }
        XCTAssertTrue(copyWasReachable, "A sharing choice must remain reachable with the configured system text size")
        XCTAssertTrue(files.isHittable)
        XCTAssertTrue(close.isHittable)
        close.tap()
        waitForShareReturn(app)
    }

    private func keepSystemScreenshot(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testActivitySheetSharesCardAndReadingImagesAndCancels() throws {
        let app = app(extra: fixedSpread, audit: true)
        reveal(app)
        let cardName = app.staticTexts["card-name"].label
        app.buttons["share-image"].tap()
        XCTAssertTrue(app.cells["Copy"].waitForExistence(timeout: 5))
        captureShareSheet(app, named: "03-reveal--share-sheet")
        app.buttons["Close"].tap()
        waitForShareReturn(app)
        XCTAssertEqual(app.staticTexts["card-name"].label, cardName)
        XCTAssertFalse(app.staticTexts["today-title"].exists)
        let cardImage = try copySharedImage(app, named: "share-card-image")
        let cardText = try recognisedText(in: cardImage)
        for text in [cardName, "Upright", "For entertainment and reflection"] {
            XCTAssertTrue(cardText.contains(normalised(text)), "Missing image text: \(text)")
        }

        app.buttons["see-meaning"].tap()
        app.buttons["tab-ask"].tap()
        scrollTo(app.buttons["ask-question-entry"], in: app)
        app.buttons["ask-question-entry"].tap()
        let field = app.descendants(matching: .any)["question-field"].firstMatch
        field.tap()
        let question = "How can I make room for a thoughtful conversation while respecting my own needs and giving the other person time to explain what matters to them?"
        field.typeText(question)
        app.keyboards.buttons["Done"].tap()
        app.buttons["submit-question"].tap()
        chooseSpread(app)
        app.buttons["read-spread"].tap()
        XCTAssertTrue(app.staticTexts["reading-question"].waitForExistence(timeout: 5))
        var passages: [String] = []
        for identifier in ["reading-situation", "reading-action", "reading-outcome", "reading-lens", "reflection-question"] {
            scrollTo(app.staticTexts[identifier], in: app)
            passages.append(app.staticTexts[identifier].label)
        }
        scrollTo(app.buttons["share-image"], in: app)
        capture(app, "09-reading--shared-source")
        app.buttons["share-image"].tap()
        XCTAssertTrue(app.cells["Copy"].waitForExistence(timeout: 5))
        captureShareSheet(app, named: "09-reading--share-sheet")
        app.buttons["Close"].tap()
        waitForShareReturn(app)
        XCTAssertEqual(app.staticTexts["reading-question"].label, "“\(question)”")
        let readingImage = try copySharedImage(app, named: "share-reading-image")
        XCTAssertGreaterThan(readingImage.size.height, cardImage.size.height * 2,
                             "The reading image must grow beyond one screen rather than crop its text")
        let readingText = try recognisedText(in: readingImage)
        for text in [question, "The Star", "The Sun", "The Fool", "Reversed", "Read together",
                     "For entertainment and reflection, not a prediction"] + passages {
            XCTAssertTrue(readingText.contains(normalised(text)), "Missing image text: \(text)\nOCR: \(readingText)")
        }
        XCTAssertTrue(app.buttons["reading-done"].exists)
        XCTAssertEqual(app.staticTexts["reading-question"].label, "“\(question)”")
    }

    private func waitForShareReturn(_ app: XCUIApplication) {
        let returned = XCTNSPredicateExpectation(predicate: NSPredicate(format: "hittable == true"),
                                                object: app.buttons["share-image"])
        XCTAssertEqual(XCTWaiter.wait(for: [returned], timeout: 5), .completed,
                       "Closing or completing the native sheet must restore the same usable screen")
    }

    private func captureShareSheet(_ app: XCUIApplication, named name: String) {
        // The remote sheet rebuilds its descendants; settle its visible controls by label.
        waitForSettled([app.cells["Copy"], app.buttons["Close"]])
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func copySharedImage(_ app: XCUIApplication, named name: String) throws -> UIImage {
        UIPasteboard.general.items = []
        app.buttons["share-image"].tap()
        XCTAssertTrue(app.cells["Copy"].waitForExistence(timeout: 5))
        app.cells["Copy"].tap()
        waitForShareReturn(app)
        let result = ClipboardImageResult()
        let loaded = expectation(description: "Read the image copied by the native sheet")
        // A cross-app read can wait for permission; keep the test thread free to answer it.
        DispatchQueue.global(qos: .userInitiated).async {
            result.store(UIPasteboard.general.image, types: UIPasteboard.general.types)
            loaded.fulfill()
        }
        let allowPaste = XCUIApplication(bundleIdentifier: "com.apple.springboard").buttons["Allow Paste"]
        if allowPaste.waitForExistence(timeout: 5) { allowPaste.tap() }
        wait(for: [loaded], timeout: 5)
        let image = try XCTUnwrap(result.value(), "The system share sheet must receive an image; copied types: \(result.typeDescription())")
        let attachment = XCTAttachment(image: image)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
        return image
    }

    private func normalised(_ text: String) -> String {
        text.lowercased().filter { $0.isLetter || $0.isNumber }
    }

    private func recognisedText(in image: UIImage) throws -> String {
        let pixels = try XCTUnwrap(image.cgImage)
        // Overlapping strips keep Vision from downsampling a long image until its type is unreadable.
        var lines: [(y: CGFloat, text: String)] = []
        for top in stride(from: 0, to: pixels.height, by: 1000) {
            let cropTop = max(0, top - 100)
            let height = min(pixels.height, top + 1100) - cropTop
            let strip = try XCTUnwrap(pixels.cropping(to: CGRect(x: 0, y: cropTop, width: pixels.width, height: height)))
            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["en-GB"]
            try VNImageRequestHandler(cgImage: strip).perform([request])
            for observation in request.results ?? [] {
                if let text = observation.topCandidates(1).first?.string {
                    let y = CGFloat(cropTop) + (1 - observation.boundingBox.midY) * CGFloat(height)
                    // Keep each line once, fully inside a strip's overlapping margins.
                    if y >= CGFloat(top), y < CGFloat(top + 1000) {
                        lines.append((y, text))
                    }
                }
            }
        }
        return normalised(lines.sorted { $0.y < $1.y }.map(\.text).joined(separator: " "))
    }

    private func app(extra: [String] = [], memory: Bool = true, seed: String = "deck-reference-583", date: String = "2026-10-11T00:00:00Z", animations: Bool = false, audit: Bool = false, welcome: Bool = false, reminderInvitation: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--test-mode", "--test-date", date,
                               "--test-time-zone", "Australia/Sydney", "--test-seed", seed]
        if memory { app.launchArguments.append("--test-memory-store") }
        if !animations { app.launchArguments.append("--test-disable-animations") }
        app.launchArguments += extra
        if audit { app.launchArguments.append("--test-reduce-motion") }
        if !welcome { app.launchArguments.append("--test-welcome-completed") }
        if !reminderInvitation { app.launchArguments.append("--test-reminder-answered") }
        app.launch()
        return app
    }

    // Capture the requested stop, then audit overlapping stops until every deferred element is covered.
    private func auditAndCapture(_ app: XCUIApplication, _ name: String, today: Bool = false,
                                 revealDeferred: ((XCUIElement) -> Void)? = nil,
                                 expecting elements: XCUIElement...) throws {
        XCTAssertTrue(app.launchArguments.contains("--test-reduce-motion"), "Audit fixtures must disable animations")
        if !elements.isEmpty { waitForSettled(elements) }
        if today {
            let viewport = visibleFrame(in: app)
            let card = app.buttons["today-card"].frame
            XCTAssertTrue(viewport.contains(card) || card.maxY <= viewport.minY,
                          "Today audits must not start with a cropped card illustration")
        }
        capture(app, name)
        var records: [[String: String]] = []
        defer {
            let data = try? JSONSerialization.data(withJSONObject: records, options: [.prettyPrinted, .sortedKeys])
            let attachment = XCTAttachment(string: data.map { String(decoding: $0, as: UTF8.self) } ?? "[]")
            attachment.name = "accessibility-audit-" + name
            attachment.lifetime = .keepAlways
            add(attachment)
        }
        var deferred: [String: XCUIElement] = [:]
        var deferredFrames: [String: CGRect] = [:]
        var covered = Set<String>()
        for _ in 0..<12 {
            let viewport = scrollViewport(in: app)
            var framesBeforeResizing = deferred.mapValues { $0.exists ? $0.frame : CGRect.null }
            let fullyVisibleBefore = framesBeforeResizing.keys.filter {
                let frame = framesBeforeResizing[$0]!
                let bounds = auditViewport(for: deferred[$0]!, in: app, contentViewport: viewport)
                return !frame.isEmpty && bounds.contains(frame)
            }
            var deferredAtThisStop = Set<String>()
            let handleIssue: (XCUIAccessibilityAuditIssue) throws -> Bool = { issue in
                guard issue.auditType == .contrast, let element = issue.element,
                      element.exists, !element.frame.isEmpty else { return false }
                let frame = element.frame
                // Only uniquely identifiable nodes can be tracked across scroll stops.
                let identifier = element.identifier
                let query = app.descendants(matching: element.elementType)
                let matches = identifier.isEmpty
                    ? query.matching(NSPredicate(format: "label == %@", element.label))
                    : query.matching(identifier: identifier)
                guard matches.count == 1 else { return false }
                let key = "\(element.elementType.rawValue):" + (identifier.isEmpty ? "label:\(element.label)" : "id:\(identifier)")
                let elementViewport = self.auditViewport(for: element, in: app, contentViewport: viewport)
                var record = ["identifier": element.identifier, "elementKey": key, "label": element.label,
                              "frame": String(describing: frame), "viewport": String(describing: elementViewport),
                              "nativeIssue": issue.compactDescription]
                if self.isNotFullyVisible(frame, in: elementViewport) {
                    print("Audit deferred \(key): \(frame), viewport \(elementViewport)")
                    deferred[key] = matches.firstMatch
                    deferredFrames[key] = frame
                    if framesBeforeResizing[key] == nil {
                        framesBeforeResizing[key] = matches.firstMatch.frame
                    }
                    deferredAtThisStop.insert(key)
                    record["disposition"] = "deferred-until-fully-visible"
                    record["alreadyAuditedFullyVisible"] = String(covered.contains(key))
                    records.append(record)
                    return true
                }
                guard !elementViewport.isNull && elementViewport.contains(frame) else { return false }
                // A mixed accessibility group can hide low-contrast text behind
                // high-contrast art. Only plain static text supports this measure.
                guard element.elementType == .staticText,
                      element.descendants(matching: .any).allElementsBoundByIndex.allSatisfy({ $0.elementType == .staticText }) else {
                    return false
                }
                let screenshot = element.screenshot()
                guard let image = screenshot.image.cgImage, let measured = measuredContrast(image) else {
                    return false
                }
                record["ratio"] = String(measured.ratio)
                record["backgroundLuminance"] = String(measured.background)
                record["textLuminance"] = String(measured.text)
                record["disposition"] = measured.ratio >= 4.5 ? "dismissed-measured-contrast" : "failed-measured-contrast"
                records.append(record)
                let evidence = XCTAttachment(screenshot: screenshot)
                evidence.name = "contrast-element-\(name)-\(records.count)"
                evidence.lifetime = .keepAlways
                self.add(evidence)
                print("Audit measured \(key): \(measured.ratio):1, \(record["disposition"]!)")
                if measured.ratio >= 4.5 { return true }
                return false
            }
            // Text clipping and Dynamic Type can disturb geometry; inspect other
            // categories first and retain the pre-resizing frames for navigation.
            let auditTypes: [XCUIAccessibilityAuditType] = [
                .elementDetection, .contrast, .hitRegion, .sufficientElementDescription,
                .trait, .textClipped, .dynamicType
            ]
            for auditType in auditTypes {
                try app.performAccessibilityAudit(for: auditType, handleIssue)
            }
            waitForStableFrames(app)
            covered.formUnion(fullyVisibleBefore.filter {
                !deferredAtThisStop.contains($0)
            })
            if !covered.isEmpty { print("Audit fully visible: \(covered.sorted())") }
            guard let key = deferred.keys.sorted().first(where: { !covered.contains($0) }) else { break }
            let target = deferred[key]!
            XCTAssertTrue(target.waitForExistence(timeout: 10),
                          "Deferred audit element did not return after Dynamic Type restoration: \(key)")
            if let revealDeferred {
                revealDeferred(target)
                continue
            }
            if today {
                positionTodayAuditBelowCard(app, revealing: target)
                continue
            }
            // Clipped SwiftUI nodes can lose their query frame; the native issue retains it.
            let queryFrame = framesBeforeResizing[key]!
            let targetFrame = queryFrame.isEmpty || queryFrame.isNull || queryFrame.isInfinite
                ? deferredFrames[key]! : queryFrame
            print("Audit navigation \(key): pre-resizing query \(queryFrame), target \(targetFrame)")
            let distance = viewport.height * 0.45 * (targetFrame.minY < viewport.minY ? -1 : 1)
            let origin = app.coordinate(withNormalizedOffset: .zero)
            let start = origin.withOffset(CGVector(dx: viewport.midX, dy: viewport.midY + distance / 2))
            let end = origin.withOffset(CGVector(dx: viewport.midX, dy: viewport.midY - distance / 2))
            start.press(forDuration: 0.05, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.1)
        }
        try requireAuditCoverage(Set(deferred.keys), covered: covered)
        // The native scaling audit can still be restoring layout when it returns.
        waitForStableFrames(app)
    }

    private func positionTodayAuditBelowCard(_ app: XCUIApplication, revealing target: XCUIElement) {
        let card = app.buttons["today-card"]
        let reading = app.staticTexts["core-interpretation"]
        XCTAssertTrue(card.exists && reading.exists && target.exists)
        for _ in 0..<10 {
            let viewport = visibleFrame(in: app)
            let cardFrame = card.frame
            let readingFrame = reading.frame
            let targetFrame = target.frame
            // Put the viewport edge in the gap after the illustration, never through its artwork.
            let gap = max(0, readingFrame.minY - cardFrame.maxY)
            let readingTop = viewport.minY + gap / 2
            let distance = max(readingFrame.minY - readingTop, targetFrame.maxY - viewport.maxY)
            if cardFrame.maxY <= viewport.minY && viewport.contains(targetFrame) { break }
            // Cross the scroll view's touch threshold, then remeasure the actual result.
            let drag = min(abs(distance) + 12, viewport.height - 2) * (distance > 0 ? 1 : -1)
            let origin = app.coordinate(withNormalizedOffset: .zero)
            let start = origin.withOffset(CGVector(dx: viewport.midX, dy: viewport.midY + drag / 2))
            let end = origin.withOffset(CGVector(dx: viewport.midX, dy: viewport.midY - drag / 2))
            start.press(forDuration: 0.05, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.1)
        }
        let viewport = visibleFrame(in: app)
        XCTAssertLessThanOrEqual(card.frame.maxY, viewport.minY,
                                 "Later Today audits must place the entire illustration above the viewport")
        assertVisible(target, in: app)
        print("Today audit stop: card \(card.frame), reading \(reading.frame), viewport \(viewport)")
    }

    private func waitForRitualToSettle(_ app: XCUIApplication,
                                      file: StaticString = #filePath, line: UInt = #line) {
        let title = app.staticTexts["draw-title"]
        let card = app.descendants(matching: .any)["revealed-card"]
        let signal: XCUIElement
        if title.exists { signal = title }
        else if card.exists { signal = card }
        else { return } // These screens have no ritual animation.
        let settled = XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == %@", "settled"), object: signal)
        XCTAssertEqual(XCTWaiter.wait(for: [settled], timeout: 10), .completed,
                       "Ritual must finish rendering before an audit or capture", file: file, line: line)
    }

    private func waitForStableFrames(_ app: XCUIApplication) {
        let alert = app.alerts.firstMatch
        // A native alert covers the identified screen and has no identifiers of its own.
        let elements = alert.exists ? [alert] : app.descendants(matching: .any).allElementsBoundByIndex.filter {
            $0.isHittable && !$0.identifier.isEmpty
        }
        var previous: [CGRect]?
        let settled = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            let frames = elements.map(\.frame)
            defer { previous = frames }
            return !frames.isEmpty && frames.allSatisfy { !$0.isEmpty } && frames == previous
        }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [settled], timeout: 15), .completed, "Visible frames must settle")
    }

    private func waitForSettled(_ elements: [XCUIElement], file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertFalse(elements.isEmpty, file: file, line: line)
        var previousFrames: [CGRect]?
        let settled = NSPredicate { _, _ in
            guard elements.allSatisfy({ $0.exists }) else { previousFrames = nil; return false }
            let frames = elements.map(\.frame)
            guard frames.allSatisfy({ !$0.isEmpty && !$0.isInfinite && !$0.isNull }) else {
                previousFrames = nil
                return false
            }
            let unchanged = frames == previousFrames
            previousFrames = frames
            return unchanged
        }
        let expectation = XCTNSPredicateExpectation(predicate: settled, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: 5), .completed,
                       "Expected screen elements must exist with unchanged frames across two reads", file: file, line: line)
    }

    private func capture(_ app: XCUIApplication, _ name: String) {
        waitForRitualToSettle(app)
        waitForStableFrames(app)
        // Accessibility frames settle before the compositor after a colour-scheme change.
        Thread.sleep(forTimeInterval: 0.3)
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func visibleFrame(in app: XCUIApplication, abovePinnedFooter: Bool = false) -> CGRect {
        let marker = app.otherElements["test-safe-viewport"]
        guard marker.exists || marker.waitForExistence(timeout: 5) else {
            XCTFail("Missing safe-area viewport marker: launch a Debug build with --test-mode")
            return .null
        }
        let viewport = marker.frame
        XCTAssertFalse(viewport.isEmpty, "The test safe-area viewport must have completed layout")
        let footer = app.otherElements["screen-footer"]
        var bottom = abovePinnedFooter && footer.exists ? min(viewport.maxY, footer.frame.minY) : viewport.maxY
        let keyboard = app.keyboards.firstMatch
        if keyboard.exists { bottom = min(bottom, keyboard.frame.minY) }
        if let tabs = visibleTabs(in: app) {
            bottom = min(bottom, tabs.frame.minY)
        }
        return CGRect(x: viewport.minX, y: viewport.minY, width: viewport.width, height: bottom - viewport.minY)
    }

    private func visibleTabs(in app: XCUIApplication) -> XCUIElement? {
        // An archive cover can retain the underlying History bar in the tree.
        app.otherElements.matching(identifier: "resting-tabs").allElementsBoundByIndex.first {
            $0.buttons["tab-today"].isHittable
        }
    }

    private func isNotFullyVisible(_ frame: CGRect, in viewport: CGRect) -> Bool {
        !frame.isEmpty && !viewport.isNull && !viewport.contains(frame)
    }

    private enum AuditCoverageError: Error, Equatable, CustomStringConvertible {
        case neverFullyVisible([String])

        var description: String {
            switch self {
            case .neverFullyVisible(let identifiers):
                return "Deferred elements never audited fully visible: \(identifiers)"
            }
        }
    }

    private func requireAuditCoverage(_ deferred: Set<String>, covered: Set<String>) throws {
        let missing = deferred.subtracting(covered).sorted()
        if !missing.isEmpty { throw AuditCoverageError.neverFullyVisible(missing) }
    }

    func testSafeViewportRequiresFullyVisibleAuditCoverage() {
        let app = app()
        let viewport = visibleFrame(in: app)
        let crossing = CGRect(x: viewport.midX, y: viewport.maxY - 5, width: 20, height: 10)
        XCTAssertTrue(isNotFullyVisible(crossing, in: viewport))
        XCTAssertFalse(isNotFullyVisible(crossing.offsetBy(dx: 0, dy: -10), in: viewport))
        XCTAssertTrue(isNotFullyVisible(crossing.offsetBy(dx: 0, dy: 10), in: viewport))
        XCTAssertThrowsError(try requireAuditCoverage(["always-offscreen"], covered: [])) { error in
            XCTAssertEqual(error as? AuditCoverageError, .neverFullyVisible(["always-offscreen"]))
        }
        XCTAssertNoThrow(try requireAuditCoverage(["now-visible"], covered: ["now-visible"]))
        XCTAssertEqual(app.otherElements["test-safe-viewport"].label, "")
        app.terminate()
        app.launchArguments = []
        app.launch()
        XCTAssertFalse(app.otherElements["test-safe-viewport"].exists, "Normal Debug launches must not expose the test marker")
    }

    private func assertVisible(_ element: XCUIElement, in app: XCUIApplication, abovePinnedFooter: Bool = false,
                               file: StaticString = #filePath, line: UInt = #line) {
        let frame = element.frame
        let viewport = visibleFrame(in: app, abovePinnedFooter: abovePinnedFooter)
        XCTAssertFalse(frame.isEmpty, "Empty frame for \(element.identifier)", file: file, line: line)
        XCTAssertTrue(viewport.contains(frame), "\(element.identifier): \(frame) outside visible area \(viewport)", file: file, line: line)
    }

    private func dragContent(_ app: XCUIApplication, up: Bool, abovePinnedFooter: Bool = false) {
        let viewport = visibleFrame(in: app, abovePinnedFooter: abovePinnedFooter)
        let origin = app.coordinate(withNormalizedOffset: .zero)
        let start = origin.withOffset(CGVector(dx: viewport.midX, dy: up ? viewport.maxY - 80 : viewport.minY + 80))
        let end = origin.withOffset(CGVector(dx: viewport.midX, dy: up ? viewport.minY + 80 : viewport.maxY - 80))
        start.press(forDuration: 0.05, thenDragTo: end)
    }

    private func activeScrollView(in app: XCUIApplication) -> XCUIElement {
        let matches = app.scrollViews.matching(identifier: "screen-content")
        XCTAssertTrue(matches.firstMatch.exists || matches.firstMatch.waitForExistence(timeout: 5))
        let scroll = matches.allElementsBoundByIndex.first { $0.isHittable }
        XCTAssertNotNil(scroll, "The foreground screen must have a hittable scroll view")
        return scroll ?? matches.firstMatch
    }

    private func scrollViewport(in app: XCUIApplication, abovePinnedFooter: Bool = false) -> CGRect {
        let scroll = activeScrollView(in: app)
        let footer = app.otherElements["screen-footer"]
        let pinned = footer.exists && !scroll.otherElements["screen-footer"].exists
        return scroll.frame.intersection(visibleFrame(in: app, abovePinnedFooter: abovePinnedFooter || pinned))
    }

    private func auditViewport(for element: XCUIElement, in app: XCUIApplication, contentViewport: CGRect) -> CGRect {
        let footer = app.otherElements["screen-footer"]
        guard footer.exists, !activeScrollView(in: app).otherElements["screen-footer"].exists else {
            return contentViewport
        }
        let descendants = footer.descendants(matching: element.elementType)
        let matches = element.identifier.isEmpty
            ? descendants.matching(NSPredicate(format: "label == %@", element.label))
            : descendants.matching(identifier: element.identifier)
        // Only actual footer descendants may use the pinned region; covered scroll content cannot.
        guard matches.count == 1 else { return contentViewport }
        return footer.frame.intersection(visibleFrame(in: app))
    }

    private func scrollTo(_ element: XCUIElement, in app: XCUIApplication, abovePinnedFooter: Bool = false,
                          file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(element.exists || element.waitForExistence(timeout: 5), file: file, line: line)
        for _ in 0..<10 {
            let frame = element.frame
            guard !frame.isEmpty && !frame.isNull && !frame.isInfinite else {
                XCTFail("Cannot scroll to \(element.identifier) using an empty or invalid frame", file: file, line: line)
                return
            }
            let viewport = scrollViewport(in: app, abovePinnedFooter: abovePinnedFooter)
            let footer = app.otherElements["screen-footer"]
            let isFooterElement = !element.identifier.isEmpty &&
                footer.descendants(matching: .any).matching(identifier: element.identifier).firstMatch.exists
            if footer.exists && isFooterElement && footer.frame.minY >= viewport.maxY - 0.5 &&
                footer.frame.contains(frame) && visibleFrame(in: app).contains(frame) {
                assertVisible(element, in: app, file: file, line: line)
                return
            }
            if !frame.isEmpty && viewport.contains(frame) { break }
            let delta = frame.maxY > viewport.maxY
                ? min(viewport.height * 0.8, frame.maxY - viewport.maxY + 24)
                : -min(viewport.height * 0.8, viewport.minY - frame.minY + 24)
            let origin = app.coordinate(withNormalizedOffset: .zero)
            let start = origin.withOffset(CGVector(dx: viewport.midX, dy: viewport.midY + delta / 2))
            let end = origin.withOffset(CGVector(dx: viewport.midX, dy: viewport.midY - delta / 2))
            start.press(forDuration: 0.05, thenDragTo: end)
        }
        XCTAssertFalse(element.frame.isEmpty, "Empty frame for \(element.identifier)", file: file, line: line)
        XCTAssertTrue(scrollViewport(in: app, abovePinnedFooter: abovePinnedFooter).contains(element.frame),
                      "\(element.identifier) must be fully inside its scroll viewport", file: file, line: line)
    }

    private func showQuestionField(_ app: XCUIApplication) {
        // A native text field can report a null frame while off-screen. Approach
        // it from above using the surrounding SwiftUI text before checking it.
        scrollTo(app.staticTexts["composer-title"], in: app)
        scrollTo(app.staticTexts["Or start from one of these"], in: app)
        let field = app.descendants(matching: .any)["question-field"].firstMatch
        scrollTo(field, in: app)
        waitForSettled([field])
        assertVisible(field, in: app)
    }

    private func showNavigationTop(_ app: XCUIApplication) {
        let back = app.buttons["go-back"]
        scrollTo(back, in: app)
        // Once the first control is visible, a downward drag reaches the real
        // scroll origin, rather than stopping at a later heading or question.
        dragContent(app, up: false)
        waitForSettled([back])
        assertVisible(back, in: app)
    }

    /// A tap during launch or the relayout after an audit can land on a moving card and be dropped.
    @discardableResult
    private func tapWhenSettled(_ element: XCUIElement, file: StaticString = #filePath, line: UInt = #line) -> CGRect {
        var previous: CGRect?
        let settled = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            let frame = element.frame
            defer { previous = frame }
            return element.isHittable && frame == previous
        }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [settled], timeout: 5), .completed,
                       "\(element.identifier) must be hittable and still before a tap", file: file, line: line)
        element.tap()
        return previous ?? .null
    }

    // Keep the original single tap; wait for its observable destination before reading it.
    private func waitForDestination(_ destination: String,
                                    file: StaticString = #filePath, line: UInt = #line,
                                    until arrived: @escaping () -> Bool) {
        let expectation = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in arrived() }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: 5), .completed,
                       "Expected \(destination) after one tap", file: file, line: line)
    }

    private func reveal(_ app: XCUIApplication, position: Int = 3) {
        let card = app.buttons["draw-card-\(position)"]
        XCTAssertTrue(card.waitForExistence(timeout: 5))
        XCTAssertEqual(card.label, "Card \(position) of 5")
        XCTAssertGreaterThanOrEqual(card.frame.width, 44)
        XCTAssertGreaterThanOrEqual(card.frame.height, 44)
        tapWhenSettled(card)
        let turnOver = app.buttons["turn-over"]
        XCTAssertTrue(turnOver.waitForExistence(timeout: 5))
        turnOver.tap()
        XCTAssertTrue(app.buttons["see-meaning"].waitForExistence(timeout: 5))
    }

    private func assertReminderEvidence(_ app: XCUIApplication, contains expected: String,
                                        file: StaticString = #filePath, line: UInt = #line) {
        let title = app.staticTexts["settings-title"].exists
            ? app.staticTexts["settings-title"] : app.staticTexts["today-title"]
        let ready = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            (title.value as? String)?.contains(expected) == true
        }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [ready], timeout: 5), .completed,
                       "Expected \(expected), got \(title.value ?? "nil")", file: file, line: line)
    }

    func testMorningInvitationEvidenceAndPermanentDecline() throws {
        let app = app(extra: ["--test-store-id", UUID().uuidString], memory: false,
                      audit: true, reminderInvitation: true)
        XCTAssertFalse(app.buttons["reminder-accept"].exists)
        reveal(app)
        XCTAssertFalse(app.buttons["reminder-accept"].exists)
        app.buttons["see-meaning"].tap()
        try auditAndCapture(app, "04-today-first-day", today: true, expecting: app.buttons["today-card"])
        positionTodayAuditBelowCard(app, revealing: app.buttons["reminder-decline"])
        assertVisible(app.buttons["reminder-accept"], in: app)
        XCTAssertEqual(app.buttons["reminder-accept"].frame.width, app.buttons["reminder-decline"].frame.width, accuracy: 1)
        XCTAssertGreaterThanOrEqual(app.buttons["reminder-decline"].frame.height, 44)
        try auditAndCapture(app, "04-today-first-day--invitation", today: true,
                            expecting: app.buttons["reminder-decline"])
        scrollTo(app.staticTexts["next-card-arrival"], in: app)
        capture(app, "04-today-first-day--bottom")
        app.terminate()
        app.launchArguments.append("--test-largest-text")
        app.launch()
        capture(app, "04-today-first-day--largest-text")
        scrollTo(app.staticTexts["reminder-invitation-title"], in: app)
        capture(app, "04-today-first-day--largest-text-invitation")
        for choice in ["accept", "decline"] {
            scrollTo(app.buttons["reminder-\(choice)"], in: app)
            capture(app, "04-today-first-day--largest-text-\(choice)")
        }
        app.buttons["reminder-decline"].tap()
        XCTAssertFalse(app.buttons["reminder-accept"].exists)
        assertReminderEvidence(app, contains: "requests=0; pending=none")
        app.terminate()
        app.launchArguments.removeAll { $0 == "--test-largest-text" }
        app.launch()
        XCTAssertTrue(app.staticTexts["today-title"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["reminder-accept"].exists)
        app.buttons["open-settings"].tap()
        scrollTo(app.switches["morning-reminder"], in: app)
        XCTAssertEqual(app.switches["morning-reminder"].value as? String, "0")
        assertReminderEvidence(app, contains: "requests=0; pending=none")
    }

    func testMorningInvitationExpiresAfterFirstDateEvenWithoutAnswer() {
        let app = app(extra: ["--test-store-id", UUID().uuidString], memory: false, reminderInvitation: true)
        reveal(app)
        app.buttons["see-meaning"].tap()
        XCTAssertTrue(app.buttons["reminder-accept"].exists)
        openHistory(app)
        let archived = app.buttons["history-daily-2026-10-11"]
        scrollTo(archived, in: app)
        archived.tap()
        XCTAssertTrue(app.buttons["back-to-history"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["reminder-accept"].exists, "Archived cards must not show the live invitation")
        app.buttons["back-to-history"].tap()
        app.buttons["tab-today"].tap()
        XCTAssertTrue(app.buttons["reminder-accept"].waitForExistence(timeout: 5))
        app.terminate()
        let dateIndex = app.launchArguments.firstIndex(of: "--test-date")! + 1
        app.launchArguments[dateIndex] = "2026-10-12T00:00:00Z"
        app.launch()
        reveal(app)
        app.buttons["see-meaning"].tap()
        XCTAssertFalse(app.buttons["reminder-accept"].exists)
        app.terminate()
        app.launchArguments[dateIndex] = "2026-10-11T00:00:00Z"
        app.launch()
        XCTAssertTrue(app.staticTexts["today-title"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["reminder-accept"].exists, "Going back a date cannot revive an expired invitation")
    }

    func testMorningReminderSchedulesPersistsCancelsAndReflectsRevocation() throws {
        let app = app(extra: ["--test-store-id", UUID().uuidString], memory: false,
                      audit: true, reminderInvitation: true)
        reveal(app)
        app.buttons["see-meaning"].tap()
        scrollTo(app.buttons["reminder-accept"], in: app)
        app.buttons["reminder-accept"].tap()
        XCTAssertFalse(app.buttons["reminder-accept"].exists)
        assertReminderEvidence(app, contains: "requests=1; pending=morning-reminder; hour=8; minute=0; repeats=true; deviceTime=true")
        assertReminderEvidence(app, contains: "title=Your card is ready; body=Take a quiet moment for today's reading.")
        app.terminate()
        app.launchArguments += ["--test-notification-permission", "allowed"]
        app.launch()
        app.buttons["open-settings"].tap()
        let toggle = app.switches["morning-reminder"]
        scrollTo(toggle, in: app)
        XCTAssertEqual(toggle.value as? String, "1")
        assertReminderEvidence(app, contains: "requests=0; pending=morning-reminder")
        try auditAndCapture(app, "11-settings--reminder-on", expecting: toggle)
        scrollTo(toggle, in: app)
        toggle.tap()
        waitForDestination("morning reminder switched off") {
            toggle.value as? String == "0"
        }
        XCTAssertEqual(toggle.value as? String, "0")
        assertReminderEvidence(app, contains: "requests=0; pending=none")
        app.terminate()
        app.launch()
        app.buttons["open-settings"].tap()
        scrollTo(toggle, in: app)
        XCTAssertEqual(toggle.value as? String, "0")
        assertReminderEvidence(app, contains: "pending=none")
        toggle.tap()
        XCTAssertEqual(toggle.value as? String, "1")
        app.terminate()
        let permissionIndex = app.launchArguments.firstIndex(of: "--test-notification-permission")! + 1
        app.launchArguments[permissionIndex] = "denied"
        app.launch()
        app.buttons["open-settings"].tap()
        scrollTo(toggle, in: app)
        XCTAssertEqual(toggle.value as? String, "0")
        assertReminderEvidence(app, contains: "requests=0; pending=none")
    }

    func testMorningReminderDenialAndSettingsPermissionRequest() throws {
        let app = app(extra: ["--test-notification-permission", "deny"], audit: true, reminderInvitation: true)
        reveal(app)
        app.buttons["see-meaning"].tap()
        scrollTo(app.buttons["reminder-accept"], in: app)
        app.buttons["reminder-accept"].tap()
        XCTAssertFalse(app.buttons["reminder-accept"].exists)
        XCTAssertTrue(app.staticTexts["today-reminder-denied"].exists)
        assertReminderEvidence(app, contains: "requests=1; pending=none")
        positionTodayAuditBelowCard(app, revealing: app.staticTexts["today-reminder-denied"])
        try auditAndCapture(app, "04-today-first-day--permission-denied", today: true,
                            expecting: app.staticTexts["today-reminder-denied"])
        scrollTo(app.buttons["open-settings"], in: app)
        app.buttons["open-settings"].tap()
        waitForDestination("Settings") {
            app.staticTexts["settings-title"].exists
        }
        scrollTo(app.switches["morning-reminder"], in: app)
        app.switches["morning-reminder"].tap()
        XCTAssertEqual(app.switches["morning-reminder"].value as? String, "0")
        assertReminderEvidence(app, contains: "requests=1; pending=none")
        scrollTo(app.staticTexts["reminder-hint"], in: app)
        XCTAssertTrue(app.staticTexts["reminder-hint"].label.contains("Allow Notifications"))
        try auditAndCapture(app, "11-settings--reminder-denied", expecting: app.staticTexts["reminder-hint"])
        app.terminate()
        let largest = self.app(extra: ["--test-largest-text", "--test-notification-permission", "denied"], audit: true)
        scrollTo(largest.buttons["draw-card-3"], in: largest)
        tapWhenSettled(largest.buttons["draw-card-3"])
        scrollTo(largest.buttons["turn-over"], in: largest)
        largest.buttons["turn-over"].tap()
        scrollTo(largest.buttons["see-meaning"], in: largest)
        largest.buttons["see-meaning"].tap()
        scrollTo(largest.buttons["open-settings"], in: largest)
        largest.buttons["open-settings"].tap()
        scrollTo(largest.switches["morning-reminder"], in: largest)
        XCTAssertGreaterThanOrEqual(largest.switches["morning-reminder"].frame.height, 44)
        capture(largest, "11-settings--reminder-largest-text")
        scrollTo(largest.staticTexts["reminder-hint"], in: largest)
        capture(largest, "11-settings--reminder-denied-largest-text")
        largest.terminate()
        let settings = self.app()
        reveal(settings)
        settings.buttons["see-meaning"].tap()
        settings.buttons["open-settings"].tap()
        scrollTo(settings.switches["morning-reminder"], in: settings)
        settings.switches["morning-reminder"].tap()
        XCTAssertEqual(settings.switches["morning-reminder"].value as? String, "1")
        assertReminderEvidence(settings, contains: "requests=1; pending=morning-reminder")
    }

    func testMorningReminderFailuresRemainRecoverable() {
        let app = app(extra: ["--test-reminder-save-failure"], reminderInvitation: true)
        reveal(app)
        app.buttons["see-meaning"].tap()
        scrollTo(app.buttons["reminder-decline"], in: app)
        app.buttons["reminder-decline"].tap()
        XCTAssertTrue(app.alerts["Your reminder could not be updated"].waitForExistence(timeout: 5))
        capture(app, "04-today-first-day--save-failure")
        app.alerts.buttons["OK"].tap()
        XCTAssertTrue(app.buttons["reminder-decline"].exists)
        app.buttons["reminder-decline"].tap()
        XCTAssertFalse(app.buttons["reminder-decline"].exists)
        assertReminderEvidence(app, contains: "requests=0; pending=none")
        app.terminate()
        let failed = self.app(extra: ["--test-notification-permission", "schedule-failure"])
        reveal(failed)
        failed.buttons["see-meaning"].tap()
        failed.buttons["open-settings"].tap()
        scrollTo(failed.switches["morning-reminder"], in: failed)
        failed.switches["morning-reminder"].tap()
        XCTAssertTrue(failed.alerts["Your reminder could not be updated"].waitForExistence(timeout: 5))
        XCTAssertTrue(failed.alerts.staticTexts["Try turning this reminder on again."].exists)
        capture(failed, "11-settings--reminder-schedule-failure")
        failed.alerts.buttons["OK"].tap()
        XCTAssertEqual(failed.switches["morning-reminder"].value as? String, "0")
        assertReminderEvidence(failed, contains: "requests=1; pending=none")
        failed.switches["morning-reminder"].tap()
        XCTAssertEqual(failed.switches["morning-reminder"].value as? String, "1")
        assertReminderEvidence(failed, contains: "requests=1; pending=morning-reminder")
    }

    @MainActor
    func testMorningReminderSchedulingFailureSystemTextEvidence() {
        // The host selects the actual system size for the focused capture run.
        // No app-only override: the native alert and SwiftUI inherit the same setting.
        let app = app(extra: ["--test-notification-permission", "schedule-failure"], audit: true)
        scrollTo(app.buttons["draw-card-3"], in: app)
        tapWhenSettled(app.buttons["draw-card-3"])
        scrollTo(app.buttons["turn-over"], in: app)
        app.buttons["turn-over"].tap()
        scrollTo(app.buttons["see-meaning"], in: app)
        app.buttons["see-meaning"].tap()
        scrollTo(app.buttons["open-settings"], in: app)
        app.buttons["open-settings"].tap()
        scrollTo(app.switches["morning-reminder"], in: app)
        app.switches["morning-reminder"].tap()
        let alert = app.alerts["Your reminder could not be updated"]
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        let heading = alert.staticTexts["Your reminder could not be updated"]
        let message = alert.staticTexts["Try turning this reminder on again."]
        let action = alert.buttons["OK"]
        waitForSettled([heading, message, action])
        for element in [heading, message, action] {
            XCTAssertTrue(app.windows.firstMatch.frame.contains(element.frame))
        }
        XCTAssertTrue(action.isHittable)
        let category = UIApplication.shared.preferredContentSizeCategory
        let categoryEvidence = XCTAttachment(string: category.rawValue)
        categoryEvidence.name = "reminder-alert-system-text-category"
        categoryEvidence.lifetime = .keepAlways
        add(categoryEvidence)
        let suffix = category == .accessibilityExtraExtraExtraLarge ? "largest-text" : "system-text"
        capture(app, "11-settings--reminder-schedule-failure-\(suffix)")
        action.tap()
        XCTAssertEqual(app.switches["morning-reminder"].value as? String, "0")
        app.switches["morning-reminder"].tap()
        XCTAssertEqual(app.switches["morning-reminder"].value as? String, "1")
        app.terminate()
    }

    private func closeDataExport(_ app: XCUIApplication) {
        app.buttons["Close"].tap()
        XCTAssertTrue(app.buttons["Close"].waitForNonExistence(timeout: 5))
        scrollTo(app.buttons["settings-export"], in: app)
        let ready = XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true AND hittable == true"),
                                             object: app.buttons["settings-export"])
        XCTAssertEqual(XCTWaiter.wait(for: [ready], timeout: 5), .completed)
        waitForSettled([app.buttons["settings-export"]])
    }

    func testDataOwnershipExportAndDeleteReturnsToFreshWelcome() throws {
        let app = app(extra: ["--test-store-id", UUID().uuidString, "--test-history-days", "3"], memory: false, audit: true)
        XCTAssertTrue(app.staticTexts["today-title"].waitForExistence(timeout: 5))
        app.buttons["open-settings"].tap()
        app.switches["visible-career"].tap()
        scrollTo(app.switches["morning-reminder"], in: app)
        app.switches["morning-reminder"].tap()
        assertReminderEvidence(app, contains: "pending=morning-reminder")
        scrollTo(app.buttons["settings-delete-all"], in: app)
        try auditAndCapture(app, "11-settings--data-actions", expecting: app.buttons["settings-export"], app.buttons["settings-delete-all"])
        scrollTo(app.buttons["settings-export"], in: app)
        app.buttons["settings-export"].tap()
        XCTAssertTrue(app.cells["Copy"].waitForExistence(timeout: 5))
        captureShareSheet(app, named: "11-settings--export-sheet")
        closeDataExport(app)
        XCTAssertTrue(app.buttons["settings-export"].waitForExistence(timeout: 5))
        scrollTo(app.buttons["settings-export"], in: app)
        app.buttons["settings-export"].tap()
        XCTAssertTrue(app.cells["Copy"].waitForExistence(timeout: 5))
        app.cells["Copy"].tap()
        let copied = expectation(description: "Read the exported file through the native Copy activity")
        let result = ClipboardTextResult()
        DispatchQueue.global(qos: .userInitiated).async {
            result.store(UIPasteboard.general.string)
            copied.fulfill()
        }
        let allow = XCUIApplication(bundleIdentifier: "com.apple.springboard").buttons["Allow Paste"]
        if allow.waitForExistence(timeout: 3) { allow.tap() }
        wait(for: [copied], timeout: 10)
        let text = try XCTUnwrap(result.value())
        let attachment = XCTAttachment(string: text)
        attachment.name = "exported-readings.txt"
        attachment.lifetime = .keepAlways
        add(attachment)
        XCTAssertEqual(text.components(separatedBy: "Daily card ·").count - 1, 3)
        XCTAssertEqual(text.components(separatedBy: "Question reading ·").count - 1, 3)
        for area in ["Career", "Relationship", "Social"] { XCTAssertTrue(text.contains("Area: \(area)")) }
        XCTAssertTrue(text.contains("Daily card · 2026-10-09"))
        XCTAssertTrue(text.contains("Daily card · 2026-10-11"))
        XCTAssertTrue(text.contains("Notes:"))
        scrollTo(app.buttons["settings-delete-all"], in: app)
        app.buttons["settings-delete-all"].tap()
        let confirmation = app.alerts["Delete all your data?"]
        waitForSettled([confirmation.buttons["Cancel"], confirmation.buttons["Delete all data"]])
        capture(app, "11-settings--delete-confirmation")
        confirmation.buttons["Cancel"].tap()
        XCTAssertTrue(confirmation.waitForNonExistence(timeout: 5))
        showNavigationTop(app)
        app.buttons["go-back"].tap()
        XCTAssertTrue(app.staticTexts["today-title"].waitForExistence(timeout: 5))
        app.buttons["tab-history"].tap()
        XCTAssertTrue(app.staticTexts["history-month-count"].label.contains("3"))
        app.buttons["open-settings"].tap()
        scrollTo(app.buttons["settings-delete-all"], in: app)
        app.buttons["settings-delete-all"].tap()
        confirmation.buttons["Delete all data"].tap()
        XCTAssertTrue(app.buttons["welcome-draw"].waitForExistence(timeout: 5))
        try auditAndCapture(app, "01-welcome--after-delete", expecting: app.buttons["welcome-draw"])
        app.terminate()
        app.launchArguments.removeAll { $0 == "--test-welcome-completed" || $0 == "--test-reminder-answered" }
        let historyIndex = try XCTUnwrap(app.launchArguments.firstIndex(of: "--test-history-days"))
        app.launchArguments.removeSubrange(historyIndex...historyIndex + 1)
        app.launch()
        XCTAssertTrue(app.buttons["welcome-draw"].waitForExistence(timeout: 5))
        app.buttons["welcome-draw"].tap()
        XCTAssertTrue(app.buttons["draw-card-3"].waitForExistence(timeout: 5))
        app.buttons["draw-history"].tap()
        XCTAssertTrue(app.staticTexts["history-message"].waitForExistence(timeout: 5))
        app.buttons["open-settings"].tap()
        for area in ["career", "relationship", "social"] { XCTAssertEqual(app.switches["visible-\(area)"].value as? String, "1") }
        scrollTo(app.buttons["settings-relationship"], in: app)
        XCTAssertTrue(app.buttons["settings-relationship"].label.contains("Not set"))
        scrollTo(app.switches["morning-reminder"], in: app)
        XCTAssertEqual(app.switches["morning-reminder"].value as? String, "0")
        assertReminderEvidence(app, contains: "pending=none")
        app.terminate()
    }

    private func assertNativeDataAlert(_ app: XCUIApplication, title: String, message: String, actions: [String]) {
        let alert = app.alerts[title]
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        let heading = alert.staticTexts[title]
        let body = alert.staticTexts.matching(NSPredicate(format: "label == %@", message)).firstMatch
        let buttons = actions.map { alert.buttons[$0] }
        waitForSettled([heading, body] + buttons)
        XCTAssertEqual(heading.label, title)
        XCTAssertEqual(body.label, message)
        for element in [heading] + buttons {
            XCTAssertTrue(app.windows.firstMatch.frame.contains(element.frame), "Native alert heading and actions must fit")
        }
        // Long UIKit messages scroll at accessibility sizes; verify their end below after scrolling.
        XCTAssertTrue(app.windows.firstMatch.frame.intersects(body.frame))
        for button in buttons { XCTAssertTrue(button.isHittable) }
    }

    private func captureNativeDataAlert(_ app: XCUIApplication, title: String, message: String, name: String,
                                        captureMiddle: Bool = false) {
        keepSystemScreenshot(name)
        guard UIApplication.shared.preferredContentSizeCategory == .accessibilityExtraExtraExtraLarge else { return }
        let alert = app.alerts[title]
        let content = alert.scrollViews.firstMatch
        XCTAssertTrue(content.exists, "Long native alert text must remain scrollable at the largest system size")
        guard content.exists else { return }
        let body = alert.staticTexts.matching(NSPredicate(format: "label == %@", message)).firstMatch
        if captureMiddle {
            // Hold before release so the missing middle clause is not skipped by scroll momentum.
            let start = content.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.9))
            let end = content.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1))
            start.press(forDuration: 0.1, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.2)
            waitForSettled([body] + alert.buttons.allElementsBoundByIndex)
            keepSystemScreenshot("\(name)-middle")
        }
        for stop in 1...6 {
            if body.frame.maxY <= content.frame.maxY { break }
            content.swipeUp()
            waitForSettled([body] + alert.buttons.allElementsBoundByIndex)
            keepSystemScreenshot("\(name)-scroll-\(stop)")
        }
        XCTAssertEqual(body.label, message)
        XCTAssertLessThanOrEqual(body.frame.maxY, content.frame.maxY, "The final line must be reachable within the native text viewport")
        XCTAssertGreaterThan(body.frame.maxY, content.frame.minY)
        XCTAssertGreaterThanOrEqual(body.frame.minX, content.frame.minX)
        XCTAssertLessThanOrEqual(body.frame.maxX, content.frame.maxX)
        for button in alert.buttons.allElementsBoundByIndex {
            XCTAssertTrue(button.isHittable)
            XCTAssertTrue(app.windows.firstMatch.frame.contains(button.frame))
        }
    }

    func testDataOwnershipSystemTextEvidence() throws {
        // Inherits real system scaling for UIKit alerts and the remote activity sheet.
        let category = UIApplication.shared.preferredContentSizeCategory
        let suffix = category == .accessibilityExtraExtraExtraLarge ? "largest-system-text" : "system-text"
        let categoryEvidence = XCTAttachment(string: category.rawValue)
        categoryEvidence.name = "data-alert-system-text-category"
        categoryEvidence.lifetime = .keepAlways
        add(categoryEvidence)
        let app = app(extra: ["--test-history-days", "1", "--test-export-failure", "--test-delete-all-failure"], audit: true)
        scrollTo(app.buttons["open-settings"], in: app)
        app.buttons["open-settings"].tap()
        scrollTo(app.buttons["settings-export"], in: app)
        app.buttons["settings-export"].tap()
        let exportError = app.alerts["Your export could not be prepared"]
        assertNativeDataAlert(app, title: "Your export could not be prepared",
                              message: "Your saved readings are unchanged. Check the free space on your phone, then try again.",
                              actions: ["Cancel", "Try again"])
        captureNativeDataAlert(app, title: "Your export could not be prepared",
                               message: "Your saved readings are unchanged. Check the free space on your phone, then try again.",
                               name: "11-settings--export-error-\(suffix)")
        exportError.buttons["Try again"].tap()
        let close = app.buttons["Close"]
        XCTAssertTrue(close.waitForExistence(timeout: 5))
        waitForSettled([close])
        keepSystemScreenshot("11-settings--export-sheet-\(suffix)")
        if category == .accessibilityExtraExtraExtraLarge {
            let hierarchy = XCTAttachment(string: app.debugDescription)
            hierarchy.name = "11-settings--export-destinations-largest-system-text-hierarchy"
            hierarchy.lifetime = .keepAlways
            add(hierarchy)
            let more = app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", "More")).firstMatch
            XCTAssertTrue(more.waitForExistence(timeout: 5))
            let window = app.windows.firstMatch
            for _ in 0..<3 {
                let frame = window.frame
                let origin = window.coordinate(withNormalizedOffset: .zero)
                let start = origin.withOffset(CGVector(dx: frame.width * 0.85, dy: more.frame.midY - frame.minY))
                let end = origin.withOffset(CGVector(dx: frame.width * 0.2, dy: more.frame.midY - frame.minY))
                start.press(forDuration: 0.1, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.2)
                waitForSettled([more, close])
                if window.frame.contains(more.frame) && more.isHittable { break }
            }
            keepSystemScreenshot("11-settings--export-sheet-\(suffix)-destinations")
            XCTAssertTrue(window.frame.contains(more.frame))
            XCTAssertTrue(more.isHittable)
        }
        let copy = app.cells["Copy"]
        let files = app.cells["Save to Files"]
        var copyReachable = copy.isHittable
        for stop in 0..<4 {
            if files.exists && files.isHittable && app.windows.firstMatch.frame.contains(files.frame) { break }
            app.swipeUp()
            waitForSettled([close])
            copyReachable = copyReachable || copy.isHittable
            keepSystemScreenshot("11-settings--export-sheet-\(suffix)-scroll-\(stop)")
        }
        XCTAssertTrue(copyReachable)
        XCTAssertTrue(files.exists && files.isHittable)
        XCTAssertTrue(close.isHittable)
        closeDataExport(app)
        scrollTo(app.buttons["settings-delete-all"], in: app)
        app.buttons["settings-delete-all"].tap()
        let confirmation = app.alerts["Delete all your data?"]
        assertNativeDataAlert(app, title: "Delete all your data?",
                              message: "This removes your readings, notes, drafts, preferences and daily-card identity, and cancels your reminder. It cannot be undone. Copies already saved elsewhere remain.",
                              actions: ["Cancel", "Delete all data"])
        captureNativeDataAlert(app, title: "Delete all your data?",
                               message: "This removes your readings, notes, drafts, preferences and daily-card identity, and cancels your reminder. It cannot be undone. Copies already saved elsewhere remain.",
                               name: "11-settings--delete-confirmation-\(suffix)", captureMiddle: true)
        confirmation.buttons["Delete all data"].tap()
        let deleteError = app.alerts["Your data could not be deleted"]
        assertNativeDataAlert(app, title: "Your data could not be deleted",
                              message: "Your saved data is unchanged. Check the free space on your phone, then try Delete all my data again.",
                              actions: ["OK"])
        captureNativeDataAlert(app, title: "Your data could not be deleted",
                               message: "Your saved data is unchanged. Check the free space on your phone, then try Delete all my data again.",
                               name: "11-settings--delete-error-\(suffix)")
        deleteError.buttons["OK"].tap()
        scrollTo(app.buttons["settings-delete-all"], in: app)
        app.buttons["settings-delete-all"].tap()
        waitForSettled([confirmation.buttons["Delete all data"]])
        confirmation.buttons["Delete all data"].tap()
        scrollTo(app.buttons["welcome-draw"], in: app)
        assertVisible(app.buttons["welcome-draw"], in: app)
        keepSystemScreenshot("01-welcome--after-delete-\(suffix)")
        app.terminate()
    }

    func testDataOwnershipFailuresAndLargestText() throws {
        for largest in [false, true] {
            let suffix = largest ? "-largest-text" : ""
            let app = app(extra: ["--test-history-days", "1", "--test-export-failure", "--test-delete-all-failure"]
                          + (largest ? ["--test-largest-text"] : []), audit: true)
            scrollTo(app.buttons["open-settings"], in: app)
            app.buttons["open-settings"].tap()
            scrollTo(app.buttons["settings-export"], in: app)
            app.buttons["settings-export"].tap()
            let exportError = app.alerts["Your export could not be prepared"]
            waitForSettled([exportError.buttons["Try again"], exportError.buttons["Cancel"]])
            capture(app, "11-settings--export-error\(suffix)")
            exportError.buttons["Try again"].tap()
            XCTAssertTrue(app.cells["Copy"].waitForExistence(timeout: 5))
            captureShareSheet(app, named: "11-settings--export-retry\(suffix)")
            closeDataExport(app)
            scrollTo(app.buttons["settings-delete-all"], in: app)
            assertVisible(app.buttons["settings-delete-all"], in: app)
            if largest { capture(app, "11-settings--data-actions-largest-text") }
            app.buttons["settings-delete-all"].tap()
            let confirmation = app.alerts["Delete all your data?"]
            waitForSettled([confirmation.buttons["Cancel"], confirmation.buttons["Delete all data"]])
            if largest { capture(app, "11-settings--delete-confirmation-largest-text") }
            confirmation.buttons["Delete all data"].tap()
            let error = app.alerts["Your data could not be deleted"]
            waitForSettled([error.buttons["OK"]])
            capture(app, "11-settings--delete-error\(suffix)")
            error.buttons["OK"].tap()
            XCTAssertFalse(app.buttons["welcome-draw"].exists)
            scrollTo(app.buttons["settings-delete-all"], in: app)
            app.buttons["settings-delete-all"].tap()
            confirmation.buttons["Delete all data"].tap()
            scrollTo(app.buttons["welcome-draw"], in: app)
            assertVisible(app.buttons["welcome-draw"], in: app)
            if largest { capture(app, "01-welcome--after-delete-largest-text") }
            app.buttons["welcome-draw"].tap()
            scrollTo(app.buttons["draw-card-3"], in: app)
            tapWhenSettled(app.buttons["draw-card-3"])
            scrollTo(app.buttons["turn-over"], in: app)
            app.buttons["turn-over"].tap()
            XCTAssertTrue(app.staticTexts["card-name"].waitForExistence(timeout: 5))
            app.terminate()
        }
    }

    func testSettingsVisibilityPersistsWithoutChangingDailyCard() throws {
        let app = app(extra: ["--test-store-id", UUID().uuidString], memory: false, audit: true)
        reveal(app)
        app.buttons["see-meaning"].tap()
        app.buttons["tab-ask"].tap()
        app.buttons["suggestion-0"].tap()
        app.buttons["submit-question"].tap()
        chooseSpread(app)
        app.buttons["read-spread"].tap()
        let savedQuestion = app.staticTexts["reading-question"].label
        let savedLens = app.staticTexts["reading-lens"].label
        app.buttons["reading-done"].tap()
        let card = app.buttons["today-card"].label
        let scores = ["career", "relationship", "social"].map {
            app.descendants(matching: .any)["score-\($0)"].firstMatch.label
        }
        app.buttons["open-settings"].tap()
        XCTAssertTrue(app.staticTexts["settings-title"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["tab-today"].isHittable)
        XCTAssertEqual(app.staticTexts["settings-title"].label, "Settings")
        for area in ["career", "relationship", "social"] {
            XCTAssertEqual(app.switches["visible-\(area)"].label, area.capitalized)
        }
        XCTAssertEqual(app.staticTexts["area-visibility-hint"].label, "Hidden areas keep their past readings.")
        for label in ["Areas on your Today screen", "About you", "Good to know"] {
            XCTAssertTrue(app.staticTexts[label].exists)
        }
        let hierarchy = XCTAttachment(string: app.debugDescription)
        hierarchy.name = "settings-accessibility-hierarchy"
        hierarchy.lifetime = .keepAlways
        add(hierarchy)
        try auditAndCapture(app, "11-settings", expecting: app.switches["visible-career"])
        scrollTo(app.buttons["settings-privacy"], in: app)
        try auditAndCapture(app, "11-settings--bottom", expecting: app.buttons["settings-privacy"])
        XCTAssertFalse(app.staticTexts["Birth details"].exists)
        XCTAssertFalse(app.staticTexts["Pronouns"].exists)
        scrollTo(app.switches["visible-relationship"], in: app)
        app.switches["visible-relationship"].tap()
        waitForDestination("Relationship area switched off") {
            app.switches["visible-relationship"].value as? String == "0"
        }
        app.switches["visible-social"].tap()
        XCTAssertFalse(app.switches["visible-career"].isEnabled)
        XCTAssertEqual(app.switches["visible-career"].value as? String, "1")
        XCTAssertTrue(app.staticTexts["area-visibility-hint"].label.contains("Keep at least one area on"))
        try auditAndCapture(app, "11-settings--last-area", expecting: app.staticTexts["area-visibility-hint"])
        showNavigationTop(app)
        app.buttons["go-back"].tap()
        waitForDestination("Today") {
            app.staticTexts["today-title"].exists
        }
        XCTAssertEqual(app.buttons["today-card"].label, card)
        XCTAssertFalse(app.descendants(matching: .any)["score-relationship"].firstMatch.exists)
        XCTAssertFalse(app.staticTexts["line-relationship"].exists)
        XCTAssertFalse(app.descendants(matching: .any)["score-social"].firstMatch.exists)
        scrollTo(app.staticTexts["line-career"], in: app)
        capture(app, "04-today--hidden-areas")
        app.buttons["tab-ask"].tap()
        XCTAssertTrue(app.buttons["area-career"].isSelected)
        XCTAssertFalse(app.buttons["area-relationship"].exists)
        XCTAssertFalse(app.buttons["area-social"].exists)
        try auditAndCapture(app, "05-ask--hidden-areas", expecting: app.buttons["area-career"])
        app.buttons["ask-question-entry"].tap()
        waitForDestination("question composer") {
            app.staticTexts["composer-title"].exists
        }
        XCTAssertFalse(app.buttons["area-relationship"].exists)
        XCTAssertFalse(app.buttons["area-social"].exists)
        try auditAndCapture(app, "06-composer--hidden-areas", expecting: app.buttons["area-career"])
        let finalSuggestion = app.buttons["suggestion-2"]
        scrollTo(finalSuggestion, in: app, abovePinnedFooter: true)
        waitForSettled([finalSuggestion])
        assertVisible(finalSuggestion, in: app, abovePinnedFooter: true)
        XCTAssertGreaterThanOrEqual(scrollViewport(in: app).maxY - finalSuggestion.frame.maxY, 8,
                                    "The complete final chip needs a clear gap above the pinned footer")
        capture(app, "06-composer--hidden-areas-bottom")
        showNavigationTop(app)
        app.buttons["go-back"].tap()
        app.terminate()
        app.launch()
        XCTAssertEqual(app.buttons["today-card"].label, card)
        XCTAssertFalse(app.staticTexts["line-relationship"].exists)
        app.buttons["open-settings"].tap()
        XCTAssertEqual(app.switches["visible-relationship"].value as? String, "0")
        app.switches["visible-relationship"].tap()
        app.switches["visible-social"].tap()
        XCTAssertTrue(app.switches["visible-career"].isEnabled)
        app.buttons["go-back"].tap()
        XCTAssertEqual(app.buttons["today-card"].label, card)
        XCTAssertEqual(["career", "relationship", "social"].map {
            app.descendants(matching: .any)["score-\($0)"].firstMatch.label
        }, scores)
        app.buttons["tab-ask"].tap()
        app.buttons["area-relationship"].tap()
        scrollTo(app.buttons["latest-area-reading"], in: app)
        app.buttons["latest-area-reading"].tap()
        XCTAssertEqual(app.staticTexts["reading-question"].label, savedQuestion)
        XCTAssertEqual(app.staticTexts["reading-lens"].label, savedLens)
    }

    func testSettingsStatusInformationAndLargestTextEvidence() throws {
        let app = app(extra: ["--test-store-id", UUID().uuidString], memory: false, audit: true)
        reveal(app)
        app.buttons["see-meaning"].tap()
        app.buttons["open-settings"].tap()
        scrollTo(app.buttons["settings-relationship"], in: app)
        app.buttons["settings-relationship"].tap()
        for status in ["single", "inRelationship", "complicated", "preferNotToSay"] {
            let option = app.buttons["settings-status-\(status)"]
            scrollTo(option, in: app)
            option.tap()
            XCTAssertTrue(option.isSelected)
        }
        showNavigationTop(app)
        try auditAndCapture(app, "11-settings--relationship", expecting: app.staticTexts["settings-current-status"])
        scrollTo(app.buttons["settings-clear-status"], in: app)
        app.buttons["settings-clear-status"].tap()
        waitForDestination("relationship status cleared") {
            app.staticTexts["settings-current-status"].label == "Current status: Not set"
        }
        XCTAssertTrue(app.buttons["settings-clear-status"].isSelected)
        XCTAssertEqual(app.staticTexts["settings-current-status"].label, "Current status: Not set")
        showNavigationTop(app)
        app.buttons["go-back"].tap()
        for (entry, copy, name) in [("settings-about", "settings-disclaimer", "about"),
                                    ("settings-privacy", "settings-privacy-copy", "privacy")] {
            scrollTo(app.buttons[entry], in: app)
            app.buttons[entry].tap()
            XCTAssertTrue(app.staticTexts[copy].exists)
            if name == "privacy" {
                XCTAssertEqual(app.staticTexts[copy].label,
                               "Everything stays on this phone and in your phone's own backups.")
                XCTAssertEqual(app.staticTexts["settings-privacy-detail"].label,
                               "Nothing is sent anywhere else.")
            }
            try auditAndCapture(app, "11-settings--\(name)", expecting: app.staticTexts[copy])
            app.buttons["go-back"].tap()
            waitForDestination("Settings") {
                app.staticTexts["settings-title"].exists
            }
        }
        app.terminate()
        app.launchArguments.append("--test-largest-text")
        app.launch()
        app.buttons["open-settings"].tap()
        capture(app, "11-settings--largest-text")
        for area in ["career", "relationship", "social"] {
            let toggle = app.switches["visible-\(area)"]
            scrollTo(toggle, in: app)
            XCTAssertEqual(toggle.label, area.capitalized)
            XCTAssertGreaterThanOrEqual(toggle.frame.height, 44)
            // Exercise the added hit area above the native switch's 28-point artwork.
            toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.05)).tap()
            XCTAssertEqual(toggle.value as? String, "0")
            toggle.tap()
            XCTAssertEqual(toggle.value as? String, "1")
            capture(app, "11-settings--largest-text-\(area)")
        }
        for (element, name) in [(app.staticTexts["area-visibility-hint"], "area-helper"),
                                 (app.staticTexts["About you"], "about-you-heading"),
                                 (app.buttons["settings-relationship"], "about-you")] {
            scrollTo(element, in: app)
            waitForSettled([element])
            assertVisible(element, in: app)
            capture(app, "11-settings--largest-text-\(name)")
        }
        scrollTo(app.buttons["settings-privacy"], in: app)
        capture(app, "11-settings--largest-text-bottom")
        scrollTo(app.buttons["settings-relationship"], in: app)
        XCTAssertTrue(app.buttons["settings-relationship"].label.contains("Not set"))
        app.buttons["settings-relationship"].tap()
        capture(app, "11-settings--relationship-largest-text")
        let currentStatus = app.staticTexts["settings-current-status"]
        let firstStatus = app.buttons["settings-status-single"]
        scrollTo(currentStatus, in: app)
        scrollTo(firstStatus, in: app)
        waitForSettled([currentStatus, firstStatus])
        XCTAssertEqual(currentStatus.label, "Current status: Not set")
        assertVisible(currentStatus, in: app)
        assertVisible(firstStatus, in: app)
        capture(app, "11-settings--relationship-largest-text-current-status")
        scrollTo(app.buttons["settings-clear-status"], in: app)
        capture(app, "11-settings--relationship-largest-text-bottom")
        showNavigationTop(app)
        app.buttons["go-back"].tap()
        for (entry, copy, name) in [("settings-about", "settings-disclaimer", "about"),
                                    ("settings-privacy", "settings-privacy-copy", "privacy")] {
            scrollTo(app.buttons[entry], in: app)
            app.buttons[entry].tap()
            capture(app, "11-settings--\(name)-largest-text")
            scrollTo(app.staticTexts[name == "privacy" ? "settings-privacy-detail" : copy], in: app)
            capture(app, "11-settings--\(name)-largest-text-bottom")
            showNavigationTop(app)
            app.buttons["go-back"].tap()
        }
        showNavigationTop(app)
        app.buttons["go-back"].tap()
        app.buttons["tab-ask"].tap()
        XCTAssertFalse(app.staticTexts["relationship-prompt"].exists)
    }

    func testSettingsSaveFailureRetainsSettingAndCanRetry() throws {
        let app = app(extra: ["--test-settings-save-failure"], audit: true)
        reveal(app)
        app.buttons["see-meaning"].tap()
        app.buttons["open-settings"].tap()
        app.switches["visible-social"].tap()
        XCTAssertTrue(app.alerts["Your setting could not be saved"].waitForExistence(timeout: 5))
        capture(app, "11-settings--save-error")
        app.alerts.buttons["OK"].tap()
        XCTAssertEqual(app.switches["visible-social"].value as? String, "1")
        app.switches["visible-social"].tap()
        XCTAssertEqual(app.switches["visible-social"].value as? String, "0")
    }

    func testAllSeventyEightFacesRenderInBothOrientations() throws {
        let app = app(extra: ["--test-card-faces"], audit: true)
        var renderedFaces = Set<Data>()
        for page in 0..<26 {
            let first = page * 3
            XCTAssertEqual(app.staticTexts["face-proof-title"].label, "Card faces \(first + 1)–\(first + 3) of 78")
            for index in first..<first + 3 {
                let name = app.staticTexts["face-name-\(index)"].label
                XCTAssertFalse(name.isEmpty)
                for orientation in ["upright", "reversed"] {
                    let face = app.descendants(matching: .any)["face-\(index)-\(orientation)"]
                    XCTAssertTrue(face.exists || face.waitForExistence(timeout: 5))
                    assertVisible(face, in: app, abovePinnedFooter: true)
                    XCTAssertEqual(face.label, "\(name), \(orientation.capitalized)")
                    XCTAssertEqual(face.frame.width, 72, accuracy: 1)
                    let pixels = face.screenshot().pngRepresentation
                    XCTAssertFalse(pixels.isEmpty)
                    XCTAssertTrue(renderedFaces.insert(pixels).inserted, "Duplicate face: \(name), \(orientation)")
                }
            }
            if page == 0 || page == 25 { try auditAndCapture(app, "card-faces--page-\(page + 1)") }
            else { capture(app, "card-faces--page-\(page + 1)") }
            let nextFirst = ((page + 1) % 26) * 3
            let nextTitle = "Card faces \(nextFirst + 1)–\(nextFirst + 3) of 78"
            tapWhenSettled(app.buttons["face-proof-next"])
            waitForDestination(nextTitle) {
                app.staticTexts["face-proof-title"].label == nextTitle
            }
        }
        XCTAssertEqual(renderedFaces.count, 156)
        XCTAssertEqual(app.staticTexts["face-proof-title"].label, "Card faces 1–3 of 78")
    }

    func testFaceSizesAndLargestTextProof() throws {
        let sizes = app(extra: ["--test-card-sizes"], audit: true)
        let sampleNames = ["The Star", "Ten of Wands", "Page of Cups", "Ten of Swords", "Queen of Pentacles",
                           "King of Wands", "King of Cups", "King of Swords", "King of Pentacles"]
        for (page, name) in sampleNames.enumerated() {
            for width in [214, 120, 84, 36] {
                let face = sizes.descendants(matching: .any)["face-size-\(width)"]
                scrollTo(face, in: sizes, abovePinnedFooter: true)
                XCTAssertEqual(face.frame.width, CGFloat(width), accuracy: 1)
                XCTAssertEqual(face.label, "\(name), Reversed")
                capture(sizes, "card-sizes--sample-\(page + 1)-width-\(width)")
            }
            if page == 0 { try auditAndCapture(sizes, "card-sizes--audit", expecting: sizes.buttons["face-proof-next"]) }
            let nextName = sampleNames[(page + 1) % sampleNames.count]
            sizes.buttons["face-proof-next"].tap()
            waitForDestination("Card sizes: \(nextName)") {
                sizes.staticTexts[nextName].exists
            }
        }
        sizes.terminate()
        let largest = app(extra: ["--test-card-faces", "--test-largest-text"])
        scrollTo(largest.staticTexts["face-proof-title"], in: largest)
        capture(largest, "card-faces--largest-text")
        for index in 0..<3 {
            scrollTo(largest.staticTexts["face-name-\(index)"], in: largest)
            scrollTo(largest.descendants(matching: .any)["face-\(index)-reversed"], in: largest)
            capture(largest, "card-faces--largest-text-row-\(index)")
        }
        scrollTo(largest.buttons["face-proof-next"], in: largest)
        capture(largest, "card-faces--largest-text-bottom")
        largest.buttons["face-proof-next"].tap()
        waitForDestination("Card faces 4–6 at largest text") {
            largest.staticTexts["face-name-3"].exists
        }
        XCTAssertTrue(largest.staticTexts["face-name-3"].exists)
        largest.terminate()
        let largeSizes = app(extra: ["--test-card-sizes", "--test-largest-text"])
        scrollTo(largeSizes.staticTexts["face-proof-title"], in: largeSizes)
        capture(largeSizes, "card-sizes--largest-text")
        for width in [214, 120, 84, 36] {
            scrollTo(largeSizes.descendants(matching: .any)["face-size-\(width)"], in: largeSizes)
            capture(largeSizes, "card-sizes--largest-text-width-\(width)")
        }
        scrollTo(largeSizes.buttons["face-proof-next"], in: largeSizes)
        capture(largeSizes, "card-sizes--largest-text-bottom")
        largeSizes.buttons["face-proof-next"].tap()
        waitForDestination("Card sizes: Ten of Wands at largest text") {
            largeSizes.staticTexts["Ten of Wands"].exists
        }
        XCTAssertTrue(largeSizes.staticTexts["Ten of Wands"].exists)

    }

    func testWelcomeFirstOpenDesignAndPersistentRouting() throws {
        let app = app(extra: ["--test-store-id", UUID().uuidString], memory: false, audit: true, welcome: true)
        XCTAssertTrue(app.staticTexts["welcome-name"].waitForExistence(timeout: 5))
        let expected = [
            "welcome-name": "Daybreak",
            "welcome-title": "One card.\nEvery morning.",
            "welcome-promise": "Pick a card, turn it over, and see how today reads for your work, your love life and the people around you.",
            "welcome-disclaimer": "A mirror, not a forecast. Readings are for entertainment and reflection, not prediction or professional advice."
        ]
        for (identifier, label) in expected {
            let element = app.staticTexts[identifier]
            assertVisible(element, in: app)
            XCTAssertEqual(element.label, label)
        }
        XCTAssertEqual(app.buttons.count, 1)
        XCTAssertEqual(app.buttons["welcome-draw"].label, "Draw my first card")
        assertVisible(app.buttons["welcome-draw"], in: app)
        XCTAssertEqual(app.textFields.count + app.secureTextFields.count + app.textViews.count, 0)
        XCTAssertEqual(app.alerts.count, 0)
        XCTAssertEqual(XCUIApplication(bundleIdentifier: "com.apple.springboard").alerts.count, 0)
        try auditAndCapture(app, "01-welcome")
        let hierarchy = XCTAttachment(string: app.debugDescription)
        hierarchy.name = "welcome-accessibility-hierarchy"
        hierarchy.lifetime = .keepAlways
        add(hierarchy)

        // An interruption before the action must not silently bypass the disclaimer.
        app.terminate()
        app.launch()
        XCTAssertTrue(app.buttons["welcome-draw"].waitForExistence(timeout: 5))
        app.buttons["welcome-draw"].tap()
        XCTAssertTrue(app.staticTexts["draw-title"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["welcome-name"].exists)
        app.terminate()
        app.launch()
        XCTAssertTrue(app.staticTexts["draw-title"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["welcome-draw"].exists)
        reveal(app)
        XCTAssertEqual(app.alerts.count, 0)
        XCTAssertEqual(XCUIApplication(bundleIdentifier: "com.apple.springboard").alerts.count, 0)
        app.buttons["see-meaning"].tap()
        XCTAssertTrue(app.staticTexts["today-title"].waitForExistence(timeout: 5))
        app.terminate()
        app.launch()
        XCTAssertTrue(app.staticTexts["today-title"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["welcome-draw"].exists)
        app.terminate()
        let dateIndex = app.launchArguments.firstIndex(of: "--test-date")!
        app.launchArguments[dateIndex + 1] = "2026-10-12T00:00:00Z"
        app.launch()
        XCTAssertTrue(app.staticTexts["draw-title"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["welcome-draw"].exists)
    }

    func testWelcomeRemainsUntilContinuedAcrossMidnight() {
        let app = app(extra: ["--test-controls"], welcome: true)
        XCTAssertTrue(app.buttons["welcome-draw"].waitForExistence(timeout: 5))
        testControl("test-next-day", in: app)
        XCTAssertTrue(app.buttons["welcome-draw"].exists)
        XCTAssertFalse(app.staticTexts["draw-title"].exists)
        app.buttons["welcome-draw"].tap()
        XCTAssertTrue(app.staticTexts["draw-title"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Monday 12 October"].exists)
    }

    func testWelcomeLargestTextAndReducedMotion() throws {
        let app = app(extra: ["--test-largest-text", "--test-reduce-motion"], animations: true, welcome: true)
        XCTAssertTrue(app.staticTexts["welcome-name"].waitForExistence(timeout: 5))
        // The top stop shows the whole headline, so it needs no stop of its own.
        assertVisible(app.staticTexts["welcome-title"], in: app)
        capture(app, "01-welcome--largest-text")
        scrollTo(app.staticTexts["welcome-promise"], in: app)
        capture(app, "01-welcome--largest-text-welcome-promise")
        scrollTo(app.staticTexts["welcome-disclaimer"], in: app)
        assertVisible(app.buttons["welcome-draw"], in: app)
        capture(app, "01-welcome--largest-text-bottom")
        let hierarchy = XCTAttachment(string: app.debugDescription)
        hierarchy.name = "welcome-largest-text-accessibility-hierarchy"
        hierarchy.lifetime = .keepAlways
        add(hierarchy)
        app.buttons["welcome-draw"].tap()
        XCTAssertTrue(app.staticTexts["draw-title"].waitForExistence(timeout: 5))
        app.terminate()

        let reduced = self.app(extra: ["--test-reduce-motion"], animations: true, welcome: true)
        XCTAssertTrue(reduced.buttons["welcome-draw"].waitForExistence(timeout: 5))
        capture(reduced, "01-welcome--reduce-motion")
        let before = reduced.scrollViews["screen-content"].screenshot().pngRepresentation
        Thread.sleep(forTimeInterval: 1)
        XCTAssertEqual(reduced.scrollViews["screen-content"].screenshot().pngRepresentation, before,
                       "Reduce Motion must leave the welcome card still")
        reduced.buttons["welcome-draw"].tap()
        XCTAssertTrue(reduced.staticTexts["draw-title"].waitForExistence(timeout: 5))
    }

    func testWelcomeSaveFailureKeepsWelcomeAndAllowsRetry() {
        let app = app(extra: ["--test-welcome-save-failure"], welcome: true)
        XCTAssertTrue(app.buttons["welcome-draw"].waitForExistence(timeout: 5))
        app.buttons["welcome-draw"].tap()
        let alert = app.alerts["Your welcome could not be saved"]
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        XCTAssertTrue(alert.staticTexts["Free some space on your phone if needed, then tap Draw my first card to try again. Your saved cards are unchanged."].exists)
        XCTAssertEqual(alert.buttons.count, 1)
        // Not audited: Dynamic Type flags the alert's system-drawn message, which the app cannot restyle.
        capture(app, "01-welcome--save-failed")
        alert.buttons["OK"].tap()
        XCTAssertTrue(app.buttons["welcome-draw"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["draw-title"].exists)
        app.buttons["welcome-draw"].tap()
        XCTAssertTrue(app.staticTexts["draw-title"].waitForExistence(timeout: 5))
    }

    func testWelcomeFloatingCardDoesNotDelayTheFirstDraw() {
        let app = app(animations: true, welcome: true)
        XCTAssertTrue(app.buttons["welcome-draw"].waitForExistence(timeout: 5))
        app.buttons["welcome-draw"].tap()
        XCTAssertTrue(app.buttons["draw-card-3"].waitForExistence(timeout: 5))
        reveal(app)
    }

    func testDrawRevealTodayAndDesignEvidence() throws {
        let app = app(audit: true)
        XCTAssertTrue(app.staticTexts["draw-title"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Pick the one that pulls at you"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["turn-over"].exists)
        var precedingLane: CGRect?
        for position in 1...5 {
            let card = app.buttons["draw-card-\(position)"]
            XCTAssertTrue(card.isHittable)
            assertVisible(card, in: app, abovePinnedFooter: true)
            if let precedingLane { XCTAssertLessThanOrEqual(precedingLane.maxX, card.frame.minX + 0.5) }
            precedingLane = card.frame
        }
        try auditAndCapture(app, "02-draw", expecting: app.staticTexts["draw-title"], app.buttons["draw-card-3"])
        let fanFrame = tapWhenSettled(app.buttons["draw-card-3"])
        waitForDestination("chosen daily card") {
            app.buttons["turn-over"].exists
        }
        XCTAssertTrue(app.buttons["turn-over"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["draw-title"].label, "This one is yours")
        XCTAssertTrue(app.buttons["draw-card-3"].isSelected)
        XCTAssertEqual(app.buttons["draw-card-3"].frame.midY, fanFrame.midY, accuracy: 0.5,
                       "Selection must preserve the fan/disc anchor to within pixel rounding")
        try auditAndCapture(app, "02-draw-card-chosen", expecting: app.staticTexts["draw-title"], app.buttons["turn-over"])
        app.buttons["turn-over"].tap()
        waitForDestination("Reveal card") {
            app.staticTexts["card-name"].exists
        }
        XCTAssertTrue(app.staticTexts["card-name"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["card-name"].label, "The Star")
        XCTAssertEqual(app.staticTexts["card-details"].label, "Upright · Major Arcana XVII")
        XCTAssertEqual(app.staticTexts["card-keywords"].label, "Hope, renewal, clarity, calm")
        XCTAssertFalse(app.staticTexts["core-interpretation"].exists)
        XCTAssertFalse(app.staticTexts["today-title"].waitForExistence(timeout: 2))
        for identifier in ["card-name", "card-details", "card-keywords"] {
            assertVisible(app.staticTexts[identifier], in: app, abovePinnedFooter: true)
        }
        assertVisible(app.buttons["see-meaning"], in: app)
        try auditAndCapture(app, "03-reveal", expecting: app.staticTexts["card-name"], app.buttons["see-meaning"])
        app.buttons["see-meaning"].tap()
        waitForDestination("Today interpretation") {
            app.staticTexts["core-interpretation"].exists
        }
        XCTAssertTrue(app.staticTexts["core-interpretation"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["core-interpretation"].label.contains("Hope may feel more useful"))
        XCTAssertEqual(app.windows.firstMatch.frame.size, CGSize(width: 390, height: 844), "Verify the reference viewport on the selected simulator")
        for identifier in ["today-card", "core-interpretation", "daily-colour", "daily-object", "daily-hour"] {
            assertVisible(app.descendants(matching: .any)[identifier].firstMatch, in: app)
        }
        assertTodayContent(app)
        try auditAndCapture(app, "04-today", today: true,
                            expecting: app.staticTexts["core-interpretation"], app.buttons["today-ask"])
        positionTodayAuditBelowCard(app, revealing: app.staticTexts["line-social"])
        try auditAndCapture(app, "04-today--bottom", today: true)
        scrollTo(app.staticTexts["next-card-arrival"], in: app)
        XCTAssertEqual(app.staticTexts["next-card-arrival"].label, "Your next card arrives at midnight")
        capture(app, "04-today--midnight")
        scrollTo(app.buttons["today-card"], in: app)
        app.buttons["today-card"].tap()
        waitForDestination("reopened Reveal") {
            app.buttons["back-to-today"].exists
        }
        XCTAssertTrue(app.buttons["back-to-today"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.descendants(matching: .any)["revealed-card"].label, "The Star, Upright")
        try auditAndCapture(app, "03-reveal--reopened")
        app.buttons["back-to-today"].tap()
        waitForDestination("Today") {
            app.staticTexts["today-title"].exists
        }
        XCTAssertTrue(app.staticTexts["today-title"].waitForExistence(timeout: 5))
        assertTodayContent(app)
        app.buttons["today-card"].tap()
        app.buttons["see-meaning"].tap()
        XCTAssertTrue(app.staticTexts["today-title"].waitForExistence(timeout: 5))
    }

    private func assertTodayContent(_ app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        let expected = ["daily-colour": "Colour, Sage", "daily-object": "Object, Something glass", "daily-hour": "Best hour, After 3 pm",
                        "score-career": "Career, 72 out of 100", "score-relationship": "Relationship, 81 out of 100",
                        "score-social": "Social, 64 out of 100", "line-career": "Share an idea you have been quietly tending.",
                        "line-relationship": "Let a kind word make room for connection.", "line-social": "Notice who gives you space to be yourself."]
        for (identifier, label) in expected {
            XCTAssertEqual(app.descendants(matching: .any)[identifier].firstMatch.label, label, file: file, line: line)
        }
        let scores = ["career", "relationship", "social"].map { app.descendants(matching: .any)["score-\($0)"].firstMatch.frame }
        XCTAssertEqual(scores[0].minY, scores[1].minY, accuracy: 1, file: file, line: line)
        XCTAssertEqual(scores[1].minY, scores[2].minY, accuracy: 1, file: file, line: line)
        XCTAssertLessThanOrEqual(app.descendants(matching: .any)["daily-hour"].firstMatch.frame.maxY, scores[0].minY, file: file, line: line)
    }

    func testTodayScrolledTextIsExposed() {
        let app = app(audit: true)
        reveal(app)
        app.buttons["see-meaning"].tap()
        XCTAssertTrue(app.staticTexts["today-title"].waitForExistence(timeout: 5))
        // Reproduce the retained failure's geometry, independently of native-audit scrolling.
        let viewport = visibleFrame(in: app)
        let origin = app.coordinate(withNormalizedOffset: .zero)
        let reading = app.staticTexts["core-interpretation"]
        let readingTop = viewport.minY + 129
        for _ in 0..<10 {
            let difference = reading.frame.minY - readingTop
            if abs(difference) < 5 { break }
            // A drag must cross the scroll view's touch threshold before content moves.
            let distance = difference + (difference > 0 ? 12 : -12)
            let start = origin.withOffset(CGVector(dx: viewport.midX, dy: viewport.midY + distance / 2))
            let end = origin.withOffset(CGVector(dx: viewport.midX, dy: viewport.midY - distance / 2))
            start.press(forDuration: 0.05, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.1)
        }
        capture(app, "04-today--voiceover-exposure")
        let hierarchy = XCTAttachment(string: app.debugDescription)
        hierarchy.name = "today-scrolled-accessibility-hierarchy"
        hierarchy.lifetime = .keepAlways
        add(hierarchy)
        XCTAssertEqual(reading.frame.minY, readingTop, accuracy: 5)

        let expected = [
            "card-details": "Upright · Major Arcana XVII",
            "core-interpretation": "Hope may feel more useful when you give it something small to do. Notice what restores a little perspective today, and make room to return to it.",
            "daily-colour": "Colour, Sage", "daily-object": "Object, Something glass", "daily-hour": "Best hour, After 3 pm",
            "score-career": "Career, 72 out of 100", "score-relationship": "Relationship, 81 out of 100", "score-social": "Social, 64 out of 100",
            "area-label-career": "Career", "line-career": "Share an idea you have been quietly tending."
        ]
        for (identifier, label) in expected {
            let element = app.descendants(matching: .any)[identifier].firstMatch
            assertVisible(element, in: app)
            XCTAssertEqual(element.label, label)
        }
        for title in ["Hope, renewal, clarity, calm", "How today sits", "What to do about it"] {
            assertVisible(app.staticTexts[title], in: app)
            XCTAssertEqual(app.staticTexts[title].label, title)
        }
        scrollTo(app.staticTexts["line-social"], in: app)
        // The resting tabs put Relationship below the first stop's viewport.
        for (identifier, label) in [
            "area-label-relationship": "Relationship", "line-relationship": "Let a kind word make room for connection.",
            "area-label-social": "Social", "line-social": "Notice who gives you space to be yourself."
        ] {
            let element = app.staticTexts[identifier]
            assertVisible(element, in: app)
            XCTAssertEqual(element.label, label)
        }
        capture(app, "04-today--voiceover-exposure-bottom")
        let bottomHierarchy = XCTAttachment(string: app.debugDescription)
        bottomHierarchy.name = "today-bottom-accessibility-hierarchy"
        bottomHierarchy.lifetime = .keepAlways
        add(bottomHierarchy)
    }

    func testTodaySnapshotSurvivesAChangedContentLibrary() {
        let app = app(extra: ["--test-store-id", UUID().uuidString], memory: false)
        reveal(app)
        app.buttons["see-meaning"].tap()
        XCTAssertTrue(app.staticTexts["today-title"].waitForExistence(timeout: 5))
        let interpretation = app.staticTexts["core-interpretation"].label
        assertTodayContent(app)
        app.terminate()
        app.launchArguments.append("--test-revised-content")
        app.launch()
        XCTAssertTrue(app.staticTexts["today-title"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["card-name"].label, "The Star")
        XCTAssertEqual(app.staticTexts["card-details"].label, "Upright · Major Arcana XVII")
        XCTAssertEqual(app.staticTexts["core-interpretation"].label, interpretation)
        assertTodayContent(app)
        app.terminate()
        let dateIndex = app.launchArguments.firstIndex(of: "--test-date")!
        app.launchArguments[dateIndex + 1] = "2026-10-12T00:00:00Z"
        app.launch()
        reveal(app)
        app.buttons["see-meaning"].tap()
        XCTAssertTrue(app.staticTexts["today-title"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["card-name"].label.hasPrefix("Revised "))
        XCTAssertEqual(app.descendants(matching: .any)["daily-colour"].firstMatch.label, "Colour, Clay")
        XCTAssertEqual(app.descendants(matching: .any)["score-career"].firstMatch.label, "Career, 10 out of 100")
        XCTAssertEqual(app.staticTexts["line-social"].label, "Revised social line.")
    }

    func testEarlierSnapshotKeepsItsOriginalReading() throws {
        let app = app(extra: ["--test-earlier-snapshot"], audit: true)
        XCTAssertTrue(app.staticTexts["today-title"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["card-name"].label, "The Star")
        XCTAssertTrue(app.staticTexts["core-interpretation"].label.contains("Hope may feel more useful"))
        XCTAssertTrue(app.staticTexts["This earlier draw has no saved extras or area readings."].exists)
        XCTAssertFalse(app.descendants(matching: .any)["daily-colour"].firstMatch.exists)
        try auditAndCapture(app, "04-today--earlier-snapshot", today: true)
        app.terminate()
        let largest = self.app(extra: ["--test-earlier-snapshot", "--test-largest-text"])
        capture(largest, "04-today--earlier-snapshot-largest-text")
        captureReadingOpening(in: largest, named: "04-today--earlier-snapshot-largest-text-opening")
        captureOverlappingContent(largest, through: largest.staticTexts["This earlier draw has no saved extras or area readings."],
                                  named: "04-today--earlier-snapshot-largest-text-bridge")
        scrollTo(largest.staticTexts["This earlier draw has no saved extras or area readings."], in: largest)
        dragContent(largest, up: true)
        assertVisible(largest.staticTexts["This earlier draw has no saved extras or area readings."], in: largest)
        capture(largest, "04-today--earlier-snapshot-largest-text-bottom")
    }

    func testAllFivePositionsGiveSameCardAndSaveTheirPosition() {
        var names: [String] = []
        var orientations: [String] = []
        for position in 1...5 {
            let app = app()
            reveal(app, position: position)
            XCTAssertEqual(app.staticTexts["draw-position"].label, "You picked card \(position) of five")
            names.append(app.staticTexts["card-name"].label)
            orientations.append(app.staticTexts["card-details"].label)
            app.terminate()
        }
        XCTAssertEqual(Set(names).count, 1)
        XCTAssertEqual(Set(orientations).count, 1)
    }

    func testSelectionCanChangeBeforeTurning() {
        let app = app()
        tapWhenSettled(app.buttons["draw-card-1"])
        tapWhenSettled(app.buttons["draw-card-5"])
        XCUIDevice.shared.press(.home)
        app.activate()
        XCTAssertTrue(app.buttons["draw-card-5"].isSelected)
        let turnOver = app.buttons["turn-over"]
        let ready = XCTNSPredicateExpectation(predicate: NSPredicate(format: "hittable == true"), object: turnOver)
        XCTAssertEqual(XCTWaiter.wait(for: [ready], timeout: 5), .completed)
        turnOver.tap()
        XCTAssertTrue(app.staticTexts["draw-position"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["draw-position"].label, "You picked card 5 of five")
    }

    func testShuffleInterruptionReplayUndoAndSameDailyCard() throws {
        let app = app(extra: ["--test-hold-shuffle"], animations: true)
        XCTAssertTrue(app.staticTexts["Washing the cards…"].waitForExistence(timeout: 5))
        for position in 1...5 { XCTAssertTrue(app.buttons["draw-card-\(position)"].isHittable) }
        XCTAssertEqual(app.staticTexts["shuffle-helper"].label, "Shuffling changes the order, not your card.")
        capture(app, "02-draw--washing-cards")
        tapWhenSettled(app.buttons["draw-card-1"])
        XCTAssertEqual(app.staticTexts["draw-title"].label, "This one is yours")
        XCTAssertTrue(app.buttons["turn-over"].isHittable)
        XCTAssertTrue(app.buttons["draw-card-1"].isSelected)
        app.buttons["choose-different"].tap()
        XCTAssertFalse(app.buttons["turn-over"].exists)
        XCTAssertEqual(app.staticTexts["draw-title"].label, "Pick the one that pulls at you")
        // A second shuffle interrupts/replaces the held first run without stale completion.
        for _ in 0..<2 {
            app.buttons["shuffle-again"].tap()
            XCTAssertEqual(app.staticTexts["draw-title"].label, "Washing the cards…")
        }
        tapWhenSettled(app.buttons["draw-card-5"])
        XCTAssertTrue(app.buttons["draw-card-5"].isSelected)
        app.buttons["turn-over"].tap()
        XCTAssertTrue(app.buttons["see-meaning"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["draw-position"].label, "You picked card 5 of five")
        let name = app.staticTexts["card-name"].label
        let details = app.staticTexts["card-details"].label
        waitForRitualToSettle(app)
        XCTAssertFalse(app.staticTexts["today-title"].waitForExistence(timeout: 2),
                       "Reveal must remain until the meaning action, including after the warming finishes")
        app.terminate()
        let unshuffled = self.app()
        reveal(unshuffled, position: 2)
        XCTAssertEqual(unshuffled.staticTexts["card-name"].label, name)
        XCTAssertEqual(unshuffled.staticTexts["card-details"].label, details)
    }

    func testAnimationOffSkipsEvenHeldShuffle() {
        let app = app(extra: ["--test-hold-shuffle"])
        XCTAssertEqual(app.staticTexts["draw-title"].value as? String, "settled")
        XCTAssertEqual(app.staticTexts["draw-title"].label, "Pick the one that pulls at you")
        for position in 1...5 { XCTAssertTrue(app.buttons["draw-card-\(position)"].isHittable) }
        app.buttons["shuffle-again"].tap()
        XCTAssertEqual(app.staticTexts["draw-title"].label, "Pick the one that pulls at you")
        reveal(app)
        XCTAssertEqual(app.descendants(matching: .any)["revealed-card"].value as? String, "settled")
        for identifier in ["card-name", "card-details", "card-keywords", "reveal-disclaimer"] {
            assertVisible(app.staticTexts[identifier], in: app, abovePinnedFooter: identifier != "reveal-disclaimer")
        }
        app.buttons["see-meaning"].tap()
        XCTAssertTrue(app.staticTexts["today-title"].waitForExistence(timeout: 5))
    }

    func testSavedDrawAndInstallSeedSurviveRelaunch() {
        let app = app(extra: ["--test-store-id", UUID().uuidString], memory: false)
        reveal(app, position: 2)
        let name = app.staticTexts["card-name"].label
        let details = app.staticTexts["card-details"].label
        app.terminate()
        // Changing a creation seed cannot replace an existing installation or saved snapshot.
        let index = app.launchArguments.firstIndex(of: "--test-seed")!
        app.launchArguments[index + 1] = "different-seed"
        let zoneIndex = app.launchArguments.firstIndex(of: "--test-time-zone")!
        app.launchArguments[zoneIndex + 1] = "Pacific/Auckland"
        app.launch()
        XCTAssertTrue(app.staticTexts["today-title"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["card-name"].label, name)
        XCTAssertEqual(app.staticTexts["card-details"].label, details)
        XCTAssertFalse(app.buttons["turn-over"].exists)
        app.terminate()
        let dateIndex = app.launchArguments.firstIndex(of: "--test-date")!
        app.launchArguments[dateIndex + 1] = "2026-10-12T00:00:00Z"
        app.launch()
        reveal(app)
        let nextName = app.staticTexts["card-name"].label
        let nextDetails = app.staticTexts["card-details"].label
        app.terminate()
        let expected = self.app(date: "2026-10-12T00:00:00Z")
        reveal(expected)
        XCTAssertEqual(expected.staticTexts["card-name"].label, nextName)
        XCTAssertEqual(expected.staticTexts["card-details"].label, nextDetails)
    }

    private func testControl(_ identifier: String, in app: XCUIApplication) {
        app.descendants(matching: .any)["test-controls"].tap()
        let action = app.descendants(matching: .any)[identifier]
        XCTAssertTrue(action.waitForExistence(timeout: 5), app.debugDescription)
        action.tap()
    }

    func testForegroundMidnightRoutesTodayToFreshDraw() {
        let app = app(extra: ["--test-controls"], date: "2026-10-11T12:59:59Z")
        reveal(app)
        let previousName = app.staticTexts["card-name"].label
        app.buttons["see-meaning"].tap()
        XCTAssertTrue(app.staticTexts["today-title"].waitForExistence(timeout: 5))
        testControl("test-next-day", in: app)
        XCTAssertTrue(app.staticTexts["draw-title"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Monday 12 October"].exists)
        XCTAssertFalse(app.buttons["turn-over"].exists)
        reveal(app)
        XCTAssertNotEqual(app.staticTexts["card-name"].label, previousName)
    }

    func testMidnightClearsUnturnedSelectionAndBackgroundReturnLeavesReveal() {
        let app = app(extra: ["--test-controls"])
        tapWhenSettled(app.buttons["draw-card-2"])
        XCTAssertTrue(app.buttons["turn-over"].exists)
        testControl("test-next-day", in: app)
        XCTAssertEqual(app.staticTexts["draw-title"].label, "Pick the one that pulls at you")
        XCTAssertFalse(app.buttons["turn-over"].exists)
        reveal(app)
        let previousName = app.staticTexts["card-name"].label
        testControl("test-background-day", in: app)
        XCUIDevice.shared.press(.home)
        app.activate()
        XCTAssertTrue(app.staticTexts["draw-title"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Tuesday 13 October"].exists)
        XCTAssertFalse(app.buttons["see-meaning"].exists)
        reveal(app)
        XCTAssertNotEqual(app.staticTexts["card-name"].label, previousName)
    }

    func testTravelBackAndForwardRestoresEachSavedDate() {
        let app = app(extra: ["--test-controls"], seed: "travel-2")
        reveal(app, position: 2)
        let name = app.staticTexts["card-name"].label
        let details = app.staticTexts["card-details"].label
        testControl("test-time-zone", in: app)
        XCTAssertTrue(app.staticTexts["draw-title"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Saturday 10 October"].exists)
        reveal(app, position: 5)
        let earlierName = app.staticTexts["card-name"].label
        let earlierDetails = app.staticTexts["card-details"].label
        XCTAssertNotEqual(earlierName, name)
        testControl("test-time-zone", in: app)
        XCTAssertTrue(app.staticTexts["today-title"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["today-title"].label, "Sunday 11 October")
        XCTAssertEqual(app.staticTexts["card-name"].label, name)
        XCTAssertEqual(app.staticTexts["card-details"].label, details)
        testControl("test-time-zone", in: app)
        XCTAssertEqual(app.staticTexts["today-title"].label, "Saturday 10 October")
        XCTAssertEqual(app.staticTexts["card-name"].label, earlierName)
        XCTAssertEqual(app.staticTexts["card-details"].label, earlierDetails)
    }

    func testTimeZoneChangeWithinSameDateKeepsReveal() {
        let app = app(extra: ["--test-controls", "--test-reduce-motion"], date: "2026-10-11T12:00:00Z", animations: true)
        reveal(app)
        let name = app.staticTexts["card-name"].label
        testControl("test-time-zone", in: app)
        XCTAssertTrue(app.buttons["see-meaning"].exists)
        XCTAssertFalse(app.staticTexts["today-title"].exists)
        XCTAssertEqual(app.staticTexts["card-name"].label, name)
        app.buttons["see-meaning"].tap()
        XCTAssertTrue(app.staticTexts["today-title"].waitForExistence(timeout: 5))
    }


    func testExpandedMajorDailyContentAndLongestNameAtBothTextSizes() throws {
        for largest in [false, true] {
            let app = app(extra: largest ? ["--test-largest-text"] : [], seed: "deck-priestess-10", audit: true)
            let suffix = largest ? "major-content-largest-text" : "major-content"
            scrollTo(app.buttons["draw-card-3"], in: app)
            tapWhenSettled(app.buttons["draw-card-3"])
            scrollTo(app.buttons["turn-over"], in: app)
            app.buttons["turn-over"].tap()
            XCTAssertTrue(app.staticTexts["card-name"].waitForExistence(timeout: 5))
            XCTAssertEqual(app.staticTexts["card-name"].label, "The High Priestess")
            XCTAssertEqual(app.staticTexts["card-details"].label, "Reversed · Major Arcana II")
            if largest {
                capture(app, "03-reveal--\(suffix)")
                captureOverlappingContent(app, through: app.staticTexts["reveal-disclaimer"], named: "03-reveal--\(suffix)-scroll")
                assertVisible(app.buttons["see-meaning"], in: app)
                capture(app, "03-reveal--\(suffix)-bottom")
            } else {
                try auditAndCapture(app, "03-reveal--\(suffix)", expecting: app.staticTexts["card-name"])
            }
            scrollTo(app.buttons["see-meaning"], in: app)
            app.buttons["see-meaning"].tap()
            XCTAssertTrue(app.staticTexts["today-title"].waitForExistence(timeout: 5))
            XCTAssertEqual(app.staticTexts["core-interpretation"].label,
                           "Other people's opinions may be crowding your own response. Pause to distinguish a useful observation from a story you have repeated to yourself.")
            XCTAssertEqual(app.descendants(matching: .any)["daily-colour"].firstMatch.label, "Colour, Slate")
            XCTAssertEqual(app.descendants(matching: .any)["score-career"].firstMatch.label, "Career, 52 out of 100")
            if largest {
                capture(app, "04-today--\(suffix)")
                captureOverlappingContent(app, through: app.staticTexts["line-social"], named: "04-today--\(suffix)-scroll")
                scrollTo(app.buttons["today-ask"], in: app)
                assertVisible(app.buttons["today-ask"], in: app)
                capture(app, "04-today--\(suffix)-bottom")
            } else {
                try auditAndCapture(app, "04-today--\(suffix)", today: true, expecting: app.staticTexts["core-interpretation"])
                positionTodayAuditBelowCard(app, revealing: app.staticTexts["line-social"])
                try auditAndCapture(app, "04-today--\(suffix)-area-readings", today: true)
                try captureTodayEnd(app, named: "04-today--\(suffix)-bottom")
            }
            XCTAssertEqual(app.staticTexts["line-relationship"].label, "Name a question you have been trying to answer by guessing.")
            app.terminate()
        }
    }

    func testExpandedMajorContentReachesQuestionAndNamedPersonReadings() throws {
        for (named, largest) in [(false, false), (true, false), (false, true), (true, true)] {
            // Priestess upright, Death reversed, World upright from the shrinking deck.
            let app = app(extra: ["--test-random-indices", "6,0,14,1,19,0"] + (largest ? ["--test-largest-text"] : []), audit: true)
            reachAsk(app, largest: largest)
            scrollTo(app.buttons["area-relationship"], in: app)
            app.buttons["area-relationship"].tap()
            if named {
                scrollTo(app.buttons["ask-person-entry"], in: app)
                app.buttons["ask-person-entry"].tap()
                enterPerson(app)
                scrollTo(app.buttons["submit-person"], in: app)
                app.buttons["submit-person"].tap()
                for _ in 0..<3 {
                    scrollTo(app.buttons["draw-card-3"], in: app)
                    tapWhenSettled(app.buttons["draw-card-3"])
                }
            } else {
                scrollTo(app.buttons["suggestion-0"], in: app)
                app.buttons["suggestion-0"].tap()
                scrollTo(app.buttons["submit-question"], in: app)
                app.buttons["submit-question"].tap()
                chooseSpread(app, largest: largest)
            }
            scrollTo(app.buttons["read-spread"], in: app)
            app.buttons["read-spread"].tap()
            XCTAssertTrue(app.staticTexts["reading-saved"].waitForExistence(timeout: 5))
            let expected = named ? [
                "you": "Notice which feelings you have kept private and which you want to put into words.",
                "them": "Let the other person explain their readiness in their own terms without pressing for your pace.",
                "connection": "Consider what you value in the whole connection, including the space for separate lives."
            ] : [
                "situation": "You may be holding a question that needs attention more than an immediate answer.",
                "action": "Choose one small adjustment without requiring yourself to settle the whole transition today.",
                "outcome": "Reflect on what a satisfying sense of completion means without expecting perfection."
            ]
            let suffix = (named ? "major-content-named-person" : "major-content-question") + (largest ? "-largest-text" : "")
            if largest { capture(app, "09-reading--\(suffix)") }
            else { try auditAndCapture(app, "09-reading--\(suffix)", expecting: app.staticTexts["reading-saved"]) }
            for position in named ? ["you", "them", "connection"] : ["situation", "action", "outcome"] {
                let passage = app.staticTexts["reading-\(position)"]
                XCTAssertEqual(passage.label, expected[position])
                if !largest {
                    scrollTo(passage, in: app)
                    try auditAndCapture(app, "09-reading--\(suffix)-\(position)", expecting: passage)
                }
            }
            if named { XCTAssertTrue(app.staticTexts["reading-lens"].label.contains("Sam")) }
            XCTAssertTrue(app.staticTexts["reflection-question"].label.hasSuffix("?"))
            if largest {
                captureOverlappingContent(app, through: app.staticTexts["reading-disclaimer"], named: "09-reading--\(suffix)-scroll")
                assertVisible(app.buttons["reading-done"], in: app)
                capture(app, "09-reading--\(suffix)-bottom")
            } else {
                scrollTo(app.staticTexts["reflection-question"], in: app)
                try auditAndCapture(app, "09-reading--\(suffix)-bottom", expecting: app.staticTexts["reflection-question"])
            }
            app.buttons["reading-done"].tap()
            XCTAssertTrue(app.staticTexts["today-title"].waitForExistence(timeout: 5))
            app.terminate()
        }
    }

    func testWandsAndCupsDailyContentAtBothTextSizes() throws {
        let fixtures = [
            (seed: "deck-wands-132", name: "Knight of Wands", orientation: "Upright", colour: "Clay", score: 81,
             interpretation: "You may feel ready to act on something that has caught your attention. Give that energy a clear direction, and check what you are agreeing to before moving at full speed.",
             relationship: "Express your interest while leaving space for a different response.", suffix: "wands-content"),
            (seed: "deck-cups-300", name: "Queen of Cups", orientation: "Reversed", colour: "Sage", score: 54,
             interpretation: "You may be attending so closely to other people's responses that your own becomes hard to hear. Pause to name what you feel and what you can offer, without taking responsibility for every feeling around you.",
             relationship: "Say what you need before trying to interpret the other person's mood.", suffix: "cups-content")
        ]
        for fixture in fixtures {
            for largest in [false, true] {
                let app = app(extra: largest ? ["--test-largest-text"] : [], seed: fixture.seed, audit: true)
                let suffix = fixture.suffix + (largest ? "-largest-text" : "")
                scrollTo(app.buttons["draw-card-3"], in: app)
                tapWhenSettled(app.buttons["draw-card-3"])
                scrollTo(app.buttons["turn-over"], in: app)
                tapWhenSettled(app.buttons["turn-over"])
                XCTAssertTrue(app.staticTexts["card-name"].waitForExistence(timeout: 5))
                XCTAssertEqual(app.staticTexts["card-name"].label, fixture.name)
                XCTAssertEqual(app.staticTexts["card-details"].label, "\(fixture.orientation) · Minor Arcana")
                if largest {
                    capture(app, "03-reveal--\(suffix)")
                    captureOverlappingContent(app, through: app.staticTexts["reveal-disclaimer"], named: "03-reveal--\(suffix)-scroll")
                    assertVisible(app.buttons["see-meaning"], in: app)
                    capture(app, "03-reveal--\(suffix)-bottom")
                } else {
                    try auditAndCapture(app, "03-reveal--\(suffix)", expecting: app.staticTexts["card-name"])
                }
                scrollTo(app.buttons["see-meaning"], in: app)
                tapWhenSettled(app.buttons["see-meaning"])
                XCTAssertTrue(app.staticTexts["today-title"].waitForExistence(timeout: 5))
                XCTAssertEqual(app.staticTexts["core-interpretation"].label, fixture.interpretation)
                XCTAssertEqual(app.descendants(matching: .any)["daily-colour"].firstMatch.label, "Colour, \(fixture.colour)")
                XCTAssertEqual(app.descendants(matching: .any)["score-career"].firstMatch.label, "Career, \(fixture.score) out of 100")
                XCTAssertEqual(app.staticTexts["line-relationship"].label, fixture.relationship)
                if largest {
                    capture(app, "04-today--\(suffix)")
                    captureOverlappingContent(app, through: app.staticTexts["next-card-arrival"], named: "04-today--\(suffix)-scroll")
                    capture(app, "04-today--\(suffix)-bottom")
                    scrollTo(app.buttons["today-ask"], in: app)
                    assertVisible(app.buttons["today-ask"], in: app)
                } else {
                    try auditAndCapture(app, "04-today--\(suffix)", today: true, expecting: app.staticTexts["core-interpretation"])
                    positionTodayAuditBelowCard(app, revealing: app.staticTexts["line-social"])
                    try auditAndCapture(app, "04-today--\(suffix)-area-readings", today: true)
                    try captureTodayEnd(app, named: "04-today--\(suffix)-bottom")
                    scrollTo(app.buttons["today-ask"], in: app)
                }
                tapWhenSettled(app.buttons["today-ask"])
                XCTAssertTrue(app.staticTexts["ask-title"].waitForExistence(timeout: 5))
                XCTAssertEqual(app.staticTexts["ask-area-line"].label, fixture.relationship)
                if largest {
                    capture(app, "05-ask--\(suffix)")
                    captureOverlappingContent(app, through: app.buttons["skip-relationship-status"], named: "05-ask--\(suffix)-scroll")
                    capture(app, "05-ask--\(suffix)-bottom")
                } else {
                    try auditAndCapture(app, "05-ask--\(suffix)", expecting: app.staticTexts["ask-area-line"])
                    scrollTo(app.buttons["skip-relationship-status"], in: app)
                    try auditAndCapture(app, "05-ask--\(suffix)-bottom", expecting: app.buttons["skip-relationship-status"])
                }
                app.terminate()
            }
        }
    }

    func testWandsAndCupsReachQuestionAndNamedPersonReadings() throws {
        for (named, largest) in [(false, false), (true, false), (false, true), (true, true)] {
            // Ace of Wands reversed, Knight of Cups upright, King of Wands upright.
            let app = app(extra: ["--test-random-indices", "22,1,46,0,34,0"] + (largest ? ["--test-largest-text"] : []), audit: true)
            let suffix = "wands-cups-" + (named ? "named-person" : "question") + (largest ? "-largest-text" : "")
            reachAsk(app, largest: largest)
            if named {
                scrollTo(app.buttons["ask-person-entry"], in: app)
                tapWhenSettled(app.buttons["ask-person-entry"])
                enterPerson(app)
                scrollTo(app.buttons["submit-person"], in: app)
                tapWhenSettled(app.buttons["submit-person"])
                for _ in 0..<3 {
                    scrollTo(app.buttons["draw-card-3"], in: app)
                    tapWhenSettled(app.buttons["draw-card-3"])
                }
            } else {
                scrollTo(app.buttons["suggestion-0"], in: app)
                tapWhenSettled(app.buttons["suggestion-0"])
                scrollTo(app.buttons["submit-question"], in: app)
                tapWhenSettled(app.buttons["submit-question"])
                chooseSpread(app, largest: largest)
            }
            let positions = named ? ["you", "them", "connection"] : ["situation", "action", "outcome"]
            let names = ["Ace of Wands", "Knight of Cups", "King of Wands"]
            for (index, position) in positions.enumerated() {
                let slot = app.descendants(matching: .any)["spread-slot-\(position)"].firstMatch
                XCTAssertTrue(slot.label.contains("\(names[index]), \(index == 0 ? "Reversed" : "Upright")"))
            }
            scrollTo(app.staticTexts["spread-question"], in: app)
            if largest {
                showNavigationTop(app)
                assertVisible(app.staticTexts["spread-progress"], in: app)
                assertVisible(app.staticTexts["spread-question"], in: app)
                capture(app, "08-three-card-pick-complete--\(suffix)")
                captureOverlappingContent(app, through: app.buttons["read-spread"], named: "08-three-card-pick-complete--\(suffix)-scroll")
                capture(app, "08-three-card-pick-complete--\(suffix)-bottom")
            } else {
                try auditAndCapture(app, "08-three-card-pick-complete--\(suffix)", expecting: app.buttons["read-spread"])
            }
            scrollTo(app.buttons["read-spread"], in: app)
            tapWhenSettled(app.buttons["read-spread"])
            XCTAssertTrue(app.staticTexts["reading-saved"].waitForExistence(timeout: 5))
            let expected = named ? [
                "Notice whether you want to begin something here or feel obliged to keep things moving. You can say which is true for you.",
                "Ask what kind of invitation the other person would welcome. A thoughtful gesture still leaves them free to prefer something else.",
                "Consider how shared direction can grow from two clear voices. A common plan needs participation as well as enthusiasm."
            ] : [
                "A possible beginning may be tangled with pressure to act immediately. Separate your own curiosity from the expectation to produce something.",
                "Offer a clear, sincere invitation or proposal and leave room for the response. Let the gesture say what you mean without promising more.",
                "Reflect on the kind of leadership you respect when a shared purpose matters more than personal control."
            ]
            if largest { capture(app, "09-reading--\(suffix)") }
            else { try auditAndCapture(app, "09-reading--\(suffix)", expecting: app.staticTexts["reading-saved"]) }
            for (index, position) in positions.enumerated() {
                let passage = app.staticTexts["reading-\(position)"]
                XCTAssertEqual(passage.label, expected[index])
                if !largest {
                    scrollTo(passage, in: app)
                    try auditAndCapture(app, "09-reading--\(suffix)-\(position)", expecting: passage)
                }
            }
            if named { XCTAssertTrue(app.staticTexts["reading-lens"].label.contains("Sam")) }
            XCTAssertTrue(app.staticTexts["reflection-question"].label.hasSuffix("?"))
            if largest {
                captureOverlappingContent(app, through: app.staticTexts["reading-disclaimer"], named: "09-reading--\(suffix)-scroll")
                assertVisible(app.buttons["reading-done"], in: app)
                capture(app, "09-reading--\(suffix)-bottom")
            } else {
                scrollTo(app.buttons["reading-response-notReally"], in: app)
                try auditAndCapture(app, "09-reading--\(suffix)-bottom", expecting:
                    app.staticTexts["reflection-question"], app.staticTexts["Something to sit with"],
                    app.staticTexts["reading-response-prompt"], app.buttons["reading-response-yes"],
                    app.buttons["reading-response-somewhat"], app.buttons["reading-response-notReally"],
                    app.buttons["reading-done"], app.staticTexts["reading-disclaimer"])
            }
            tapWhenSettled(app.buttons["reading-done"])
            XCTAssertTrue(app.staticTexts["today-title"].waitForExistence(timeout: 5))
            app.terminate()
        }
    }

    func testSwordsAndPentaclesDailyContentAtBothTextSizes() throws {
        let fixtures = [
            (seed: "swords-content-651", name: "Queen of Swords", orientation: "Upright", colour: "Sage", score: 76,
             interpretation: "You may be able to see a situation clearly while still caring about the people in it. Say what fits your experience, and let a clear boundary do its work without a harsh explanation.",
             relationship: "Name a boundary in language that leaves little room for guessing.", suffix: "swords-content"),
            (seed: "pentacles-content-150", name: "Knight of Pentacles", orientation: "Reversed", colour: "Sage", score: 55,
             interpretation: "A dependable routine may be starting to feel more like an obligation than a choice. Review one part of it and decide whether a small change would bring the purpose back into view.",
             relationship: "Ask whether an ordinary shared routine still feels good to both of you.", suffix: "pentacles-content")
        ]
        for fixture in fixtures {
            for largest in [false, true] {
                let app = app(extra: largest ? ["--test-largest-text"] : [], seed: fixture.seed, audit: true)
                let suffix = fixture.suffix + (largest ? "-largest-text" : "")
                scrollTo(app.buttons["draw-card-3"], in: app)
                tapWhenSettled(app.buttons["draw-card-3"])
                scrollTo(app.buttons["turn-over"], in: app)
                tapWhenSettled(app.buttons["turn-over"])
                XCTAssertTrue(app.staticTexts["card-name"].waitForExistence(timeout: 5))
                XCTAssertEqual(app.staticTexts["card-name"].label, fixture.name)
                XCTAssertEqual(app.staticTexts["card-details"].label, "\(fixture.orientation) · Minor Arcana")
                if largest {
                    capture(app, "03-reveal--\(suffix)")
                    captureOverlappingContent(app, through: app.staticTexts["reveal-disclaimer"], named: "03-reveal--\(suffix)-scroll")
                    assertVisible(app.buttons["see-meaning"], in: app)
                    capture(app, "03-reveal--\(suffix)-bottom")
                } else {
                    try auditAndCapture(app, "03-reveal--\(suffix)", expecting: app.staticTexts["card-name"])
                }
                scrollTo(app.buttons["see-meaning"], in: app)
                tapWhenSettled(app.buttons["see-meaning"])
                XCTAssertTrue(app.staticTexts["today-title"].waitForExistence(timeout: 5))
                XCTAssertEqual(app.staticTexts["core-interpretation"].label, fixture.interpretation)
                XCTAssertEqual(app.descendants(matching: .any)["daily-colour"].firstMatch.label, "Colour, \(fixture.colour)")
                XCTAssertEqual(app.descendants(matching: .any)["score-career"].firstMatch.label, "Career, \(fixture.score) out of 100")
                XCTAssertEqual(app.staticTexts["line-relationship"].label, fixture.relationship)
                if largest {
                    capture(app, "04-today--\(suffix)")
                    captureOverlappingContent(app, through: app.staticTexts["next-card-arrival"], named: "04-today--\(suffix)-scroll")
                    capture(app, "04-today--\(suffix)-bottom")
                    scrollTo(app.buttons["today-ask"], in: app)
                    assertVisible(app.buttons["today-ask"], in: app)
                } else {
                    try auditAndCapture(app, "04-today--\(suffix)", today: true, expecting: app.staticTexts["core-interpretation"])
                    positionTodayAuditBelowCard(app, revealing: app.staticTexts["line-social"])
                    try auditAndCapture(app, "04-today--\(suffix)-area-readings", today: true)
                    try captureTodayEnd(app, named: "04-today--\(suffix)-bottom")
                    scrollTo(app.buttons["today-ask"], in: app)
                }
                tapWhenSettled(app.buttons["today-ask"])
                XCTAssertTrue(app.staticTexts["ask-title"].waitForExistence(timeout: 5))
                XCTAssertEqual(app.staticTexts["ask-area-line"].label, fixture.relationship)
                if largest {
                    capture(app, "05-ask--\(suffix)")
                    captureOverlappingContent(app, through: app.buttons["skip-relationship-status"], named: "05-ask--\(suffix)-scroll")
                    capture(app, "05-ask--\(suffix)-bottom")
                } else {
                    try auditAndCapture(app, "05-ask--\(suffix)", expecting: app.staticTexts["ask-area-line"])
                    scrollTo(app.buttons["skip-relationship-status"], in: app)
                    try auditAndCapture(app, "05-ask--\(suffix)-bottom", expecting: app.buttons["skip-relationship-status"])
                }
                app.terminate()
            }
        }
    }

    func testSwordsAndPentaclesReachQuestionAndNamedPersonReadings() throws {
        for (named, largest) in [(false, false), (true, false), (false, true), (true, true)] {
            // Ace of Swords reversed, Queen of Pentacles upright, King of Swords upright.
            let app = app(extra: ["--test-random-indices", "50,1,75,0,62,0"] + (largest ? ["--test-largest-text"] : []), audit: true)
            let suffix = "swords-pentacles-" + (named ? "named-person" : "question") + (largest ? "-largest-text" : "")
            reachAsk(app, largest: largest)
            if named {
                scrollTo(app.buttons["ask-person-entry"], in: app)
                tapWhenSettled(app.buttons["ask-person-entry"])
                enterPerson(app)
                scrollTo(app.buttons["submit-person"], in: app)
                tapWhenSettled(app.buttons["submit-person"])
                for _ in 0..<3 {
                    scrollTo(app.buttons["draw-card-3"], in: app)
                    tapWhenSettled(app.buttons["draw-card-3"])
                }
            } else {
                scrollTo(app.buttons["suggestion-0"], in: app)
                tapWhenSettled(app.buttons["suggestion-0"])
                scrollTo(app.buttons["submit-question"], in: app)
                tapWhenSettled(app.buttons["submit-question"])
                chooseSpread(app, largest: largest)
            }
            let positions = named ? ["you", "them", "connection"] : ["situation", "action", "outcome"]
            let names = ["Ace of Swords", "Queen of Pentacles", "King of Swords"]
            for (index, position) in positions.enumerated() {
                let slot = app.descendants(matching: .any)["spread-slot-\(position)"].firstMatch
                XCTAssertTrue(slot.label.contains("\(names[index]), \(index == 0 ? "Reversed" : "Upright")"))
            }
            scrollTo(app.staticTexts["spread-question"], in: app)
            if largest {
                showNavigationTop(app)
                assertVisible(app.staticTexts["spread-progress"], in: app)
                assertVisible(app.staticTexts["spread-question"], in: app)
                capture(app, "08-three-card-pick-complete--\(suffix)")
                captureOverlappingContent(app, through: app.buttons["read-spread"], named: "08-three-card-pick-complete--\(suffix)-scroll")
                capture(app, "08-three-card-pick-complete--\(suffix)-bottom")
            } else {
                try auditAndCapture(app, "08-three-card-pick-complete--\(suffix)", expecting: app.buttons["read-spread"])
            }
            scrollTo(app.buttons["read-spread"], in: app)
            tapWhenSettled(app.buttons["read-spread"])
            XCTAssertTrue(app.staticTexts["reading-saved"].waitForExistence(timeout: 5))
            let expected = named ? [
                "You may be unsure how to say something without being misunderstood. Begin with what you know about your own experience.",
                "Ask which everyday comforts matter to the other person. A caring intention becomes more specific when you hear their preference.",
                "The connection may benefit from fair agreements that neither person has to guess. Review whether the same standards apply to both of you."
            ] : [
                "You may be trying to reach a conclusion before the details are clear. Separate what you have observed from what you have inferred.",
                "Choose one practical improvement to the space, routine or task in front of you. Let it be useful without requiring you to attend to everything.",
                "Consider what would make your judgement both explainable and open to correction."
            ]
            if largest { capture(app, "09-reading--\(suffix)") }
            else { try auditAndCapture(app, "09-reading--\(suffix)", expecting: app.staticTexts["reading-saved"]) }
            for (index, position) in positions.enumerated() {
                let passage = app.staticTexts["reading-\(position)"]
                XCTAssertEqual(passage.label, expected[index])
                if !largest {
                    scrollTo(passage, in: app)
                    try auditAndCapture(app, "09-reading--\(suffix)-\(position)", expecting: passage)
                }
            }
            if named { XCTAssertTrue(app.staticTexts["reading-lens"].label.contains("Sam")) }
            XCTAssertTrue(app.staticTexts["reflection-question"].label.hasSuffix("?"))
            if largest {
                captureOverlappingContent(app, through: app.staticTexts["reading-disclaimer"], named: "09-reading--\(suffix)-scroll")
                assertVisible(app.buttons["reading-done"], in: app)
                capture(app, "09-reading--\(suffix)-bottom")
            } else {
                scrollTo(app.buttons["reading-response-notReally"], in: app)
                try auditAndCapture(app, "09-reading--\(suffix)-bottom", expecting:
                    app.staticTexts["reflection-question"], app.staticTexts["Something to sit with"],
                    app.staticTexts["reading-response-prompt"], app.buttons["reading-response-yes"],
                    app.buttons["reading-response-somewhat"], app.buttons["reading-response-notReally"],
                    app.buttons["reading-done"], app.staticTexts["reading-disclaimer"])
            }
            tapWhenSettled(app.buttons["reading-done"])
            XCTAssertTrue(app.staticTexts["today-title"].waitForExistence(timeout: 5))
            app.terminate()
        }
    }

    func testReversedCardUsesItsOwnMeaning() throws {
        let app = app(seed: "deck-reversed-215", audit: true)
        reveal(app)
        XCTAssertEqual(app.staticTexts["card-name"].label, "The Star")
        XCTAssertEqual(app.staticTexts["card-details"].label, "Reversed · Major Arcana XVII")
        XCTAssertEqual(app.descendants(matching: .any)["revealed-card"].label, "The Star, Reversed")
        try auditAndCapture(app, "03-reveal--reversed", expecting: app.staticTexts["card-name"], app.buttons["see-meaning"])
        app.buttons["see-meaning"].tap()
        waitForDestination("Today interpretation for the reversed card") {
            app.staticTexts["core-interpretation"].exists
        }
        XCTAssertTrue(app.staticTexts["core-interpretation"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["core-interpretation"].label.contains("Hope may feel more useful"))
        XCTAssertEqual(app.descendants(matching: .any)["daily-colour"].firstMatch.label, "Colour, Blue")
        XCTAssertEqual(app.descendants(matching: .any)["score-career"].firstMatch.label, "Career, 54 out of 100")
        XCTAssertEqual(app.staticTexts["line-relationship"].label, "Name a need without asking for an instant answer.")
        capture(app, "04-today--reversed")
        positionTodayAuditBelowCard(app, revealing: app.staticTexts["line-social"])
        for area in ["career", "relationship", "social"] {
            assertVisible(app.staticTexts["area-label-\(area)"], in: app)
            assertVisible(app.staticTexts["line-\(area)"], in: app)
        }
        capture(app, "04-today--reversed-area-readings")
        try captureTodayEnd(app, named: "04-today--reversed-bottom")
    }

    private func captureTodayEnd(_ app: XCUIApplication, named name: String) throws {
        let lastHeading = app.staticTexts["area-label-social"]
        let lastRow = app.staticTexts["line-social"]
        let ask = app.buttons["today-ask"]
        let midnight = app.staticTexts["next-card-arrival"]
        scrollTo(midnight, in: app)
        waitForSettled([lastHeading, lastRow, ask, midnight])
        for element in [lastHeading, lastRow, ask, midnight] { assertVisible(element, in: app) }
        let tabs = try XCTUnwrap(visibleTabs(in: app))
        let safeArea = app.otherElements["test-safe-viewport"].frame
        for tab in ["today", "ask", "history"] {
            XCTAssertTrue(safeArea.contains(tabs.buttons["tab-\(tab)"].frame))
        }
        try auditAndCapture(app, name, today: true, revealDeferred: { target in
            let reading = app.staticTexts["core-interpretation"]
            if target.frame.minY < reading.frame.minY {
                // Header text sits beside the illustration at this size. Bring
                // both fully onscreen before auditing this separate scroll stop.
                let card = app.buttons["today-card"]
                self.scrollTo(app.staticTexts["today-title"], in: app)
                self.waitForSettled([card, target])
                self.assertVisible(card, in: app)
                self.assertVisible(target, in: app)
            } else {
                self.positionTodayAuditBelowCard(app, revealing: target)
            }
        }, expecting: lastHeading, lastRow, ask, midnight)
    }

    func testStorageOpenFailureRecoveryAndDesignEvidence() throws {
        let failed = app(extra: ["--test-storage-open-failure"], audit: true)
        XCTAssertTrue(failed.staticTexts["storage-error-title"].waitForExistence(timeout: 5))
        XCTAssertTrue(failed.buttons["storage-retry"].isHittable)
        try auditAndCapture(failed, "storage-open-failure", expecting: failed.staticTexts["storage-error-title"], failed.buttons["storage-retry"])
        failed.buttons["storage-retry"].tap()
        waitForDestination("Draw after storage retry") {
            failed.staticTexts["draw-title"].exists
        }
        XCTAssertTrue(failed.staticTexts["draw-title"].waitForExistence(timeout: 5))
        failed.terminate()

        let largest = app(extra: ["--test-storage-open-failure", "--test-largest-text"])
        scrollTo(largest.staticTexts["storage-error-title"], in: largest)
        capture(largest, "storage-open-failure--largest-text")
        scrollTo(largest.buttons["storage-retry"], in: largest)
        capture(largest, "storage-open-failure--largest-text-bottom")
    }

    private func captureReadingOpening(in app: XCUIApplication, named name: String) {
        let interpretation = app.staticTexts["core-interpretation"]
        XCTAssertTrue(interpretation.exists)
        // A long paragraph exceeds a viewport. Capture an overlapping opening before its end.
        // Do not rely on isHittable: partially cropped text can still be tappable.
        for _ in 0..<10 {
            let viewport = visibleFrame(in: app)
            let top = interpretation.frame.minY
            if top >= viewport.minY + 20 && top <= viewport.midY { break }
            let delta = max(-viewport.height / 2, min(viewport.height / 2, top - viewport.minY - 120))
            let origin = app.coordinate(withNormalizedOffset: .zero)
            let start = origin.withOffset(CGVector(dx: viewport.midX, dy: viewport.midY + delta / 2))
            let end = origin.withOffset(CGVector(dx: viewport.midX, dy: viewport.midY - delta / 2))
            start.press(forDuration: 0.1, thenDragTo: end)
        }
        XCTAssertGreaterThanOrEqual(interpretation.frame.minY, visibleFrame(in: app).minY + 20)
        XCTAssertLessThanOrEqual(interpretation.frame.minY, visibleFrame(in: app).midY)
        capture(app, name)
    }

    private func captureOverlappingContent(_ app: XCUIApplication, through last: XCUIElement, named name: String) {
        // Drags of at most half a viewport, held before release, preserve overlap.
        // This records long paragraphs as well as complete rows; it does not change audit rules.
        XCTAssertTrue(last.exists)
        for index in 0..<40 {
            let viewport = scrollViewport(in: app)
            let frame = last.frame
            if viewport.contains(frame) { break }
            // Near-full-height rows cannot leave 24 points clear. Aim within the
            // available space while retaining enough movement to start a drag.
            let settlingDistance = min(24, 12 + max(0, viewport.height - frame.height) / 2)
            let delta = frame.maxY > viewport.maxY
                ? min(viewport.height / 2, frame.maxY - viewport.maxY + settlingDistance)
                : -min(viewport.height / 2, viewport.minY - frame.minY + settlingDistance)
            let origin = app.coordinate(withNormalizedOffset: .zero)
            let start = origin.withOffset(CGVector(dx: viewport.midX, dy: viewport.midY + delta / 2))
            let end = origin.withOffset(CGVector(dx: viewport.midX, dy: viewport.midY - delta / 2))
            start.press(forDuration: 0.1, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.2)
            capture(app, "\(name)-\(index)")
        }
        assertVisible(last, in: app)
    }

    func testLargestTextAndReduceMotion() throws {
        let app = app(extra: ["--test-largest-text", "--test-reduce-motion"], animations: true)
        scrollTo(app.staticTexts["draw-title"], in: app)
        capture(app, "02-draw--largest-text")
        scrollTo(app.buttons["draw-card-3"], in: app)
        capture(app, "02-draw--largest-text-fan")
        scrollTo(app.staticTexts["shuffle-helper"], in: app)
        assertVisible(app.buttons["shuffle-again"], in: app)
        capture(app, "02-draw--largest-text-bottom")
        scrollTo(app.buttons["draw-card-3"], in: app)
        tapWhenSettled(app.buttons["draw-card-3"])
        scrollTo(app.buttons["draw-history"], in: app)
        dragContent(app, up: false)
        assertVisible(app.staticTexts["Sunday 11 October"], in: app)
        assertVisible(app.buttons["draw-history"], in: app)
        capture(app, "02-draw-card-chosen--largest-text-top")
        scrollTo(app.staticTexts["draw-title"], in: app)
        capture(app, "02-draw-card-chosen--largest-text")
        scrollTo(app.buttons["turn-over"], in: app)
        capture(app, "02-draw-card-chosen--largest-text-bottom")
        app.buttons["turn-over"].tap()
        scrollTo(app.buttons["share-image"], in: app)
        assertVisible(app.buttons["share-image"], in: app)
        capture(app, "03-reveal--largest-text-share")
        scrollTo(app.staticTexts["draw-position"], in: app)
        capture(app, "03-reveal--largest-text")
        for identifier in ["card-name", "card-details", "card-keywords"] {
            scrollTo(app.staticTexts[identifier], in: app)
        }
        scrollTo(app.staticTexts["reveal-disclaimer"], in: app)
        assertVisible(app.buttons["see-meaning"], in: app)
        capture(app, "03-reveal--largest-text-bottom")
        app.buttons["see-meaning"].tap()
        scrollTo(app.staticTexts["today-title"], in: app)
        capture(app, "04-today--largest-text")
        for identifier in ["card-name", "card-details"] {
            scrollTo(app.staticTexts[identifier], in: app)
        }
        captureReadingOpening(in: app, named: "04-today--largest-text-opening")
        let interpretation = app.staticTexts["core-interpretation"]
        // Verify the paragraph's width and reachable final line.
        for _ in 0..<10 {
            if interpretation.frame.maxY <= visibleFrame(in: app).maxY { break }
            dragContent(app, up: true)
        }
        let viewport = visibleFrame(in: app)
        XCTAssertFalse(interpretation.frame.isEmpty)
        XCTAssertGreaterThan(interpretation.frame.maxY, viewport.minY)
        XCTAssertLessThanOrEqual(interpretation.frame.maxY, viewport.maxY)
        XCTAssertGreaterThanOrEqual(interpretation.frame.minX, viewport.minX)
        XCTAssertLessThanOrEqual(interpretation.frame.maxX, viewport.maxX)
        capture(app, "04-today--largest-text-reading-end")
        for identifier in ["daily-colour", "daily-object", "daily-hour", "score-career", "score-relationship", "score-social",
                           "line-career", "line-relationship", "line-social"] {
            scrollTo(app.descendants(matching: .any)[identifier].firstMatch, in: app)
            capture(app, "04-today--largest-text-\(identifier)")
        }
        dragContent(app, up: true)
        assertVisible(app.staticTexts["line-social"], in: app)
        capture(app, "04-today--largest-text-bottom")
        scrollTo(app.staticTexts["next-card-arrival"], in: app)
        XCTAssertEqual(app.staticTexts["next-card-arrival"].label, "Your next card arrives at midnight")
        capture(app, "04-today--largest-text-midnight")
        scrollTo(app.buttons["today-card"], in: app)
        app.buttons["today-card"].tap()
        scrollTo(app.buttons["back-to-today"], in: app)
        capture(app, "03-reveal--reopened-largest-text")
        let modalDetails = activeScrollView(in: app).staticTexts["card-details"]
        scrollTo(modalDetails, in: app)
        XCTAssertGreaterThan(modalDetails.frame.height, 40,
                             "The modal must retain the injected largest text size")
        capture(app, "03-reveal--reopened-largest-text-details")
        scrollTo(app.staticTexts["reveal-disclaimer"], in: app)
        assertVisible(app.buttons["see-meaning"], in: app)
        capture(app, "03-reveal--reopened-largest-text-bottom")
        app.buttons["see-meaning"].tap()
        XCTAssertTrue(app.staticTexts["today-title"].waitForExistence(timeout: 5))
        app.terminate()
        let reduced = self.app(extra: ["--test-reduce-motion", "--test-hold-shuffle"], animations: true)
        XCTAssertTrue(reduced.buttons["draw-card-3"].waitForExistence(timeout: 5))
        XCTAssertEqual(reduced.staticTexts["draw-title"].label, "Pick the one that pulls at you")
        XCTAssertEqual(reduced.staticTexts["draw-title"].value as? String, "settled")
        for position in 1...5 {
            XCTAssertTrue(reduced.buttons["draw-card-\(position)"].isHittable)
            assertVisible(reduced.buttons["draw-card-\(position)"], in: reduced, abovePinnedFooter: true)
        }
        capture(reduced, "02-draw--reduce-motion")
        reduced.buttons["shuffle-again"].tap()
        XCTAssertEqual(reduced.staticTexts["draw-title"].label, "Pick the one that pulls at you")
        tapWhenSettled(reduced.buttons["draw-card-3"])
        capture(reduced, "02-draw-card-chosen--reduce-motion")
        reduced.buttons["turn-over"].tap()
        XCTAssertEqual(reduced.descendants(matching: .any)["revealed-card"].value as? String, "settled")
        for identifier in ["card-name", "card-details", "card-keywords", "reveal-disclaimer"] {
            assertVisible(reduced.staticTexts[identifier], in: reduced, abovePinnedFooter: identifier != "reveal-disclaimer")
        }
        capture(reduced, "03-reveal--reduce-motion")
        reduced.buttons["see-meaning"].tap()
        reduced.buttons["today-card"].tap()
        XCTAssertTrue(reduced.buttons["back-to-today"].waitForExistence(timeout: 5))
        capture(reduced, "03-reveal--reopened-reduce-motion")
        reduced.buttons["back-to-today"].tap()
        XCTAssertTrue(reduced.staticTexts["today-title"].waitForExistence(timeout: 5))
    }

    func testContrastMeasurementSelfChecks() {
        func synthetic(background: UInt8, text: UInt8) -> CGImage {
            var pixels: [UInt8] = []
            for _ in 0..<40 {
                for x in 0..<100 {
                    let grey = x < 70 ? background : text
                    pixels += [grey, grey, grey, 255]
                }
            }
            let provider = CGDataProvider(data: Data(pixels) as CFData)!
            return CGImage(width: 100, height: 40, bitsPerComponent: 8, bitsPerPixel: 32,
                           bytesPerRow: 400, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                           bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue),
                           provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent)!
        }
        for (background, text, expected) in [(UInt8(255), UInt8(67), 10.0),
                                               (UInt8(67), UInt8(255), 10.0),
                                               (UInt8(255), UInt8(149), 3.0)] {
            let measured = measuredContrast(synthetic(background: background, text: text))
            XCTAssertNotNil(measured)
            XCTAssertEqual(measured?.ratio ?? 0, expected, accuracy: 0.25)
            if expected == 3 { XCTAssertLessThan(measured?.ratio ?? .infinity, 4.5) }
        }
    }

    private func openHistory(_ app: XCUIApplication) {
        let tab = app.buttons["tab-history"]
        if tab.exists { tab.tap() } else { app.buttons["draw-history"].tap() }
        XCTAssertTrue(app.staticTexts["history-title"].waitForExistence(timeout: 5))
    }

    func testHistoryCalendarFiltersAndDesignEvidence() throws {
        let app = app(extra: ["--test-history-days", "10"], audit: true)
        openHistory(app)
        XCTAssertTrue(app.buttons["tab-history"].isSelected)
        XCTAssertLessThan(app.buttons["tab-today"].frame.midX, app.buttons["tab-ask"].frame.midX)
        XCTAssertLessThan(app.buttons["tab-ask"].frame.midX, app.buttons["tab-history"].frame.midX)
        XCTAssertEqual(app.staticTexts["history-month"].label, "October 2026")
        XCTAssertEqual(app.staticTexts["history-month-count"].label, "10 cards drawn")
        let today = app.staticTexts["history-day-2026-10-11"]
        XCTAssertTrue(today.label.contains("Today, Card drawn"))
        XCTAssertTrue(app.descendants(matching: .any)["history-day-2026-10-12"].firstMatch.label.contains("Future day"))
        XCTAssertFalse(app.descendants(matching: .any)["history-day-2026-10-01"].firstMatch.label.contains("Card drawn"))
        try auditAndCapture(app, "10-history", expecting: app.staticTexts["history-title"], app.staticTexts["history-month"])
        scrollTo(app.buttons["history-filter-all"], in: app)
        for area in ["all", "career", "relationship", "social"] {
            let filter = app.buttons["history-filter-\(area)"]
            // Frame subtraction can represent an exact 44 points as 43.99999999999994.
            XCTAssertGreaterThanOrEqual(filter.frame.height + 0.000_001, 44)
            XCTAssertGreaterThanOrEqual(filter.frame.width + 0.000_001, 44)
        }
        for (index, area) in ["career", "relationship", "social"].enumerated() {
            scrollTo(app.buttons["history-filter-\(area)"], in: app)
            app.buttons["history-filter-\(area)"].tap()
            waitForDestination("History filtered to \(area)") {
                app.buttons["history-filter-\(area)"].isSelected
            }
            let row = app.buttons["history-reading-00000000-0000-0000-0000-00000000000\(index + 1)"]
            scrollTo(row, in: app)
            XCTAssertTrue(row.label.contains("\(area.capitalized) question"))
            XCTAssertEqual(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'history-daily-'")).count, 0)
            XCTAssertEqual(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'history-reading-'")).count, 1)
        }
        try auditAndCapture(app, "10-history--filtered", expecting: app.buttons["history-filter-social"])
        scrollTo(app.buttons["history-filter-all"], in: app)
        app.buttons["history-filter-all"].tap()
        waitForDestination("History with all areas selected") {
            app.buttons["history-filter-all"].isSelected
        }
        let firstReading = app.buttons["history-reading-00000000-0000-0000-0000-000000000001"]
        scrollTo(firstReading, in: app)
        let daily = app.buttons["history-daily-2026-10-11"]
        XCTAssertLessThan(firstReading.frame.minY, daily.frame.minY)
        XCTAssertEqual(app.buttons["history-filter-all"].label, "All")
        XCTAssertTrue(firstReading.label.contains("Career question · Today"))
        XCTAssertEqual(daily.label, "The Star, upright, Daily card · Today")
        scrollTo(app.buttons["history-daily-2026-10-06"], in: app)
        capture(app, "10-history--list")
        let hierarchy = XCTAttachment(string: app.debugDescription)
        hierarchy.name = "history-accessibility-hierarchy"
        hierarchy.lifetime = .keepAlways
        add(hierarchy)
        // The oldest reading is beyond the ten daily cards, proving the month does not limit the list.
        let oldest = app.buttons["history-reading-00000000-0000-0000-0000-000000000003"]
        for _ in 0..<8 {
            if oldest.exists && oldest.isHittable { break }
            activeScrollView(in: app).swipeUp(velocity: .slow)
        }
        scrollTo(oldest, in: app)
        try auditAndCapture(app, "10-history--bottom", expecting: oldest)
        scrollTo(app.staticTexts["history-title"], in: app)
        app.buttons["history-previous-month"].tap()
        waitForDestination("History for September 2026") {
            app.staticTexts["history-month"].label == "September 2026"
        }
        XCTAssertEqual(app.staticTexts["history-month"].label, "September 2026")
        XCTAssertEqual(app.staticTexts["history-month-count"].label, "0 cards drawn")
        app.buttons["history-next-month"].tap()
        app.buttons["history-next-month"].tap()
        XCTAssertEqual(app.staticTexts["history-month"].label, "November 2026")
        XCTAssertTrue(app.descendants(matching: .any)["history-day-2026-11-01"].firstMatch.label.contains("Future day"))

        // The prior day's Strength is visibly distinct from the live Star fixture.
        scrollTo(app.buttons["history-daily-2026-10-10"], in: app)
        app.buttons["history-daily-2026-10-10"].tap()
        XCTAssertEqual(app.staticTexts["today-title"].label, "Saturday 10 October 2026")
        XCTAssertTrue(try XCTUnwrap(visibleTabs(in: app)).buttons["tab-history"].isSelected)
        app.buttons["today-card"].tap()
        XCTAssertEqual(app.buttons["back-to-today"].label, "Back to daily card")
        let archiveRevealName = activeScrollView(in: app).staticTexts["card-name"]
        XCTAssertEqual(archiveRevealName.label, "Strength")
        XCTAssertNil(visibleTabs(in: app), "Reveal keeps the resting tabs hidden")
        try auditAndCapture(app, "03-reveal--history", expecting: app.buttons["back-to-today"], archiveRevealName)
        app.buttons["back-to-today"].tap()
        waitForDestination("archived Today for Saturday 10 October 2026") {
            app.staticTexts["today-title"].exists && app.staticTexts["today-title"].label == "Saturday 10 October 2026"
        }
        XCTAssertEqual(app.staticTexts["today-title"].label, "Saturday 10 October 2026")
        try XCTUnwrap(visibleTabs(in: app)).buttons["tab-ask"].tap()
        XCTAssertTrue(app.buttons["ask-question-entry"].waitForExistence(timeout: 5))
        openHistory(app)
        scrollTo(app.buttons["history-daily-2026-10-10"], in: app)
        app.buttons["history-daily-2026-10-10"].tap()
        try XCTUnwrap(visibleTabs(in: app)).buttons["tab-today"].tap()
        XCTAssertEqual(app.staticTexts["today-title"].label, "Sunday 11 October")
        XCTAssertFalse(app.buttons["back-to-history"].exists)
        app.terminate()

        let reduced = self.app(extra: ["--test-history-days", "2", "--test-reduce-motion"], animations: true)
        openHistory(reduced)
        scrollTo(reduced.buttons["history-daily-2026-10-10"], in: reduced)
        reduced.buttons["history-daily-2026-10-10"].tap()
        reduced.buttons["today-card"].tap()
        XCTAssertEqual(reduced.buttons["back-to-today"].label, "Back to daily card")
        XCTAssertEqual(activeScrollView(in: reduced).staticTexts["card-name"].label, "Strength")
        XCTAssertEqual(reduced.descendants(matching: .any)["revealed-card"].value as? String, "settled")
        capture(reduced, "03-reveal--history-reduce-motion")
        reduced.buttons["back-to-today"].tap()
        XCTAssertEqual(reduced.staticTexts["today-title"].label, "Saturday 10 October 2026")
    }

    func testHistoryAppearsImmediatelyAndSnapshotsSurviveRelaunch() throws {
        let app = app(extra: ["--test-store-id", UUID().uuidString] + fixedSpread, memory: false, audit: true)
        openHistory(app)
        XCTAssertEqual(app.staticTexts["history-message"].label, "Your story starts here")
        app.buttons["tab-today"].tap()
        reveal(app)
        let name = app.staticTexts["card-name"].label
        let details = app.staticTexts["card-details"].label
        app.buttons["see-meaning"].tap()
        let interpretation = app.staticTexts["core-interpretation"].label
        openHistory(app)
        let daily = app.buttons["history-daily-2026-10-11"]
        scrollTo(daily, in: app)
        daily.tap()
        XCTAssertEqual(app.staticTexts["card-name"].label, name)
        XCTAssertEqual(app.staticTexts["card-details"].label, details)
        XCTAssertEqual(app.staticTexts["core-interpretation"].label, interpretation)
        assertTodayContent(app)
        XCTAssertTrue(try XCTUnwrap(visibleTabs(in: app)).buttons["tab-history"].isSelected)
        try auditAndCapture(app, "04-today--history", today: true, expecting: app.buttons["back-to-history"], app.buttons["today-card"])
        positionTodayAuditBelowCard(app, revealing: app.staticTexts["line-social"])
        try auditAndCapture(app, "04-today--history-bottom", today: true, expecting: app.staticTexts["line-social"])
        XCTAssertFalse(app.buttons["today-ask"].exists)
        XCTAssertFalse(app.staticTexts["next-card-arrival"].exists)
        scrollTo(app.buttons["back-to-history"], in: app)
        app.buttons["back-to-history"].tap()
        waitForDestination("History") {
            app.staticTexts["history-title"].exists
        }
        app.buttons["tab-ask"].tap()
        app.buttons["ask-question-entry"].tap()
        app.buttons["suggestion-0"].tap()
        app.buttons["submit-question"].tap()
        chooseSpread(app)
        app.buttons["read-spread"].tap()
        var saved: [String: String] = [:]
        for id in ["reading-question", "reading-situation", "reading-action", "reading-outcome", "reading-lens", "reflection-question"] {
            saved[id] = app.staticTexts[id].label
        }
        app.buttons["reading-done"].tap()
        openHistory(app)
        scrollTo(app.buttons["history-filter-relationship"], in: app)
        app.buttons["history-filter-relationship"].tap()
        let reading = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'history-reading-'")).firstMatch
        scrollTo(reading, in: app)
        let readingID = reading.identifier
        reading.tap()
        XCTAssertNil(visibleTabs(in: app), "Archived readings keep the resting tabs hidden")
        try auditAndCapture(app, "09-reading--history", expecting: app.staticTexts["reading-question"])
        for (id, value) in saved { XCTAssertEqual(app.staticTexts[id].label, value) }
        scrollTo(app.staticTexts["Something to sit with"], in: app, abovePinnedFooter: true)
        dragContent(app, up: true, abovePinnedFooter: true)
        assertVisible(app.staticTexts["reflection-question"], in: app, abovePinnedFooter: true)
        assertVisible(app.staticTexts["Something to sit with"], in: app, abovePinnedFooter: true)
        assertVisible(app.buttons["reading-done"], in: app)
        capture(app, "09-reading--history-bottom")
        app.buttons["reading-done"].tap()
        waitForDestination("History with Relationship selected") {
            app.buttons["history-filter-relationship"].exists && app.buttons["history-filter-relationship"].isSelected
        }
        XCTAssertTrue(app.buttons["history-filter-relationship"].isSelected)
        app.terminate()
        app.launchArguments += ["--test-revised-content"]
        let dateIndex = app.launchArguments.firstIndex(of: "--test-date")!
        app.launchArguments[dateIndex + 1] = "2026-10-12T00:00:00Z"
        app.launch()
        reveal(app)
        XCTAssertTrue(app.staticTexts["card-name"].label.hasPrefix("Revised "))
        app.buttons["see-meaning"].tap()
        openHistory(app)
        for _ in 0..<3 {
            if app.buttons["history-daily-2026-10-11"].exists { break }
            activeScrollView(in: app).swipeUp(velocity: .slow)
        }
        scrollTo(app.buttons["history-daily-2026-10-11"], in: app)
        app.buttons["history-daily-2026-10-11"].tap()
        XCTAssertEqual(app.staticTexts["today-title"].label, "Sunday 11 October 2026")
        XCTAssertEqual(app.staticTexts["card-name"].label, name)
        XCTAssertEqual(app.staticTexts["core-interpretation"].label, interpretation)
        assertTodayContent(app)
        app.buttons["back-to-history"].tap()
        scrollTo(app.buttons[readingID], in: app)
        app.buttons[readingID].tap()
        for (id, value) in saved { XCTAssertEqual(app.staticTexts[id].label, value) }
        app.buttons["reading-done"].tap()
        XCTAssertTrue(app.staticTexts["history-title"].exists)
        XCTAssertTrue(app.buttons["history-daily-2026-10-11"].exists)
    }

    func testHistoryRefreshesAfterReadingEditAndUserDeletion() {
        let app = app(extra: ["--test-history-days", "1"])
        openHistory(app)
        let reading = app.buttons["history-reading-00000000-0000-0000-0000-000000000001"]
        scrollTo(reading, in: app)
        reading.tap()
        scrollTo(app.buttons["reading-response-somewhat"], in: app)
        app.buttons["reading-response-somewhat"].tap()
        XCTAssertTrue(app.buttons["reading-response-somewhat"].isSelected)
        app.buttons["reading-done"].tap()
        scrollTo(reading, in: app)
        reading.tap()
        XCTAssertTrue(app.buttons["reading-response-somewhat"].isSelected)
        scrollTo(app.buttons["reading-more"], in: app)
        app.buttons["reading-more"].tap()
        app.buttons["reading-delete"].tap()
        let confirmation = app.alerts["Delete this reading?"]
        XCTAssertTrue(confirmation.waitForExistence(timeout: 5))
        confirmation.buttons["Delete"].tap()
        XCTAssertTrue(app.staticTexts["history-title"].waitForExistence(timeout: 5))
        XCTAssertFalse(reading.exists, "Deleting an archived reading must update the open History list")
        XCTAssertTrue(app.buttons["history-daily-2026-10-11"].exists)
    }

    func testHistoryEmptyErrorAndLargestTextEvidence() throws {
        let empty = app(audit: true)
        openHistory(empty)
        scrollTo(empty.staticTexts["history-message"], in: empty)
        try auditAndCapture(empty, "10-history--empty", expecting: empty.staticTexts["history-message"])
        scrollTo(empty.buttons["history-filter-career"], in: empty)
        empty.buttons["history-filter-career"].tap()
        waitForDestination("empty Career history") {
            empty.staticTexts["history-message"].label == "No career readings yet"
        }
        XCTAssertEqual(empty.staticTexts["history-message"].label, "No career readings yet")
        capture(empty, "10-history--empty-area")
        empty.terminate()
        let failure = app(extra: ["--test-history-read-failure"], audit: true)
        openHistory(failure)
        try auditAndCapture(failure, "10-history--read-error", expecting: failure.buttons["history-retry"])
        failure.buttons["history-retry"].tap()
        waitForDestination("History calendar after retry") {
            failure.staticTexts["history-month"].exists
        }
        XCTAssertTrue(failure.staticTexts["history-month"].waitForExistence(timeout: 5))
        failure.terminate()
        let emptyLarge = app(extra: ["--test-largest-text", "--test-history-read-failure"])
        openHistory(emptyLarge)
        capture(emptyLarge, "10-history--read-error-largest-text")
        scrollTo(emptyLarge.buttons["history-retry"], in: emptyLarge)
        capture(emptyLarge, "10-history--read-error-largest-text-bottom")
        emptyLarge.buttons["history-retry"].tap()
        scrollTo(emptyLarge.staticTexts["history-message"], in: emptyLarge)
        capture(emptyLarge, "10-history--empty-largest-text")
        scrollTo(emptyLarge.staticTexts["history-message-body"], in: emptyLarge)
        capture(emptyLarge, "10-history--empty-largest-text-bottom")
        scrollTo(emptyLarge.buttons["history-filter-career"], in: emptyLarge)
        emptyLarge.buttons["history-filter-career"].tap()
        XCTAssertTrue(emptyLarge.buttons["history-filter-career"].isSelected)
        capture(emptyLarge, "10-history--empty-area-largest-text-filter")
        captureOverlappingContent(emptyLarge, through: emptyLarge.staticTexts["history-message"],
                                  named: "10-history--empty-area-largest-text-heading")
        XCTAssertEqual(emptyLarge.staticTexts["history-message"].label, "No career readings yet")
        capture(emptyLarge, "10-history--empty-area-largest-text")
        captureOverlappingContent(emptyLarge, through: emptyLarge.staticTexts["history-message-body"],
                                  named: "10-history--empty-area-largest-text-scroll")
        capture(emptyLarge, "10-history--empty-area-largest-text-bottom")
        emptyLarge.terminate()
        let large = app(extra: ["--test-history-days", "2", "--test-largest-text"], audit: true)
        openHistory(large)
        capture(large, "10-history--largest-text")
        let today = large.staticTexts["history-day-2026-10-11"]
        captureOverlappingContent(large, through: today, named: "10-history--largest-text-calendar-start")
        XCTAssertTrue(today.label.contains("Today, Card drawn"))
        capture(large, "10-history--largest-text-today")
        captureOverlappingContent(large, through: large.buttons["history-filter-all"],
                                  named: "10-history--largest-text-calendar-end")
        capture(large, "10-history--largest-text-filters")
        for area in ["all", "career", "relationship", "social"] {
            scrollTo(large.buttons["history-filter-\(area)"], in: large)
            XCTAssertGreaterThanOrEqual(large.buttons["history-filter-\(area)"].frame.height + 0.000_001, 44)
            capture(large, "10-history--largest-text-filter-\(area)")
        }
        let reading = large.buttons["history-reading-00000000-0000-0000-0000-000000000001"]
        captureOverlappingContent(large, through: reading, named: "10-history--largest-text-list-start")
        capture(large, "10-history--largest-text-first-entry")
        let relationship = large.buttons["history-reading-00000000-0000-0000-0000-000000000002"]
        captureOverlappingContent(large, through: relationship, named: "10-history--largest-text-list")
        capture(large, "10-history--largest-text-relationship-entry")
        let oldest = large.buttons["history-reading-00000000-0000-0000-0000-000000000003"]
        captureOverlappingContent(large, through: oldest, named: "10-history--largest-text-list-end")
        // The 608-point row fits, but not together with the bottom padding.
        // Keep its complete bounds and the absolute scroll end as separate stops.
        assertVisible(oldest, in: large)
        capture(large, "10-history--largest-text-last-entry")
        dragContent(large, up: true)
        assertVisible(large.staticTexts["history-entry-detail-reading-00000000-0000-0000-0000-000000000003"], in: large)
        capture(large, "10-history--largest-text-bottom")
        scrollTo(large.buttons["history-filter-social"], in: large)
        large.buttons["history-filter-social"].tap()
        XCTAssertTrue(large.buttons["history-filter-social"].isSelected)
        capture(large, "10-history--filtered-largest-text")
        captureOverlappingContent(large, through: oldest, named: "10-history--filtered-largest-text-scroll")
        XCTAssertEqual(large.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'history-daily-'")).count, 0)
        XCTAssertEqual(large.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'history-reading-'")).count, 1)
        capture(large, "10-history--filtered-largest-text-result")
        scrollTo(large.buttons["history-filter-all"], in: large)
        large.buttons["history-filter-all"].tap()
        let daily = large.buttons["history-daily-2026-10-10"]
        scrollTo(daily, in: large)
        daily.tap()
        XCTAssertEqual(large.staticTexts["today-title"].label, "Saturday 10 October 2026")
        XCTAssertEqual(large.staticTexts["card-name"].label, "Strength")
        XCTAssertTrue(try XCTUnwrap(visibleTabs(in: large)).buttons["tab-history"].isSelected)
        capture(large, "04-today--history-largest-text")
        captureOverlappingContent(large, through: large.staticTexts["line-social"],
                                  named: "04-today--history-largest-text-scroll")
        dragContent(large, up: true)
        assertVisible(large.staticTexts["line-social"], in: large)
        capture(large, "04-today--history-largest-text-bottom")
        scrollTo(large.buttons["today-card"], in: large)
        large.buttons["today-card"].tap()
        XCTAssertEqual(large.buttons["back-to-today"].label, "Back to daily card")
        XCTAssertNil(visibleTabs(in: large))
        capture(large, "03-reveal--history-largest-text")
        captureOverlappingContent(large, through: large.staticTexts["reveal-disclaimer"],
                                  named: "03-reveal--history-largest-text-scroll")
        assertVisible(large.buttons["see-meaning"], in: large)
        capture(large, "03-reveal--history-largest-text-bottom")
        scrollTo(large.buttons["back-to-today"], in: large)
        large.buttons["back-to-today"].tap()
        XCTAssertEqual(large.staticTexts["today-title"].label, "Saturday 10 October 2026")
        XCTAssertEqual(large.staticTexts["card-name"].label, "Strength")
        try XCTUnwrap(visibleTabs(in: large)).buttons["tab-history"].tap()
        XCTAssertTrue(large.buttons["history-filter-all"].isSelected)
        // This return only needs to open the row; its complete bounds were captured above.
        for _ in 0..<40 {
            if reading.isHittable { break }
            let viewport = scrollViewport(in: large)
            let frame = reading.frame
            let settlingDistance = min(24, 12 + max(0, viewport.height - frame.height) / 2)
            let delta = frame.maxY > viewport.maxY
                ? min(viewport.height / 2, frame.maxY - viewport.maxY + settlingDistance)
                : -min(viewport.height / 2, viewport.minY - frame.minY + settlingDistance)
            let origin = large.coordinate(withNormalizedOffset: .zero)
            let start = origin.withOffset(CGVector(dx: viewport.midX, dy: viewport.midY + delta / 2))
            let end = origin.withOffset(CGVector(dx: viewport.midX, dy: viewport.midY - delta / 2))
            start.press(forDuration: 0.1, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.2)
        }
        XCTAssertTrue(reading.isHittable)
        reading.tap()
        XCTAssertNil(visibleTabs(in: large))
        capture(large, "09-reading--history-largest-text")
        captureOverlappingContent(large, through: large.staticTexts["reading-disclaimer"],
                                  named: "09-reading--history-largest-text-scroll")
        scrollTo(large.staticTexts["reading-disclaimer"], in: large)
        assertVisible(large.buttons["reading-done"], in: large)
        capture(large, "09-reading--history-largest-text-bottom")
        large.buttons["reading-done"].tap()
        XCTAssertTrue(large.staticTexts["history-title"].exists)
    }

    func testHistoryYearOfEntriesScrollPerformance() throws {
        let app = app(extra: ["--test-history-days", "365"])
        openHistory(app)
        scrollTo(app.buttons["history-filter-all"], in: app)
        let rows = app.buttons.matching(NSPredicate(format:
            "identifier BEGINSWITH 'history-daily-' OR identifier BEGINSWITH 'history-reading-'"))
        XCTAssertEqual(rows.count, 368)
        let options = XCTMeasureOptions()
        options.iterationCount = 2
        var metrics: [any XCTMetric] = [XCTOSSignpostMetric.scrollingAndDecelerationMetric]
        #if compiler(>=6.2)
        if #available(iOS 26.0, *) { metrics.append(XCTHitchMetric(application: app)) }
        #endif
        measure(metrics: metrics, options: options) {
            for _ in 0..<5 { app.swipeUp(velocity: .fast) }
        }
        XCTAssertTrue(app.buttons["tab-history"].isHittable)
        let visible = app.buttons[try captureHistoryYear(app, "10-history--year-scroll")]
        XCTAssertTrue(visible.isHittable)
        visible.tap()
        XCTAssertTrue(app.buttons["back-to-history"].waitForExistence(timeout: 5))
        _ = try captureHistoryYear(app, "04-today--history-year-entry", requiring: "back-to-history")
        app.buttons["back-to-history"].tap()
        XCTAssertTrue(app.buttons["tab-history"].isHittable)
        XCTAssertTrue(visible.isHittable)
    }

    private func captureHistoryYear(_ app: XCUIApplication, _ name: String,
                                    requiring requiredIdentifier: String? = nil) throws -> String {
        let viewport = visibleFrame(in: app)
        var previous: [String: CGRect]?
        var visibleTarget: String?
        // Read the retained tree once per sample. Resolving every off-screen element
        // individually is slow even while an archive detail covers the 365-day list.
        let settled = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            guard let snapshot = try? app.snapshot() else { return false }
            var frames: [String: CGRect] = [:]
            visibleTarget = nil
            func collect(_ node: any XCUIElementSnapshot) {
                if !node.identifier.isEmpty, !node.frame.isEmpty, node.frame.intersects(viewport) {
                    frames[node.identifier] = node.frame
                    let matchesTarget = requiredIdentifier.map { node.identifier == $0 }
                        ?? node.identifier.hasPrefix("history-daily-")
                    if visibleTarget == nil, node.elementType == .button,
                       matchesTarget, viewport.contains(node.frame) {
                        visibleTarget = node.identifier
                    }
                }
                for child in node.children { collect(child) }
            }
            collect(snapshot)
            let unchanged = previous == frames
            previous = frames
            return !frames.isEmpty && visibleTarget != nil && unchanged
        }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [settled], timeout: 15), .completed, "Visible History frames must settle")
        let identifier = try XCTUnwrap(visibleTarget)
        Thread.sleep(forTimeInterval: 0.3)
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
        return identifier
    }

    private let fixedSpread = ["--test-random-indices", "0,0,0,1,0,0"]

    private func enterPerson(_ app: XCUIApplication, note: String = "") {
        let name = app.textFields["person-name"]
        scrollTo(app.staticTexts["Their name or a nickname"], in: app)
        scrollTo(name, in: app)
        name.tap()
        name.typeText("Sam\n")
        scrollTo(app.buttons["person-relation-friend"], in: app)
        app.buttons["person-relation-friend"].tap()
        if !note.isEmpty {
            let field = app.textViews["person-note"]
            scrollTo(app.staticTexts["Anything specific? (optional)"], in: app)
            scrollTo(field, in: app)
            field.tap()
            field.typeText(note)
            app.buttons["note-keyboard-done"].tap()
        }
    }

    func testNamedPersonFormDraftPickAndSavedReadingEvidence() throws {
        let app = app(extra: fixedSpread + ["--test-store-id", UUID().uuidString], memory: false, audit: true)
        reachAsk(app)
        for area in ["career", "social"] {
            app.buttons["area-\(area)"].tap()
            XCTAssertFalse(app.buttons["ask-person-entry"].exists)
        }
        app.buttons["area-relationship"].tap()
        scrollTo(app.buttons["ask-person-entry"], in: app)
        try auditAndCapture(app, "05-ask--named-person-entry", expecting: app.buttons["ask-person-entry"])
        scrollTo(app.buttons["ask-person-entry"], in: app)
        app.buttons["ask-person-entry"].tap()
        waitForDestination("Ask about someone form") {
            app.staticTexts["person-title"].exists
        }
        XCTAssertEqual(app.staticTexts["person-explanation"].label,
                       "No birth details needed for them. Just a name or nickname, so the reading can speak about them.")
        XCTAssertEqual(app.textFields.count, 1)
        XCTAssertEqual(app.textViews.count, 1)
        for relation in ["partner", "crush", "ex", "family", "friend", "colleague"] {
            XCTAssertFalse(app.buttons["person-relation-\(relation)"].isSelected)
        }
        XCTAssertFalse(app.buttons["submit-person"].isEnabled)
        XCTAssertEqual(app.buttons["submit-person"].label, "Add a name and who they are")
        try auditAndCapture(app, "07-about-someone", expecting: app.staticTexts["person-title"], app.buttons["submit-person"])
        scrollTo(app.textViews["person-note"], in: app)
        try auditAndCapture(app, "07-about-someone--bottom", expecting: app.textViews["person-note"])
        app.buttons["person-relation-friend"].tap()
        waitForDestination("Friend relationship selected") {
            app.buttons["person-relation-friend"].isSelected
        }
        XCTAssertEqual(app.buttons["submit-person"].label, "Add a name or nickname")
        enterPerson(app, note: "How can we make more time to talk?")
        XCTAssertTrue(app.buttons["submit-person"].isEnabled)
        XCTAssertEqual(app.buttons["submit-person"].label, "Draw for you and Sam")
        showNavigationTop(app)
        try auditAndCapture(app, "07-about-someone--filled", expecting: app.staticTexts["person-title"], app.buttons["submit-person"])
        XCUIDevice.shared.press(.home)
        app.activate()
        app.terminate()
        app.launch()
        XCTAssertTrue(app.staticTexts["today-title"].waitForExistence(timeout: 5))
        app.buttons["tab-ask"].tap()
        scrollTo(app.buttons["ask-person-entry"], in: app)
        app.buttons["ask-person-entry"].tap()
        XCTAssertEqual(app.textFields["person-name"].value as? String, "Sam")
        XCTAssertTrue(app.buttons["person-relation-friend"].isSelected)
        XCTAssertEqual(app.textViews["person-note"].value as? String, "How can we make more time to talk?")
        app.buttons["submit-person"].tap()
        XCTAssertEqual(app.staticTexts["spread-question"].label, "“You and Sam”")
        XCTAssertEqual(app.staticTexts["pick-prompt"].label, "Choose a card for you")
        try auditAndCapture(app, "08-three-card-pick--named-person-reduce-motion", expecting: app.staticTexts["pick-prompt"], app.buttons["draw-card-3"])
        for position in ["you", "them", "connection"] {
            XCTAssertTrue(app.descendants(matching: .any)["spread-slot-\(position)"].firstMatch.label.contains("empty"))
        }
        tapWhenSettled(app.buttons["draw-card-3"])
        waitForDestination("You card picked and Them prompt") {
            app.staticTexts["pick-prompt"].label == "Choose a card for them"
        }
        let first = app.descendants(matching: .any)["spread-slot-you"].firstMatch.label
        XCTAssertFalse(first.contains("empty"), "A card must be picked before checking draft restoration")
        XCTAssertEqual(app.staticTexts["pick-prompt"].label, "Choose a card for them")
        app.buttons["go-back"].tap()
        XCTAssertTrue(app.staticTexts["person-title"].exists)
        app.terminate()
        app.launch()
        app.buttons["tab-ask"].tap()
        XCTAssertTrue(app.staticTexts["person-title"].waitForExistence(timeout: 5))
        app.buttons["submit-person"].tap()
        XCTAssertEqual(app.descendants(matching: .any)["spread-slot-you"].firstMatch.label, first)
        for (position, subject) in [("them", "them"), ("connection", "the connection")] {
            XCTAssertEqual(app.staticTexts["pick-prompt"].label, "Choose a card for \(subject)")
            capture(app, "08-three-card-pick--named-person-prompt-\(position)-reduce-motion")
            tapWhenSettled(app.buttons["draw-card-3"])
        }
        try auditAndCapture(app, "08-three-card-pick-complete--named-person-reduce-motion", expecting: app.buttons["read-spread"])
        app.buttons["read-spread"].tap()
        waitForDestination("saved named-person reading") {
            app.staticTexts["reading-saved"].exists
        }
        XCTAssertTrue(app.staticTexts["reading-saved"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["reading-saved"].label, "Relationship · Saved to History")
        try auditAndCapture(app, "09-reading--named-person", expecting: app.staticTexts["reading-question"], app.buttons["reading-done"])
        var original: [String: String] = [:]
        for position in ["you", "them", "connection", "lens"] {
            let section = app.staticTexts["reading-\(position)"]
            scrollTo(section, in: app)
            original[position] = section.label
            XCTAssertFalse(section.label.isEmpty)
            try auditAndCapture(app, "09-reading--named-person-\(position)", expecting: section)
        }
        XCTAssertTrue(original["lens"]!.contains("Sam"))
        scrollTo(app.buttons["reading-response-notReally"], in: app)
        try auditAndCapture(app, "09-reading--named-person-bottom", expecting: app.buttons["reading-response-notReally"])
        app.terminate()
        app.launchArguments += ["--test-revised-content", "--test-open-saved-reading"]
        app.launch()
        XCTAssertTrue(app.staticTexts["reading-question"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["reading-question"].label, "“You and Sam”")
        for (position, text) in original { XCTAssertEqual(app.staticTexts["reading-\(position)"].label, text) }
        app.buttons["reading-done"].tap()
        app.buttons["tab-history"].tap()
        scrollTo(app.buttons["history-filter-relationship"], in: app)
        app.buttons["history-filter-relationship"].tap()
        let archived = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'history-reading-'")).firstMatch
        scrollTo(archived, in: app)
        XCTAssertTrue(archived.label.contains("You and Sam"))
        archived.tap()
        XCTAssertTrue(app.staticTexts["reading-question"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["reading-question"].label, "“You and Sam”")
        for (position, text) in original { XCTAssertEqual(app.staticTexts["reading-\(position)"].label, text) }
        app.buttons["reading-done"].tap()
        XCTAssertTrue(app.buttons["history-filter-relationship"].isSelected)
        app.buttons["tab-ask"].tap()
        scrollTo(app.buttons["latest-area-reading"], in: app)
        XCTAssertTrue(app.buttons["latest-area-reading"].label.contains("You and Sam"))
        scrollTo(app.buttons["ask-person-entry"], in: app)
        app.buttons["ask-person-entry"].tap()
        XCTAssertFalse(app.buttons["submit-person"].isEnabled)
    }

    func testNamedPersonDraftKeepsRelationshipWhenAreaIsHidden() {
        let app = app(extra: fixedSpread + ["--test-store-id", UUID().uuidString], memory: false, audit: true)
        reachAsk(app)
        scrollTo(app.buttons["ask-person-entry"], in: app)
        app.buttons["ask-person-entry"].tap()
        enterPerson(app)
        app.buttons["submit-person"].tap()
        tapWhenSettled(app.buttons["draw-card-3"])
        let first = app.descendants(matching: .any)["spread-slot-you"].firstMatch.label
        app.terminate()
        app.launch()
        XCTAssertTrue(app.buttons["open-settings"].waitForExistence(timeout: 5))
        app.buttons["open-settings"].tap()
        scrollTo(app.switches["visible-relationship"], in: app)
        app.switches["visible-relationship"].tap()
        XCTAssertEqual(app.switches["visible-relationship"].value as? String, "0")
        showNavigationTop(app)
        app.buttons["go-back"].tap()
        app.buttons["tab-ask"].tap()
        XCTAssertTrue(app.staticTexts["spread-question"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["spread-question"].label, "“You and Sam”")
        XCTAssertEqual(app.descendants(matching: .any)["spread-slot-you"].firstMatch.label, first)
        app.terminate()
        app.launch()
        app.buttons["tab-ask"].tap()
        XCTAssertTrue(app.staticTexts["spread-question"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.descendants(matching: .any)["spread-slot-you"].firstMatch.label, first)
        for _ in 0..<2 { tapWhenSettled(app.buttons["draw-card-3"]) }
        app.buttons["read-spread"].tap()
        XCTAssertTrue(app.staticTexts["reading-saved"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["reading-saved"].label, "Relationship · Saved to History")
        app.buttons["reading-done"].tap()
        app.buttons["tab-ask"].tap()
        XCTAssertTrue(app.buttons["area-career"].isSelected)
        XCTAssertFalse(app.buttons["area-relationship"].exists)
        XCTAssertFalse(app.buttons["ask-person-entry"].exists)
        app.buttons["tab-today"].tap()
        app.buttons["open-settings"].tap()
        scrollTo(app.switches["visible-relationship"], in: app)
        app.switches["visible-relationship"].tap()
        showNavigationTop(app)
        app.buttons["go-back"].tap()
        app.buttons["tab-ask"].tap()
        app.buttons["area-relationship"].tap()
        scrollTo(app.buttons["latest-area-reading"], in: app)
        XCTAssertTrue(app.buttons["latest-area-reading"].label.contains("You and Sam"))
    }

    func testNamedPersonCrisisNoteClearsDraftAndBackDiscardsDetails() {
        let app = app(extra: fixedSpread + ["--test-store-id", UUID().uuidString, "--test-crisis-discard-failure"], memory: false, audit: true)
        reachAsk(app)
        scrollTo(app.buttons["ask-person-entry"], in: app)
        app.buttons["ask-person-entry"].tap()
        enterPerson(app, note: "I want to kill myself")
        app.buttons["submit-person"].tap()
        XCTAssertTrue(app.staticTexts["support-title"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["draw-card-3"].exists)
        XCTAssertFalse(app.buttons["support-today"].isEnabled)
        app.terminate()
        app.launchArguments.removeAll { $0 == "--test-crisis-discard-failure" }
        app.launch()
        XCTAssertTrue(app.staticTexts["support-title"].waitForExistence(timeout: 5))
        app.buttons["support-today"].tap()
        app.buttons["tab-ask"].tap()
        XCTAssertFalse(app.buttons["latest-area-reading"].exists)
        scrollTo(app.buttons["ask-person-entry"], in: app)
        app.buttons["ask-person-entry"].tap()
        XCTAssertFalse(app.buttons["submit-person"].isEnabled)
        XCTAssertEqual(app.textViews["person-note"].value as? String, "")
        enterPerson(app)
        app.buttons["submit-person"].tap()
        app.buttons["draw-card-3"].tap()
        XCTAssertEqual(app.descendants(matching: .any)["spread-slot-you"].firstMatch.label, "You, The Star, Upright")
        app.buttons["go-back"].tap()
        app.buttons["go-back"].tap()
        scrollTo(app.buttons["ask-person-entry"], in: app)
        app.buttons["ask-person-entry"].tap()
        XCTAssertFalse(app.buttons["submit-person"].isEnabled)
        XCTAssertFalse(app.buttons["person-relation-friend"].isSelected)
    }

    func testNamedPersonLargestTextAndKeyboardEvidence() {
        let app = app(extra: fixedSpread + ["--test-largest-text"], audit: true)
        reachAsk(app, largest: true)
        scrollTo(app.buttons["ask-person-entry"], in: app)
        capture(app, "05-ask--named-person-entry-largest-text")
        scrollTo(app.staticTexts["ask-person-explanation"], in: app)
        capture(app, "05-ask--named-person-explanation-largest-text")
        scrollTo(app.buttons["ask-person-entry"], in: app)
        app.buttons["ask-person-entry"].tap()
        capture(app, "07-about-someone--largest-text")
        scrollTo(app.staticTexts["person-explanation"], in: app)
        capture(app, "07-about-someone--largest-text-explanation")
        scrollTo(app.staticTexts["Their name or a nickname"], in: app)
        scrollTo(app.textFields["person-name"], in: app)
        capture(app, "07-about-someone--largest-text-name")
        for relation in ["partner", "crush", "ex", "family", "friend", "colleague"] {
            scrollTo(app.buttons["person-relation-\(relation)"], in: app)
            capture(app, "07-about-someone--largest-text-\(relation)")
        }
        scrollTo(app.staticTexts["Anything specific? (optional)"], in: app)
        scrollTo(app.textViews["person-note"], in: app)
        capture(app, "07-about-someone--largest-text-note")
        scrollTo(app.buttons["submit-person"], in: app)
        capture(app, "07-about-someone--largest-text-bottom")
        let name = app.textFields["person-name"]
        scrollTo(app.staticTexts["Their name or a nickname"], in: app)
        scrollTo(name, in: app)
        name.tap()
        name.typeText("Sam")
        capture(app, "07-about-someone--largest-text-name-keyboard")
        name.typeText("\n")
        scrollTo(app.buttons["submit-person"], in: app)
        XCTAssertFalse(app.buttons["submit-person"].isEnabled)
        XCTAssertEqual(app.buttons["submit-person"].label, "Choose who they are to you")
        scrollTo(app.buttons["person-relation-friend"], in: app)
        app.buttons["person-relation-friend"].tap()
        let note = app.textViews["person-note"]
        scrollTo(app.staticTexts["Anything specific? (optional)"], in: app)
        scrollTo(note, in: app)
        note.tap()
        note.typeText("Time to talk.")
        capture(app, "07-about-someone--largest-text-note-keyboard")
        app.buttons["note-keyboard-done"].tap()
        scrollTo(app.buttons["submit-person"], in: app)
        assertVisible(app.buttons["submit-person"], in: app)
        capture(app, "07-about-someone--largest-text-filled-bottom")
        app.buttons["submit-person"].tap()
        capture(app, "08-three-card-pick--named-person-largest-text")
        for position in ["you", "them", "connection"] {
            scrollTo(app.descendants(matching: .any)["spread-slot-\(position)"].firstMatch, in: app)
            capture(app, "08-three-card-pick--named-person-largest-text-\(position)")
        }
        for (position, subject) in [("you", "you"), ("them", "them"), ("connection", "the connection")] {
            let prompt = app.staticTexts["pick-prompt"]
            scrollTo(prompt, in: app)
            XCTAssertEqual(prompt.label, "Choose a card for \(subject)")
            capture(app, "08-three-card-pick--named-person-largest-text-prompt-\(position)")
            scrollTo(app.buttons["draw-card-3"], in: app)
            tapWhenSettled(app.buttons["draw-card-3"])
        }
        showNavigationTop(app)
        capture(app, "08-three-card-pick-complete--named-person-largest-text")
        for position in ["you", "them", "connection"] {
            scrollTo(app.descendants(matching: .any)["spread-slot-\(position)"].firstMatch, in: app)
            capture(app, "08-three-card-pick-complete--named-person-largest-text-\(position)")
        }
        scrollTo(app.buttons["read-spread"], in: app)
        capture(app, "08-three-card-pick-complete--named-person-largest-text-bottom")
        app.buttons["read-spread"].tap()
        capture(app, "09-reading--named-person-largest-text")
        for index in 0..<20 {
            if app.buttons["reading-done"].isHittable { break }
            dragContent(app, up: true)
            capture(app, "09-reading--named-person-largest-text-scroll-\(index)")
        }
        scrollTo(app.staticTexts["reading-disclaimer"], in: app)
        assertVisible(app.buttons["reading-done"], in: app)
        capture(app, "09-reading--named-person-largest-text-bottom")
        app.buttons["reading-done"].tap()
        XCTAssertTrue(app.buttons["tab-today"].exists)
    }

    private func reachAsk(_ app: XCUIApplication, largest: Bool = false) {
        XCTAssertFalse(app.buttons["tab-ask"].exists)
        if largest {
            scrollTo(app.buttons["draw-card-3"], in: app)
            tapWhenSettled(app.buttons["draw-card-3"])
            scrollTo(app.buttons["turn-over"], in: app)
            app.buttons["turn-over"].tap()
            scrollTo(app.buttons["see-meaning"], in: app)
        } else { reveal(app) }
        XCTAssertFalse(app.buttons["tab-ask"].exists)
        app.buttons["see-meaning"].tap()
        scrollTo(app.buttons["today-ask"], in: app)
        XCTAssertTrue(app.buttons["tab-today"].exists)
        XCTAssertTrue(app.buttons["tab-ask"].exists)
        app.buttons["today-ask"].tap()
        XCTAssertTrue(app.staticTexts["ask-title"].waitForExistence(timeout: 5))
    }

    private func chooseSpread(_ app: XCUIApplication, largest: Bool = false) {
        for (index, position) in ["situation", "action", "outcome"].enumerated() {
            if largest { scrollTo(app.buttons["draw-card-3"], in: app) }
            XCTAssertTrue(app.buttons["draw-card-3"].isHittable)
            tapWhenSettled(app.buttons["draw-card-3"])
            let slot = app.descendants(matching: .any)["spread-slot-\(position)"].firstMatch
            XCTAssertFalse(slot.label.contains("empty"))
            if index < 2 { XCTAssertFalse(app.buttons["read-spread"].exists) }
        }
        XCTAssertFalse(app.buttons["draw-card-3"].exists)
        if largest { scrollTo(app.buttons["read-spread"], in: app) }
    }

    func testComposerLimitAreaChangeAndDraftRestoresAfterBackgroundAndRelaunch() throws {
        let app = app(extra: ["--test-store-id", UUID().uuidString], memory: false, audit: true)
        reachAsk(app)
        scrollTo(app.buttons["ask-question-entry"], in: app)
        app.buttons["ask-question-entry"].tap()
        let field = app.descendants(matching: .any)["question-field"].firstMatch
        field.tap()
        let question = String(repeating: "a", count: 300)
        field.typeText(question + "b")
        XCTAssertEqual(field.value as? String, question)
        field.typeText(XCUIKeyboardKey.delete.rawValue)
        XCTAssertEqual(field.value as? String, String(question.dropLast()))
        XCTAssertEqual(app.staticTexts["question-count"].label, "299 of 300 characters")
        field.typeText("a")
        XCTAssertEqual(field.value as? String, question)
        XCTAssertEqual(app.staticTexts["question-count"].label, "300 of 300 characters, limit reached")
        app.keyboards.buttons["Done"].tap()
        XCTAssertEqual(app.staticTexts["question-count"].label, "300 of 300 characters, limit reached")
        scrollTo(app.staticTexts["question-count"], in: app)
        try auditAndCapture(app, "06-composer-question-entered--limit", expecting: app.staticTexts["question-count"])
        showNavigationTop(app)
        let oldSuggestion = app.buttons["suggestion-0"].label
        app.buttons["area-career"].tap()
        waitForDestination("Career composer suggestions") {
            app.buttons["suggestion-0"].label != oldSuggestion
        }
        XCTAssertNotEqual(app.buttons["suggestion-0"].label, oldSuggestion)
        XCTAssertEqual(field.value as? String, question)
        XCUIDevice.shared.press(.home)
        app.activate()
        XCTAssertEqual(field.value as? String, question)
        app.terminate()
        app.launch()
        XCTAssertTrue(app.buttons["tab-ask"].waitForExistence(timeout: 5))
        app.buttons["tab-ask"].tap()
        XCTAssertTrue(app.buttons["area-career"].isSelected)
        scrollTo(app.buttons["ask-question-entry"], in: app)
        app.buttons["ask-question-entry"].tap()
        XCTAssertEqual(field.value as? String, question)
        showNavigationTop(app)
        app.buttons["go-back"].tap()
        app.terminate()
        app.launch()
        app.buttons["tab-ask"].tap()
        scrollTo(app.buttons["ask-question-entry"], in: app)
        app.buttons["ask-question-entry"].tap()
        XCTAssertEqual(app.staticTexts["question-count"].label, "0 of 300 characters")
    }

    func testAskContextStatusAndLatestSavedReading() throws {
        let app = app(extra: fixedSpread + ["--test-store-id", UUID().uuidString], memory: false, audit: true)
        reachAsk(app)
        let expected = ["career": ("Share an idea you have been quietly tending.", "Career, 72 out of 100"),
                        "relationship": ("Let a kind word make room for connection.", "Relationship, 81 out of 100"),
                        "social": ("Notice who gives you space to be yourself.", "Social, 64 out of 100")]
        for area in ["career", "social", "relationship"] {
            app.buttons["area-\(area)"].tap()
            XCTAssertEqual(app.staticTexts["ask-area-line"].label, expected[area]!.0)
            XCTAssertEqual(app.staticTexts["ask-area-score"].label, expected[area]!.1)
            XCTAssertFalse(app.buttons["latest-area-reading"].exists)
        }
        scrollTo(app.buttons["relationship-status-single"], in: app)
        for status in ["single", "inRelationship", "complicated", "preferNotToSay"] {
            let choice = app.buttons["relationship-status-\(status)"]
            XCTAssertGreaterThanOrEqual(choice.frame.height, 44)
            XCTAssertGreaterThanOrEqual(choice.frame.width, 44)
        }
        app.buttons["relationship-status-single"].tap()
        XCTAssertFalse(app.staticTexts["relationship-prompt"].exists)
        scrollTo(app.buttons["suggestion-0"], in: app)
        app.buttons["suggestion-0"].tap()
        app.buttons["submit-question"].tap()
        chooseSpread(app)
        app.buttons["read-spread"].tap()
        let identifiers = ["reading-question", "reading-situation", "reading-action", "reading-outcome", "reading-lens", "reflection-question"]
        let firstQuestion = app.staticTexts["reading-question"].label
        XCTAssertTrue(app.staticTexts["reading-lens"].label.contains("while single"))
        app.terminate()
        let dateArgument = app.launchArguments.firstIndex(of: "--test-date")!
        app.launchArguments[dateArgument + 1] = "2026-10-11T01:00:00Z"
        app.launch()
        app.buttons["tab-ask"].tap()
        XCTAssertFalse(app.staticTexts["relationship-prompt"].exists)
        scrollTo(app.buttons["suggestion-1"], in: app)
        app.buttons["suggestion-1"].tap()
        app.buttons["submit-question"].tap()
        chooseSpread(app)
        app.buttons["read-spread"].tap()
        XCTAssertNotEqual(app.staticTexts["reading-question"].label, firstQuestion)
        XCTAssertTrue(app.staticTexts["reading-lens"].label.contains("while single"))
        let original = identifiers.map { app.staticTexts[$0].label }
        app.terminate()
        app.launchArguments.append("--test-revised-content")
        app.launch()
        app.buttons["tab-ask"].tap()
        XCTAssertFalse(app.staticTexts["relationship-prompt"].exists)
        scrollTo(app.buttons["latest-area-reading"], in: app)
        XCTAssertGreaterThanOrEqual(app.buttons["latest-area-reading"].frame.height, 44)
        XCTAssertGreaterThanOrEqual(app.buttons["latest-area-reading"].frame.width, 44)
        try auditAndCapture(app, "05-ask--recent-reading", expecting: app.buttons["latest-area-reading"])
        app.buttons["latest-area-reading"].tap()
        waitForDestination("latest saved reading") {
            app.staticTexts["reading-question"].exists
        }
        XCTAssertEqual(identifiers.map { app.staticTexts[$0].label }, original)
        app.buttons["reading-done"].tap()
        app.buttons["tab-ask"].tap()
        app.buttons["area-social"].tap()
        XCTAssertFalse(app.buttons["latest-area-reading"].exists)
        scrollTo(app.buttons["ask-question-entry"], in: app)
        app.buttons["ask-question-entry"].tap()
        XCTAssertEqual(app.staticTexts["question-count"].label, "0 of 300 characters")
        app.terminate()
        app.launchArguments.append("--test-largest-text")
        app.launch()
        app.buttons["tab-ask"].tap()
        app.buttons["area-relationship"].tap()
        scrollTo(app.buttons["latest-area-reading"], in: app)
        capture(app, "05-ask--largest-text-recent-reading")
        app.buttons["latest-area-reading"].tap()
        XCTAssertEqual(app.staticTexts["reading-question"].label, original[0])
    }

    func testSkippedRelationshipStatusIsRememberedWithoutChoosingAStatus() {
        let app = app(extra: ["--test-store-id", UUID().uuidString], memory: false)
        reachAsk(app)
        scrollTo(app.buttons["skip-relationship-status"], in: app)
        app.buttons["skip-relationship-status"].tap()
        XCTAssertFalse(app.staticTexts["relationship-prompt"].exists)
        app.terminate()
        app.launch()
        app.buttons["tab-ask"].tap()
        XCTAssertFalse(app.staticTexts["relationship-prompt"].exists)
        scrollTo(app.buttons["suggestion-0"], in: app)
        app.buttons["suggestion-0"].tap()
        app.buttons["submit-question"].tap()
        chooseSpread(app)
        app.buttons["read-spread"].tap()
        XCTAssertTrue(app.staticTexts["reading-lens"].label.contains("Whether you are exploring a connection"))
    }

    func testAskSuggestionsComposerPickReadingAndDesignEvidence() throws {
        let app = app(extra: fixedSpread, audit: true)
        reachAsk(app)
        var suggestions = Set<String>()
        for area in ["career", "social", "relationship"] {
            let button = app.buttons["area-\(area)"]
            XCTAssertTrue(button.isHittable)
            button.tap()
            for index in 0..<3 {
                let suggestion = app.buttons["suggestion-\(index)"]
                XCTAssertTrue(suggestion.label.hasSuffix("?"))
                XCTAssertTrue(suggestions.insert(suggestion.label).inserted)
            }
        }
        XCTAssertFalse(app.buttons["latest-area-reading"].exists)
        try auditAndCapture(app, "05-ask", expecting: app.staticTexts["ask-title"], app.staticTexts["ask-area-line"])
        scrollTo(app.buttons["suggestion-2"], in: app)
        try auditAndCapture(app, "05-ask--suggestions", expecting: app.buttons["suggestion-2"])
        scrollTo(app.buttons["skip-relationship-status"], in: app)
        try auditAndCapture(app, "05-ask--bottom", expecting: app.buttons["skip-relationship-status"])
        app.buttons["skip-relationship-status"].tap()
        waitForDestination("Ask with relationship prompt dismissed") {
            app.staticTexts["ask-title"].exists && !app.staticTexts["relationship-prompt"].exists
        }
        XCTAssertFalse(app.staticTexts["relationship-prompt"].exists)
        XCTAssertFalse(app.buttons["latest-area-reading"].exists)
        scrollTo(app.staticTexts["ask-title"], in: app)
        capture(app, "05-ask--status-skipped-no-reading")
        scrollTo(app.buttons["suggestion-2"], in: app)
        capture(app, "05-ask--status-skipped-no-reading-bottom")
        app.buttons["tab-today"].tap()
        waitForDestination("Today tab") {
            app.staticTexts["today-title"].exists
        }
        XCTAssertTrue(app.staticTexts["today-title"].waitForExistence(timeout: 5))
        app.buttons["tab-ask"].tap()
        scrollTo(app.buttons["ask-question-entry"], in: app)
        app.buttons["ask-question-entry"].tap()
        XCTAssertFalse(app.buttons["tab-ask"].exists)
        XCTAssertFalse(app.buttons["submit-question"].isEnabled)
        XCTAssertEqual(app.buttons["submit-question"].label, "Write or pick a question")
        XCTAssertEqual(app.staticTexts["question-count"].label, "0 of 300 characters")
        for position in ["situation", "action", "outcome"] {
            XCTAssertEqual(app.descendants(matching: .any)["composer-preview-\(position)"].firstMatch.label, "\(position.capitalized), empty")
        }
        try auditAndCapture(app, "06-composer", expecting: app.descendants(matching: .any)["question-field"].firstMatch, app.buttons["submit-question"])
        let finalSuggestion = app.buttons["suggestion-2"]
        scrollTo(finalSuggestion, in: app, abovePinnedFooter: true)
        // Reach the content's bottom so the chip has space above the pinned footer.
        dragContent(app, up: true, abovePinnedFooter: true)
        waitForSettled([finalSuggestion])
        assertVisible(finalSuggestion, in: app, abovePinnedFooter: true)
        XCTAssertGreaterThanOrEqual(scrollViewport(in: app).maxY - finalSuggestion.frame.maxY, 8,
                                    "The complete final chip needs a clear gap above the pinned footer")
        try auditAndCapture(app, "06-composer--bottom", expecting: finalSuggestion)
        scrollTo(app.buttons["suggestion-0"], in: app)
        app.buttons["suggestion-0"].tap()
        waitForDestination("composer filled with What matters to me here?") {
            app.descendants(matching: .any)["question-field"].firstMatch.value as? String == "What matters to me here?"
        }
        XCTAssertTrue(app.buttons["submit-question"].isEnabled)
        XCTAssertEqual(app.descendants(matching: .any)["question-field"].firstMatch.value as? String, "What matters to me here?")
        showNavigationTop(app)
        try auditAndCapture(app, "06-composer-question-entered", expecting: app.staticTexts["composer-title"], app.buttons["submit-question"])
        scrollTo(app.buttons["suggestion-2"], in: app)
        try auditAndCapture(app, "06-composer-question-entered--bottom", expecting: app.buttons["suggestion-2"])
        app.buttons["submit-question"].tap()
        waitForDestination("three-card pick") {
            app.staticTexts["spread-question"].exists
        }
        XCTAssertEqual(app.staticTexts["spread-question"].label, "“What matters to me here?”")
        XCTAssertFalse(app.buttons["tab-ask"].exists)
        for position in ["situation", "action", "outcome"] {
            XCTAssertTrue(app.descendants(matching: .any)["spread-slot-\(position)"].firstMatch.label.contains("empty"))
        }
        try auditAndCapture(app, "08-three-card-pick", expecting: app.staticTexts["spread-question"], app.buttons["draw-card-3"])
        app.buttons["draw-card-3"].tap()
        waitForDestination("Situation card picked") {
            app.descendants(matching: .any)["spread-slot-situation"].firstMatch.label == "Situation, The Star, Upright"
        }
        try auditAndCapture(app, "08-three-card-pick--one-picked", expecting: app.staticTexts["pick-prompt"], app.buttons["spread-shuffle"])
        app.buttons["draw-card-1"].tap()
        waitForDestination("Action card picked") {
            app.descendants(matching: .any)["spread-slot-action"].firstMatch.label == "Action, The Sun, Reversed"
        }
        try auditAndCapture(app, "08-three-card-pick--two-picked", expecting: app.staticTexts["pick-prompt"], app.buttons["spread-shuffle"])
        app.buttons["draw-card-5"].tap()
        waitForDestination("Outcome card picked") {
            app.descendants(matching: .any)["spread-slot-outcome"].firstMatch.label == "Outcome, The Fool, Upright"
        }
        XCTAssertEqual(app.descendants(matching: .any)["spread-slot-situation"].firstMatch.label, "Situation, The Star, Upright")
        XCTAssertEqual(app.descendants(matching: .any)["spread-slot-action"].firstMatch.label, "Action, The Sun, Reversed")
        XCTAssertEqual(app.descendants(matching: .any)["spread-slot-outcome"].firstMatch.label, "Outcome, The Fool, Upright")
        try auditAndCapture(app, "08-three-card-pick-complete", expecting: app.staticTexts["spread-complete-title"], app.buttons["read-spread"])
        app.buttons["read-spread"].tap()
        waitForDestination("saved question reading") {
            app.staticTexts["reading-saved"].exists
        }
        XCTAssertTrue(app.staticTexts["reading-saved"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["reading-saved"].label, "Relationship · Saved to History")
        XCTAssertFalse(app.buttons["tab-ask"].exists)
        try auditAndCapture(app, "09-reading", expecting: app.staticTexts["reading-saved"], app.staticTexts["reading-situation"], app.buttons["reading-done"])
        for identifier in ["reading-situation", "reading-action", "reading-outcome", "reading-lens"] {
            XCTAssertFalse(app.staticTexts[identifier].label.isEmpty)
        }
        scrollTo(app.staticTexts["reading-action"], in: app)
        try auditAndCapture(app, "09-reading--action", expecting: app.staticTexts["reading-action"])
        scrollTo(app.staticTexts["reading-outcome"], in: app)
        try auditAndCapture(app, "09-reading--outcome", expecting: app.staticTexts["reading-outcome"])
        let reflectionCaption = app.staticTexts["Something to sit with"]
        scrollTo(reflectionCaption, in: app)
        assertVisible(app.staticTexts["reflection-question"], in: app, abovePinnedFooter: true)
        XCTAssertTrue(app.staticTexts["reflection-question"].label.hasSuffix("?"))
        try auditAndCapture(app, "09-reading--bottom", expecting: app.staticTexts["reflection-question"], reflectionCaption, app.buttons["reading-done"])
        scrollTo(app.buttons["reading-response-notReally"], in: app)
        try auditAndCapture(app, "09-reading--response", expecting: app.staticTexts["reading-response-prompt"], app.buttons["reading-response-yes"])
        app.buttons["reading-done"].tap()
        waitForDestination("Today") {
            app.staticTexts["today-title"].exists
        }
        XCTAssertTrue(app.staticTexts["today-title"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["tab-today"].exists)
    }

    func testTypedQuestionWhitespaceAndSavedReadingSurvivesRelaunch() throws {
        let app = app(extra: fixedSpread + ["--test-store-id", UUID().uuidString], memory: false)
        reachAsk(app)
        app.buttons["area-career"].tap()
        scrollTo(app.buttons["ask-question-entry"], in: app)
        app.buttons["ask-question-entry"].tap()
        let field = app.descendants(matching: .any)["question-field"].firstMatch
        field.tap()
        field.typeText("   ")
        XCTAssertFalse(app.buttons["submit-question"].isEnabled)
        field.typeText("How can I make room to learn?")
        XCTAssertTrue(app.buttons["submit-question"].isEnabled)
        app.keyboards.buttons["Done"].tap()
        XCTAssertTrue(app.keyboards.firstMatch.waitForNonExistence(timeout: 5))
        app.buttons["submit-question"].tap()
        chooseSpread(app)
        app.buttons["read-spread"].tap()
        XCTAssertEqual(app.staticTexts["reading-question"].label, "“How can I make room to learn?”")
        let identifiers = ["reading-question", "reading-saved", "reading-situation", "reading-action", "reading-outcome", "reading-lens", "reflection-question"]
        let original = identifiers.map { app.staticTexts[$0].label }
        XCTAssertTrue(app.staticTexts["reading-lens"].label.contains("your work"))
        app.terminate()
        let random = app.launchArguments.firstIndex(of: "--test-random-indices")!
        app.launchArguments[random + 1] = "5,1,4,0,3,1"
        app.launchArguments += ["--test-open-saved-reading", "--test-revised-content"]
        app.launch()
        XCTAssertTrue(app.staticTexts["reading-saved"].waitForExistence(timeout: 5))
        XCTAssertEqual(identifiers.map { app.staticTexts[$0].label }, original)
        app.buttons["close-reading"].tap()
        XCTAssertTrue(app.staticTexts["today-title"].waitForExistence(timeout: 5))
    }

    private func openReadingNote(_ app: XCUIApplication) {
        scrollTo(app.buttons["reading-more"], in: app)
        app.buttons["reading-more"].tap()
        waitForDestination("reading actions menu before note editing") {
            app.buttons["reading-edit-note"].exists
        }
        app.buttons["reading-edit-note"].tap()
        XCTAssertTrue(app.staticTexts["note-title"].waitForExistence(timeout: 5))
    }

    private func finishNoteEditing(_ app: XCUIApplication) {
        app.buttons["note-keyboard-done"].tap()
        XCTAssertTrue(app.keyboards.firstMatch.waitForNonExistence(timeout: 5))
    }

    private func captureNoteKeyboard(_ app: XCUIApplication, largest: Bool = false) {
        let field = app.textViews["note-field"]
        let dismiss = app.buttons["note-keyboard-done"]
        let save = app.buttons["note-save"]
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 5))
        scrollTo(field, in: app)
        waitForSettled([field, dismiss])
        func noteViewport() -> CGRect {
            let viewport = scrollViewport(in: app)
            let bottom = min(viewport.maxY, dismiss.frame.minY - 8)
            return CGRect(x: viewport.minX, y: viewport.minY, width: viewport.width,
                          height: max(0, bottom - viewport.minY))
        }
        func recordGeometry(_ phase: String) {
            let geometry = "\(phase): field=\(field.frame), save=\(save.frame), done=\(dismiss.frame), " +
                "viewport=\(noteViewport()), gap=\(dismiss.frame.minY - save.frame.maxY)"
            let attachment = XCTAttachment(string: geometry)
            attachment.name = "note-keyboard-geometry-\(largest ? "largest" : "ordinary")-\(phase)"
            attachment.lifetime = .keepAlways
            add(attachment)
            print("Note keyboard geometry \(geometry)")
        }
        assertVisible(field, in: app)
        assertVisible(dismiss, in: app)
        XCTAssertTrue(noteViewport().contains(field.frame))
        XCTAssertLessThanOrEqual(field.frame.maxY + 8, dismiss.frame.minY)
        recordGeometry("before-scroll")
        if largest { capture(app, "09-reading--note-keyboard-largest-text") }
        if largest {
            // Keep both ends in the unoccluded outer gutter, above Done and the keyboard.
            let viewport = noteViewport()
            let origin = app.coordinate(withNormalizedOffset: .zero)
            let start = origin.withOffset(CGVector(dx: viewport.minX + 8, dy: viewport.maxY - 24))
            let end = origin.withOffset(CGVector(dx: viewport.minX + 8, dy: viewport.minY + 24))
            start.press(forDuration: 0.05, thenDragTo: end)
        } else {
            scrollTo(save, in: app)
        }
        waitForSettled([save, dismiss])
        recordGeometry("after-scroll")
        capture(app, largest ? "09-reading--note-keyboard-largest-text-bottom" : "09-reading--note-keyboard")
        assertVisible(save, in: app)
        if largest { XCTAssertTrue(noteViewport().contains(save.frame)) }
        XCTAssertLessThanOrEqual(save.frame.maxY + 8, dismiss.frame.minY)
    }

    private func makeQuestionReading(_ app: XCUIApplication, largest: Bool = false) {
        scrollTo(app.buttons["suggestion-0"], in: app)
        app.buttons["suggestion-0"].tap()
        scrollTo(app.buttons["submit-question"], in: app)
        app.buttons["submit-question"].tap()
        chooseSpread(app, largest: largest)
        app.buttons["read-spread"].tap()
        XCTAssertTrue(app.staticTexts["reading-saved"].waitForExistence(timeout: 5))
    }

    func testReadingResponseNoteAndConfirmedDeletionPersist() throws {
        let app = app(extra: fixedSpread + ["--test-store-id", UUID().uuidString], memory: false, audit: true)
        reachAsk(app)
        makeQuestionReading(app)
        let originalQuestion = app.staticTexts["reading-question"].label
        let textIDs = ["reading-question", "reading-situation", "reading-action", "reading-outcome", "reading-lens", "reflection-question"]
        let originalText = textIDs.map { app.staticTexts[$0].label }
        XCTAssertFalse(app.buttons["reading-delete"].exists)
        for response in ["yes", "notReally", "notReally", "somewhat"] {
            let button = app.buttons["reading-response-" + response]
            scrollTo(button, in: app)
            button.tap()
        }
        XCTAssertTrue(app.buttons["reading-response-somewhat"].isSelected)
        XCTAssertFalse(app.buttons["reading-response-yes"].isSelected)
        try auditAndCapture(app, "09-reading--response-selected", expecting: app.buttons["reading-response-somewhat"])
        scrollTo(app.buttons["reading-more"], in: app)
        app.buttons["reading-more"].tap()
        waitForDestination("reading actions menu") {
            app.buttons["reading-edit-note"].exists && app.buttons["reading-delete"].exists
        }
        waitForSettled([app.buttons["reading-edit-note"], app.buttons["reading-delete"]])
        XCTAssertTrue(app.buttons["reading-edit-note"].exists && app.buttons["reading-edit-note"].isHittable)
        XCTAssertTrue(app.buttons["reading-delete"].exists && app.buttons["reading-delete"].isHittable)
        capture(app, "09-reading--more")
        // Native menus cover the app's scroll view; audit the reading after dismissal.
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.05, dy: 0.5)).tap()
        XCTAssertTrue(app.buttons["reading-delete"].waitForNonExistence(timeout: 5))
        try auditAndCapture(app, "09-reading--menu-dismissed", expecting: app.buttons["reading-more"], app.staticTexts["reading-question"])
        scrollTo(app.buttons["reading-more"], in: app)
        app.buttons["reading-more"].tap()
        waitForDestination("reading actions menu") {
            app.buttons["reading-edit-note"].exists
        }
        app.buttons["reading-edit-note"].tap()
        try auditAndCapture(app, "09-reading--note-editor", expecting: app.staticTexts["note-title"], app.buttons["note-save"])
        let field = app.textViews["note-field"]
        XCTAssertTrue((field.value as? String ?? "").isEmpty)
        field.tap()
        waitForDestination("note editor keyboard focus") {
            app.keyboards.firstMatch.exists && app.buttons["note-keyboard-done"].exists
        }
        field.typeText("I can take a small step.\nThere is time.")
        captureNoteKeyboard(app)
        finishNoteEditing(app)
        app.buttons["note-save"].tap()
        scrollTo(app.staticTexts["reading-note"], in: app)
        XCTAssertEqual(app.staticTexts["reading-note"].label, "I can take a small step.\nThere is time.")
        try auditAndCapture(app, "09-reading--note-saved", expecting: app.staticTexts["reading-note"])
        openReadingNote(app)
        // Tap below this short note to append; TextView.tap() targets its first character.
        field.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
        field.typeText(" Today.")
        finishNoteEditing(app)
        app.buttons["note-save"].tap()
        openReadingNote(app)
        field.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
        field.typeText(" Unsaved.")
        finishNoteEditing(app)
        app.buttons["note-cancel"].tap()
        app.buttons["reading-done"].tap()
        app.buttons["tab-ask"].tap()
        scrollTo(app.buttons["latest-area-reading"], in: app)
        app.buttons["latest-area-reading"].tap()
        XCTAssertEqual(textIDs.map { app.staticTexts[$0].label }, originalText)
        scrollTo(app.staticTexts["reading-note"], in: app)
        XCTAssertEqual(app.staticTexts["reading-note"].label, "I can take a small step.\nThere is time. Today.")
        XCTAssertTrue(app.buttons["reading-response-somewhat"].isSelected)
        app.terminate()
        app.launchArguments += ["--test-open-saved-reading", "--test-revised-content"]
        app.launch()
        XCTAssertTrue(app.staticTexts["reading-saved"].waitForExistence(timeout: 5))
        XCTAssertEqual(textIDs.map { app.staticTexts[$0].label }, originalText)
        scrollTo(app.staticTexts["reading-note"], in: app)
        XCTAssertEqual(app.staticTexts["reading-note"].label, "I can take a small step.\nThere is time. Today.")
        XCTAssertTrue(app.buttons["reading-response-somewhat"].isSelected)
        // Keep a second reading to prove deletion removes only the selected one.
        app.buttons["reading-done"].tap()
        app.buttons["tab-ask"].tap()
        app.buttons["area-career"].tap()
        makeQuestionReading(app)
        XCTAssertNotEqual(app.staticTexts["reading-question"].label, originalQuestion)
        app.buttons["reading-more"].tap()
        app.buttons["reading-delete"].tap()
        let confirmation = app.alerts["Delete this reading?"]
        XCTAssertTrue(confirmation.waitForExistence(timeout: 5))
        waitForSettled([confirmation.buttons["Cancel"], confirmation.buttons["Delete"]])
        XCTAssertTrue(confirmation.buttons["Cancel"].exists && confirmation.buttons["Cancel"].isHittable)
        XCTAssertTrue(confirmation.buttons["Delete"].exists && confirmation.buttons["Delete"].isHittable)
        capture(app, "09-reading--delete-confirmation")
        // Audit the app after the native alert stops covering its scroll view.
        confirmation.buttons["Cancel"].tap()
        XCTAssertTrue(confirmation.waitForNonExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["reading-saved"].exists)
        try auditAndCapture(app, "09-reading--delete-cancelled", expecting: app.staticTexts["reading-question"], app.buttons["reading-more"])
        scrollTo(app.buttons["reading-more"], in: app)
        app.buttons["reading-more"].tap()
        waitForDestination("reading actions menu") {
            app.buttons["reading-delete"].exists
        }
        app.buttons["reading-delete"].tap()
        confirmation.buttons["Delete"].tap()
        XCTAssertTrue(app.staticTexts["today-title"].waitForExistence(timeout: 5))
        app.buttons["tab-ask"].tap()
        XCTAssertTrue(app.buttons["area-career"].isSelected)
        XCTAssertFalse(app.buttons["latest-area-reading"].exists)
        app.buttons["area-relationship"].tap()
        scrollTo(app.buttons["latest-area-reading"], in: app)
        XCTAssertTrue(app.buttons["latest-area-reading"].exists)
        app.terminate()
        app.launch()
        XCTAssertTrue(app.staticTexts["reading-saved"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["reading-question"].label, originalQuestion)
        openReadingNote(app)
        field.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
        let note = field.value as! String
        field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: note.count))
        finishNoteEditing(app)
        app.buttons["note-save"].tap()
        XCTAssertFalse(app.staticTexts["reading-note"].exists)
        scrollTo(app.buttons["reading-response-somewhat"], in: app)
        app.buttons["reading-response-somewhat"].tap()
        XCTAssertFalse(app.buttons["reading-response-somewhat"].isSelected)
        app.terminate()
        app.launch()
        XCTAssertTrue(app.staticTexts["reading-saved"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["reading-note"].exists)
        XCTAssertFalse(app.buttons["reading-response-somewhat"].isSelected)
        app.buttons["reading-more"].tap()
        app.buttons["reading-delete"].tap()
        confirmation.buttons["Delete"].tap()
        XCTAssertTrue(app.staticTexts["today-title"].waitForExistence(timeout: 5))
        app.buttons["tab-ask"].tap()
        XCTAssertFalse(app.buttons["latest-area-reading"].exists)
        capture(app, "05-ask--reading-deleted")
        scrollTo(app.buttons["skip-relationship-status"], in: app)
        assertVisible(app.buttons["skip-relationship-status"], in: app)
        XCTAssertFalse(app.buttons["latest-area-reading"].exists)
        capture(app, "05-ask--reading-deleted-bottom")
        app.terminate()
        app.launch()
        XCTAssertTrue(app.staticTexts["today-title"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["reading-saved"].exists)
        app.buttons["tab-ask"].tap()
        XCTAssertTrue(app.staticTexts["ask-title"].exists)
        XCTAssertFalse(app.buttons["latest-area-reading"].exists)
        app.buttons["area-career"].tap()
        XCTAssertFalse(app.buttons["latest-area-reading"].exists)
    }

    func testReadingChangesRecoverFromFailedSaveAndDelete() throws {
        for largest in [false, true] {
            let app = app(extra: fixedSpread + ["--test-store-id", UUID().uuidString,
                          "--test-reading-update-failure", "--test-reading-delete-failure"] + (largest ? ["--test-largest-text"] : []), memory: false)
            reachAsk(app, largest: largest)
            makeQuestionReading(app, largest: largest)
            openReadingNote(app)
            let field = app.textViews["note-field"]
            scrollTo(field, in: app)
            field.tap()
            field.typeText("Keep this thought.")
            finishNoteEditing(app)
            scrollTo(app.buttons["note-save"], in: app)
            app.buttons["note-save"].tap()
            XCTAssertTrue(app.alerts["Your change could not be saved"].waitForExistence(timeout: 5))
            capture(app, largest ? "09-reading--note-save-failure-largest-text" : "09-reading--note-save-failure")
            app.alerts.buttons["OK"].tap()
            XCTAssertEqual(field.value as? String, "Keep this thought.")
            scrollTo(app.buttons["note-save"], in: app)
            app.buttons["note-save"].tap()
            app.buttons["reading-more"].tap()
            app.buttons["reading-delete"].tap()
            app.alerts.buttons["Delete"].tap()
            XCTAssertTrue(app.alerts["Your change could not be saved"].waitForExistence(timeout: 5))
            capture(app, largest ? "09-reading--delete-failure-largest-text" : "09-reading--delete-failure")
            app.alerts.buttons["OK"].tap()
            XCTAssertTrue(app.staticTexts["reading-saved"].exists)
            app.terminate()
            app.launchArguments.removeAll { $0 == "--test-reading-update-failure" || $0 == "--test-reading-delete-failure" }
            app.launchArguments.append("--test-open-saved-reading")
            app.launch()
            XCTAssertTrue(app.staticTexts["reading-saved"].waitForExistence(timeout: 5))
            scrollTo(app.staticTexts["reading-note"], in: app)
            XCTAssertEqual(app.staticTexts["reading-note"].label, "Keep this thought.")
            scrollTo(app.buttons["reading-more"], in: app)
            app.buttons["reading-more"].tap()
            app.buttons["reading-delete"].tap()
            app.alerts.buttons["Delete"].tap()
            XCTAssertTrue(app.staticTexts["today-title"].waitForExistence(timeout: 5))
            app.terminate()
        }
    }

    func testReadingNoteAndConfirmationAtLargestText() throws {
        let app = app(extra: fixedSpread + ["--test-largest-text"], audit: true)
        reachAsk(app, largest: true)
        makeQuestionReading(app, largest: true)
        scrollTo(app.buttons["reading-response-somewhat"], in: app)
        app.buttons["reading-response-somewhat"].tap()
        capture(app, "09-reading--response-largest-text")
        openReadingNote(app)
        capture(app, "09-reading--note-editor-largest-text")
        let field = app.textViews["note-field"]
        XCTAssertTrue((field.value as? String ?? "").isEmpty)
        scrollTo(field, in: app)
        field.tap()
        field.typeText("One step at a time.")
        captureNoteKeyboard(app, largest: true)
        finishNoteEditing(app)
        scrollTo(app.buttons["note-save"], in: app)
        assertVisible(app.buttons["note-save"], in: app)
        capture(app, "09-reading--note-editor-largest-text-bottom")
        app.buttons["note-save"].tap()
        scrollTo(app.staticTexts["reading-note"], in: app)
        capture(app, "09-reading--note-saved-largest-text")
        scrollTo(app.buttons["reading-done"], in: app)
        assertVisible(app.buttons["reading-done"], in: app)
        scrollTo(app.buttons["reading-more"], in: app)
        app.buttons["reading-more"].tap()
        capture(app, "09-reading--more-largest-text")
        app.buttons["reading-delete"].tap()
        XCTAssertTrue(app.alerts["Delete this reading?"].waitForExistence(timeout: 5))
        capture(app, "09-reading--delete-confirmation-largest-text")
        app.alerts.buttons["Cancel"].tap()
        XCTAssertTrue(app.alerts.firstMatch.waitForNonExistence(timeout: 5))
        capture(app, "09-reading--delete-cancelled-largest-text")
        scrollTo(app.buttons["reading-more"], in: app)
        app.buttons["reading-more"].tap()
        app.buttons["reading-delete"].tap()
        app.alerts.buttons["Delete"].tap()
        XCTAssertTrue(app.staticTexts["today-title"].waitForExistence(timeout: 5))
        app.buttons["tab-ask"].tap()
        XCTAssertFalse(app.buttons["latest-area-reading"].exists)
        capture(app, "05-ask--reading-deleted-largest-text")
        scrollTo(app.buttons["skip-relationship-status"], in: app)
        assertVisible(app.buttons["skip-relationship-status"], in: app)
        XCTAssertFalse(app.buttons["latest-area-reading"].exists)
        capture(app, "05-ask--reading-deleted-largest-text-bottom")
    }

    func testAskSuggestedQuestionOpensComposerAndSocialLens() {
        let app = app(extra: fixedSpread)
        reachAsk(app)
        app.buttons["area-social"].tap()
        let question = app.buttons["suggestion-0"].label
        scrollTo(app.buttons["suggestion-0"], in: app)
        app.buttons["suggestion-0"].tap()
        XCTAssertEqual(app.descendants(matching: .any)["question-field"].firstMatch.value as? String, question)
        XCTAssertTrue(app.buttons["submit-question"].isEnabled)
        app.buttons["submit-question"].tap()
        chooseSpread(app)
        app.buttons["read-spread"].tap()
        XCTAssertEqual(app.staticTexts["reading-saved"].label, "Social · Saved to History")
        XCTAssertTrue(app.staticTexts["reading-lens"].label.contains("belonging"))
    }

    func testAskLargestTextAndPickReduceMotionEvidence() throws {
        let app = app(extra: fixedSpread + ["--test-largest-text", "--test-reduce-motion"])
        reachAsk(app, largest: true)
        scrollTo(app.staticTexts["ask-title"], in: app)
        capture(app, "05-ask--largest-text")
        scrollTo(app.buttons["suggestion-2"], in: app)
        capture(app, "05-ask--largest-text-suggestions")
        scrollTo(app.staticTexts["ask-area-line"], in: app)
        capture(app, "05-ask--largest-text-context")
        scrollTo(app.buttons["ask-question-entry"], in: app)
        let introduction = app.staticTexts["Or start from one of these"]
        scrollTo(introduction, in: app)
        assertVisible(app.buttons["ask-question-entry"], in: app)
        assertVisible(introduction, in: app)
        capture(app, "05-ask--largest-text-entry")
        scrollTo(app.staticTexts["relationship-prompt"], in: app)
        capture(app, "05-ask--largest-text-status")
        for status in ["single", "inRelationship", "complicated", "preferNotToSay"] {
            scrollTo(app.buttons["relationship-status-\(status)"], in: app)
            capture(app, "05-ask--largest-text-status-\(status)")
        }
        scrollTo(app.buttons["skip-relationship-status"], in: app)
        capture(app, "05-ask--largest-text-bottom")
        app.buttons["skip-relationship-status"].tap()
        XCTAssertFalse(app.staticTexts["relationship-prompt"].exists)
        XCTAssertFalse(app.buttons["latest-area-reading"].exists)
        scrollTo(app.staticTexts["ask-title"], in: app)
        capture(app, "05-ask--status-skipped-no-reading-largest-text")
        scrollTo(app.buttons["suggestion-2"], in: app)
        capture(app, "05-ask--status-skipped-no-reading-largest-text-bottom")
        scrollTo(app.buttons["ask-question-entry"], in: app)
        scrollTo(app.buttons["ask-question-entry"], in: app)
        app.buttons["ask-question-entry"].tap()
        showNavigationTop(app)
        capture(app, "06-composer--largest-text")
        scrollTo(app.staticTexts["Open questions work best. “What” and “how” more than “will”."], in: app)
        capture(app, "06-composer--largest-text-guidance")
        showQuestionField(app)
        capture(app, "06-composer--largest-text-field")
        scrollTo(app.buttons["suggestion-1"], in: app)
        capture(app, "06-composer--largest-text-suggestions")
        scrollTo(app.buttons["submit-question"], in: app)
        XCTAssertFalse(app.buttons["submit-question"].isEnabled)
        capture(app, "06-composer--largest-text-bottom")
        scrollTo(app.buttons["suggestion-0"], in: app)
        scrollTo(app.buttons["suggestion-0"], in: app)
        app.buttons["suggestion-0"].tap()
        showNavigationTop(app)
        capture(app, "06-composer-question-entered--largest-text")
        scrollTo(app.staticTexts["Open questions work best. “What” and “how” more than “will”."], in: app)
        capture(app, "06-composer-question-entered--largest-text-guidance")
        showQuestionField(app)
        capture(app, "06-composer-question-entered--largest-text-field")
        scrollTo(app.buttons["suggestion-1"], in: app)
        for index in 0..<3 { assertVisible(app.buttons["suggestion-\(index)"], in: app) }
        capture(app, "06-composer-question-entered--largest-text-suggestions")
        scrollTo(app.buttons["submit-question"], in: app)
        capture(app, "06-composer-question-entered--largest-text-bottom")
        app.buttons["submit-question"].tap()
        showNavigationTop(app)
        assertVisible(app.staticTexts["spread-progress"], in: app)
        assertVisible(app.staticTexts["spread-question"], in: app)
        capture(app, "08-three-card-pick--largest-text")
        for position in ["situation", "action", "outcome"] {
            scrollTo(app.descendants(matching: .any)["spread-slot-\(position)"].firstMatch, in: app)
            capture(app, "08-three-card-pick--largest-text-\(position)")
        }
        scrollTo(app.buttons["draw-card-3"], in: app)
        capture(app, "08-three-card-pick--largest-text-fan")
        scrollTo(app.staticTexts["spread-shuffle-helper"], in: app)
        assertVisible(app.buttons["spread-shuffle"], in: app)
        capture(app, "08-three-card-pick--largest-text-bottom")
        chooseSpread(app, largest: true)
        capture(app, "08-three-card-pick-complete--largest-text-bottom")
        showNavigationTop(app)
        assertVisible(app.staticTexts["spread-progress"], in: app)
        assertVisible(app.staticTexts["spread-question"], in: app)
        capture(app, "08-three-card-pick-complete--largest-text")
        for position in ["situation", "action", "outcome"] {
            scrollTo(app.descendants(matching: .any)["spread-slot-\(position)"].firstMatch, in: app)
            capture(app, "08-three-card-pick-complete--largest-text-\(position)")
        }
        scrollTo(app.buttons["read-spread"], in: app)
        app.buttons["read-spread"].tap()
        scrollTo(app.buttons["share-image"], in: app)
        assertVisible(app.buttons["share-image"], in: app)
        capture(app, "09-reading--largest-text-share")
        scrollTo(app.staticTexts["reading-question"], in: app)
        capture(app, "09-reading--largest-text")
        // Paragraphs can exceed the viewport; overlapping captures expose every line.
        for index in 0..<14 {
            if app.buttons["reading-done"].isHittable { break }
            dragContent(app, up: true)
            capture(app, "09-reading--largest-text-scroll-\(index)")
        }
        scrollTo(app.staticTexts["reading-disclaimer"], in: app)
        assertVisible(app.buttons["reading-done"], in: app)
        capture(app, "09-reading--largest-text-bottom")
        app.buttons["reading-done"].tap()
        XCTAssertTrue(app.buttons["tab-today"].exists)
        app.terminate()
        let reduced = self.app(extra: fixedSpread + ["--test-reduce-motion"])
        reachAsk(reduced)
        reduced.buttons["suggestion-0"].tap()
        reduced.buttons["submit-question"].tap()
        XCTAssertTrue(reduced.buttons["draw-card-3"].isHittable)
        capture(reduced, "08-three-card-pick--reduce-motion")
        chooseSpread(reduced)
        capture(reduced, "08-three-card-pick-complete--reduce-motion")
    }

    func testComposerKeyboardLayoutEvidence() {
        for largest in [false, true] {
            let app = app(extra: fixedSpread + ["--test-reduce-motion"] + (largest ? ["--test-largest-text"] : []))
            reachAsk(app, largest: largest)
            if largest { scrollTo(app.buttons["ask-question-entry"], in: app) }
            scrollTo(app.buttons["ask-question-entry"], in: app)
        app.buttons["ask-question-entry"].tap()
            let field = app.descendants(matching: .any)["question-field"].firstMatch
            if largest { showQuestionField(app) }
            field.tap()
            XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 5))
            field.typeText("Where can I grow?")
            waitForSettled([field, app.keyboards.firstMatch])
            assertVisible(field, in: app)
            capture(app, largest ? "06-composer-question-entered--largest-text-keyboard" : "06-composer-question-entered--keyboard")
            XCTAssertTrue(app.keyboards.buttons["Done"].exists)
            app.keyboards.buttons["Done"].tap()
            XCTAssertTrue(app.keyboards.firstMatch.waitForNonExistence(timeout: 5))
            XCTAssertEqual(field.value as? String, "Where can I grow?")
            for index in 0..<3 { scrollTo(app.buttons["suggestion-\(index)"], in: app) }
            scrollTo(app.buttons["submit-question"], in: app)
            XCTAssertTrue(app.buttons["submit-question"].isEnabled)
            capture(app, largest ? "06-composer-question-entered--largest-text-keyboard-dismissed" : "06-composer-question-entered--keyboard-dismissed")
            app.buttons["submit-question"].tap()
            XCTAssertTrue(app.staticTexts["spread-question"].waitForExistence(timeout: 5))
            XCTAssertEqual(app.staticTexts["spread-question"].label, "“Where can I grow?”")
            app.terminate()
        }
    }

    func testSpreadShuffleNeverConsumesPickAndCanBeInterrupted() {
        for reduced in [false, true] {
            let app = app(extra: fixedSpread + ["--test-hold-shuffle"] + (reduced ? ["--test-reduce-motion"] : []), animations: true)
            reachAsk(app)
            app.buttons["suggestion-0"].tap()
            waitForDestination("composer opened from suggested question") {
                app.staticTexts["composer-title"].exists && app.buttons["submit-question"].isEnabled
            }
            app.buttons["submit-question"].tap()
            for (index, position) in ["situation", "action", "outcome"].enumerated() {
                XCTAssertEqual(app.staticTexts["spread-progress"].label, "Card \(index + 1) of 3")
                XCTAssertEqual(app.staticTexts["pick-prompt"].label, "Choose your \(position) card")
                XCTAssertEqual(app.staticTexts["spread-shuffle-helper"].label, "Shuffling never uses up a pick.")
                let previous = ["situation", "action", "outcome"].map {
                    app.descendants(matching: .any)["spread-slot-\($0)"].firstMatch.label
                }
                for _ in 0..<2 { app.buttons["spread-shuffle"].tap() }
                XCTAssertEqual(previous, ["situation", "action", "outcome"].map {
                    app.descendants(matching: .any)["spread-slot-\($0)"].firstMatch.label
                })
                for card in 1...5 { XCTAssertTrue(app.buttons["draw-card-\(card)"].isHittable) }
                let fan = app.descendants(matching: .any)["spread-fan"].firstMatch
                XCTAssertEqual(fan.value as? String, reduced ? "settled" : "animating")
                app.buttons["draw-card-\(index + 1)"].tap()
                XCTAssertFalse(app.buttons["spread-slot-\(position)"].exists)
                let filled = app.descendants(matching: .any)["spread-slot-\(position)"].firstMatch
                let locked = filled.label
                filled.tap()
                XCTAssertEqual(filled.label, locked)
                XCTAssertEqual(app.staticTexts["spread-progress"].label, index == 2 ? "All three drawn" : "Card \(index + 2) of 3")
            }
            XCTAssertEqual(app.descendants(matching: .any)["spread-slot-situation"].firstMatch.label, "Situation, The Star, Upright")
            XCTAssertEqual(app.descendants(matching: .any)["spread-slot-action"].firstMatch.label, "Action, The Sun, Reversed")
            XCTAssertEqual(app.descendants(matching: .any)["spread-slot-outcome"].firstMatch.label, "Outcome, The Fool, Upright")
            XCTAssertTrue(app.buttons["read-spread"].isHittable)
            XCTAssertFalse(app.buttons["spread-shuffle"].exists)
            app.terminate()
        }
    }

    func testSpreadShuffleSettlesEachRound() {
        let app = app(extra: fixedSpread, animations: true)
        reachAsk(app)
        app.buttons["suggestion-0"].tap()
        app.buttons["submit-question"].tap()
        for count in 1...3 {
            let fan = app.descendants(matching: .any)["spread-fan"].firstMatch
            let settled = XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == %@", "settled"), object: fan)
            XCTAssertEqual(XCTWaiter.wait(for: [settled], timeout: 10), .completed)
            XCTAssertEqual(app.staticTexts["spread-progress"].label, "Card \(count) of 3")
            if count == 1 { capture(app, "08-three-card-pick--shuffle-settled") }
            app.buttons["draw-card-3"].tap()
        }
        XCTAssertTrue(app.buttons["read-spread"].isHittable)
    }

    func testSpreadDraftSurvivesBackgroundRelaunchAndClearsAtReadingOrAsk() {
        let app = app(extra: fixedSpread + ["--test-store-id", UUID().uuidString], memory: false)
        reachAsk(app)
        app.buttons["suggestion-0"].tap()
        app.buttons["submit-question"].tap()
        for count in 0...3 {
            let slots = ["situation", "action", "outcome"].map {
                app.descendants(matching: .any)["spread-slot-\($0)"].firstMatch.label
            }
            XCUIDevice.shared.press(.home)
            app.activate()
            XCTAssertEqual(app.staticTexts["spread-question"].label, "“What matters to me here?”")
            app.terminate()
            app.launch()
            XCTAssertTrue(app.staticTexts["today-title"].waitForExistence(timeout: 5))
            app.buttons["tab-ask"].tap()
            XCTAssertEqual(app.staticTexts["spread-question"].label, "“What matters to me here?”")
            XCTAssertEqual(slots, ["situation", "action", "outcome"].map {
                app.descendants(matching: .any)["spread-slot-\($0)"].firstMatch.label
            })
            app.buttons["go-back"].tap()
            XCTAssertEqual(app.descendants(matching: .any)["question-field"].firstMatch.value as? String, "What matters to me here?")
            app.buttons["submit-question"].tap()
            XCTAssertEqual(slots, ["situation", "action", "outcome"].map {
                app.descendants(matching: .any)["spread-slot-\($0)"].firstMatch.label
            })
            if count < 3 { app.buttons["draw-card-3"].tap() }
        }
        app.buttons["read-spread"].tap()
        XCTAssertTrue(app.staticTexts["reading-saved"].waitForExistence(timeout: 5))
        app.terminate()
        app.launch()
        app.buttons["tab-ask"].tap()
        XCTAssertTrue(app.staticTexts["ask-title"].waitForExistence(timeout: 5))
        app.buttons["suggestion-0"].tap()
        app.buttons["submit-question"].tap()
        app.buttons["draw-card-3"].tap()
        app.buttons["go-back"].tap()
        app.buttons["go-back"].tap()
        XCTAssertTrue(app.staticTexts["ask-title"].exists)
        app.terminate()
        app.launch()
        app.buttons["tab-ask"].tap()
        XCTAssertTrue(app.staticTexts["ask-title"].waitForExistence(timeout: 5))
        app.buttons["suggestion-0"].tap()
        app.buttons["submit-question"].tap()
        XCTAssertEqual(app.staticTexts["spread-progress"].label, "Card 1 of 3")
    }

    func testSpreadDraftSaveFailureCanRetry() {
        let app = app(extra: fixedSpread + ["--test-spread-save-failure", "--test-reduce-motion"])
        reachAsk(app)
        app.buttons["suggestion-0"].tap()
        app.buttons["submit-question"].tap()
        XCTAssertTrue(app.alerts["Your draft could not be saved"].waitForExistence(timeout: 5))
        capture(app, "08-three-card-pick--draft-save-failure")
        app.alerts.buttons["Try again"].tap()
        XCTAssertTrue(app.alerts.firstMatch.waitForNonExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["spread-progress"].label, "Card 1 of 3")
        chooseSpread(app)
        app.buttons["read-spread"].tap()
        XCTAssertTrue(app.staticTexts["reading-saved"].waitForExistence(timeout: 5))
    }

    private func enterCrisisQuestion(_ app: XCUIApplication) {
        showQuestionField(app)
        let field = app.descendants(matching: .any)["question-field"].firstMatch
        field.tap()
        // The cursor can be before existing words; keep the synthetic phrase bounded.
        field.typeText(" I cannot keep myself safe. ")
        XCTAssertTrue((field.value as? String)?.contains("I cannot keep myself safe.") == true)
        app.keyboards.buttons["Done"].tap()
        XCTAssertTrue(app.keyboards.firstMatch.waitForNonExistence(timeout: 5))
        scrollTo(app.buttons["submit-question"], in: app)
        app.buttons["submit-question"].tap()
        XCTAssertTrue(app.staticTexts["support-title"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["draw-card-3"].exists)
        XCTAssertFalse(app.staticTexts["spread-question"].exists)
        XCTAssertFalse(app.staticTexts["reading-saved"].exists)
        XCTAssertFalse(app.buttons["tab-ask"].exists)
    }

    func testCrisisSupportClearsDraftWithoutDrawingOrSavingAndSurvivesRelaunch() throws {
        let app = app(extra: ["--test-random-indices", "0,0,1,1,2,1,3,1", "--test-store-id", UUID().uuidString], memory: false, audit: true)
        reachAsk(app)
        app.buttons["area-career"].tap()
        app.buttons["ask-question-entry"].tap()
        enterCrisisQuestion(app)
        try auditAndCapture(app, "12-support", expecting: app.staticTexts["support-title"], app.buttons["support-today"])
        for (identifier, expected) in [
            ("support-region", "Support in Australia"),
            ("support-emergency-contact", "Call 000"),
            ("support-lifeline-contact", "Call 13 11 14"),
            ("support-respect-contact", "Call 1800 737 732")
        ] {
            let element = app.staticTexts[identifier]
            scrollTo(element, in: app)
            assertVisible(element, in: app, abovePinnedFooter: true)
            XCTAssertEqual(element.label, expected)
        }
        scrollTo(app.staticTexts["support-outside-region"], in: app)
        try auditAndCapture(app, "12-support--bottom", expecting: app.staticTexts["support-outside-region"])
        app.buttons["support-today"].tap()
        waitForDestination("Today from support") {
            app.staticTexts["today-title"].exists
        }
        XCTAssertTrue(app.staticTexts["today-title"].waitForExistence(timeout: 5))
        app.buttons["tab-ask"].tap()
        XCTAssertFalse(app.buttons["latest-area-reading"].exists)
        app.buttons["ask-question-entry"].tap()
        XCTAssertEqual(app.staticTexts["question-count"].label, "0 of 300 characters")
        app.buttons["suggestion-0"].tap()
        app.buttons["submit-question"].tap()
        XCTAssertEqual(app.staticTexts["spread-progress"].label, "Card 1 of 3")
        app.buttons["draw-card-3"].tap()
        // The same process still uses the first random pair: the crisis path drew nothing.
        XCTAssertEqual(app.descendants(matching: .any)["spread-slot-situation"].firstMatch.label, "Situation, The Star, Upright")
        app.buttons["go-back"].tap()
        enterCrisisQuestion(app)
        // Relaunch directly from support before another composer can overwrite a stale draft.
        app.terminate()
        app.launchArguments.append("--test-open-saved-reading")
        app.launch()
        XCTAssertTrue(app.staticTexts["today-title"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["reading-saved"].exists)
        app.buttons["tab-ask"].tap()
        for area in ["career", "social", "relationship"] {
            app.buttons["area-\(area)"].tap()
            XCTAssertFalse(app.buttons["latest-area-reading"].exists)
        }
        app.buttons["ask-question-entry"].tap()
        XCTAssertEqual(app.staticTexts["question-count"].label, "0 of 300 characters")
    }

    func testCrisisAfterEditingPickedSpreadKeepsSupportDuringRemovalFailureAndRetriesOnRelaunch() throws {
        let app = app(extra: fixedSpread + ["--test-store-id", UUID().uuidString, "--test-crisis-discard-failure"], memory: false, audit: true)
        reachAsk(app)
        app.buttons["suggestion-0"].tap()
        app.buttons["submit-question"].tap()
        chooseSpread(app)
        app.buttons["go-back"].tap()
        enterCrisisQuestion(app)
        XCTAssertFalse(app.buttons["support-today"].isEnabled)
        scrollTo(app.buttons["support-retry-removal"], in: app)
        try auditAndCapture(app, "12-support--removal-failure", expecting: app.staticTexts["support-removal-failure"], app.buttons["support-retry-removal"])
        app.terminate()
        app.launchArguments.removeAll { $0 == "--test-crisis-discard-failure" }
        app.launch()
        XCTAssertTrue(app.staticTexts["support-title"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["support-removal-failure"].exists)
        app.buttons["support-today"].tap()
        app.terminate()
        app.launchArguments.append("--test-open-saved-reading")
        app.launch()
        XCTAssertTrue(app.staticTexts["today-title"].waitForExistence(timeout: 5))
        app.buttons["tab-ask"].tap()
        XCTAssertTrue(app.staticTexts["ask-title"].exists)
        XCTAssertFalse(app.buttons["latest-area-reading"].exists)
        app.buttons["ask-question-entry"].tap()
        XCTAssertEqual(app.staticTexts["question-count"].label, "0 of 300 characters")
        app.buttons["suggestion-0"].tap()
        app.buttons["submit-question"].tap()
        XCTAssertEqual(app.staticTexts["spread-progress"].label, "Card 1 of 3")
    }

    func testCrisisSupportLargestTextAndRemovalRetry() {
        let app = app(extra: ["--test-largest-text", "--test-crisis-discard-failure"], audit: true)
        reachAsk(app, largest: true)
        scrollTo(app.buttons["ask-question-entry"], in: app)
        app.buttons["ask-question-entry"].tap()
        enterCrisisQuestion(app)
        capture(app, "12-support--largest-text")
        for identifier in ["introduction", "region", "emergency-title", "emergency-contact", "emergency-detail",
                           "lifeline-title", "lifeline-contact", "lifeline-detail", "respect-title", "respect-contact",
                           "respect-detail", "outside-region", "removal-failure"] {
            let element = app.staticTexts["support-\(identifier)"]
            scrollTo(element, in: app)
            assertVisible(element, in: app)
            capture(app, "12-support--largest-text-\(identifier)")
        }
        scrollTo(app.buttons["support-retry-removal"], in: app)
        assertVisible(app.buttons["support-retry-removal"], in: app)
        capture(app, "12-support--largest-text-removal-retry")
        app.buttons["support-retry-removal"].tap()
        XCTAssertFalse(app.staticTexts["support-removal-failure"].exists)
        scrollTo(app.buttons["support-today"], in: app)
        assertVisible(app.buttons["support-today"], in: app)
        XCTAssertTrue(app.buttons["support-today"].isEnabled)
        capture(app, "12-support--largest-text-bottom")
        app.buttons["support-today"].tap()
        XCTAssertTrue(app.staticTexts["today-title"].waitForExistence(timeout: 5))
    }

}
