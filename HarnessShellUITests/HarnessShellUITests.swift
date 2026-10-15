import XCTest
import UIKit

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

    private func app(extra: [String] = [], memory: Bool = true, seed: String = "reference-1", date: String = "2026-10-11T00:00:00Z", animations: Bool = false, audit: Bool = false, welcome: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--test-mode", "--test-date", date,
                               "--test-time-zone", "Australia/Sydney", "--test-seed", seed]
        if memory { app.launchArguments.append("--test-memory-store") }
        if !animations { app.launchArguments.append("--test-disable-animations") }
        app.launchArguments += extra
        if audit { app.launchArguments.append("--test-reduce-motion") }
        if !welcome { app.launchArguments.append("--test-welcome-completed") }
        app.launch()
        return app
    }

    // Capture the requested stop, then audit overlapping stops until every deferred element is covered.
    private func auditAndCapture(_ app: XCUIApplication, _ name: String, today: Bool = false,
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
            XCTAssertTrue(target.exists, "Deferred audit element disappeared: \(key)")
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
        XCTAssertEqual(XCTWaiter.wait(for: [settled], timeout: 5), .completed, "Visible frames must settle")
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
        let tabs = app.otherElements["resting-tabs"]
        if tabs.exists && tabs.buttons["tab-today"].isHittable {
            bottom = min(bottom, tabs.frame.minY)
        }
        return CGRect(x: viewport.minX, y: viewport.minY, width: viewport.width, height: bottom - viewport.minY)
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
        app.switches["visible-social"].tap()
        XCTAssertFalse(app.switches["visible-career"].isEnabled)
        XCTAssertEqual(app.switches["visible-career"].value as? String, "1")
        XCTAssertTrue(app.staticTexts["area-visibility-hint"].label.contains("Keep at least one area on"))
        try auditAndCapture(app, "11-settings--last-area", expecting: app.staticTexts["area-visibility-hint"])
        showNavigationTop(app)
        app.buttons["go-back"].tap()
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
        XCTAssertFalse(app.buttons["area-relationship"].exists)
        XCTAssertFalse(app.buttons["area-social"].exists)
        try auditAndCapture(app, "06-composer--hidden-areas", expecting: app.buttons["area-career"])
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
        XCTAssertTrue(app.buttons["settings-clear-status"].isSelected)
        XCTAssertEqual(app.staticTexts["settings-current-status"].label, "Current status: Not set")
        showNavigationTop(app)
        app.buttons["go-back"].tap()
        for (entry, copy, name) in [("settings-about", "settings-disclaimer", "about"),
                                    ("settings-privacy", "settings-privacy-copy", "privacy")] {
            scrollTo(app.buttons[entry], in: app)
            app.buttons[entry].tap()
            XCTAssertTrue(app.staticTexts[copy].exists)
            try auditAndCapture(app, "11-settings--\(name)", expecting: app.staticTexts[copy])
            app.buttons["go-back"].tap()
        }
        app.terminate()
        app.launchArguments.append("--test-largest-text")
        app.launch()
        app.buttons["open-settings"].tap()
        capture(app, "11-settings--largest-text")
        scrollTo(app.buttons["settings-privacy"], in: app)
        capture(app, "11-settings--largest-text-bottom")
        scrollTo(app.buttons["settings-relationship"], in: app)
        XCTAssertTrue(app.buttons["settings-relationship"].label.contains("Not set"))
        app.buttons["settings-relationship"].tap()
        capture(app, "11-settings--relationship-largest-text")
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
            app.buttons["face-proof-next"].tap()
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
            sizes.buttons["face-proof-next"].tap()
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
        XCTAssertTrue(app.buttons["turn-over"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["draw-title"].label, "This one is yours")
        XCTAssertTrue(app.buttons["draw-card-3"].isSelected)
        XCTAssertEqual(app.buttons["draw-card-3"].frame.midY, fanFrame.midY, accuracy: 0.5,
                       "Selection must preserve the fan/disc anchor to within pixel rounding")
        try auditAndCapture(app, "02-draw-card-chosen", expecting: app.staticTexts["draw-title"], app.buttons["turn-over"])
        app.buttons["turn-over"].tap()
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
        XCTAssertTrue(app.buttons["back-to-today"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.descendants(matching: .any)["revealed-card"].label, "The Star, Upright")
        try auditAndCapture(app, "03-reveal--reopened")
        app.buttons["back-to-today"].tap()
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

    func testReversedCardUsesItsOwnMeaning() throws {
        let app = app(seed: "reference-4", audit: true)
        reveal(app)
        XCTAssertEqual(app.staticTexts["card-name"].label, "The Star")
        XCTAssertEqual(app.staticTexts["card-details"].label, "Reversed · Major Arcana XVII")
        XCTAssertEqual(app.descendants(matching: .any)["revealed-card"].label, "The Star, Reversed")
        try auditAndCapture(app, "03-reveal--reversed", expecting: app.staticTexts["card-name"], app.buttons["see-meaning"])
        app.buttons["see-meaning"].tap()
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
        capture(app, "04-today--reversed-bottom")
    }

    func testStorageOpenFailureRecoveryAndDesignEvidence() throws {
        let failed = app(extra: ["--test-storage-open-failure"], audit: true)
        XCTAssertTrue(failed.staticTexts["storage-error-title"].waitForExistence(timeout: 5))
        XCTAssertTrue(failed.buttons["storage-retry"].isHittable)
        try auditAndCapture(failed, "storage-open-failure", expecting: failed.staticTexts["storage-error-title"], failed.buttons["storage-retry"])
        failed.buttons["storage-retry"].tap()
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
        scrollTo(app.staticTexts["draw-title"], in: app)
        capture(app, "02-draw-card-chosen--largest-text")
        scrollTo(app.buttons["turn-over"], in: app)
        capture(app, "02-draw-card-chosen--largest-text-bottom")
        app.buttons["turn-over"].tap()
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

    private let fixedSpread = ["--test-random-indices", "0,0,0,1,0,0"]

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
        XCTAssertFalse(app.staticTexts["relationship-prompt"].exists)
        XCTAssertFalse(app.buttons["latest-area-reading"].exists)
        scrollTo(app.staticTexts["ask-title"], in: app)
        capture(app, "05-ask--status-skipped-no-reading")
        scrollTo(app.buttons["suggestion-2"], in: app)
        capture(app, "05-ask--status-skipped-no-reading-bottom")
        app.buttons["tab-today"].tap()
        XCTAssertTrue(app.staticTexts["today-title"].exists)
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
        scrollTo(app.buttons["suggestion-2"], in: app)
        try auditAndCapture(app, "06-composer--bottom", expecting: app.buttons["suggestion-2"])
        scrollTo(app.buttons["suggestion-0"], in: app)
        app.buttons["suggestion-0"].tap()
        XCTAssertTrue(app.buttons["submit-question"].isEnabled)
        XCTAssertEqual(app.descendants(matching: .any)["question-field"].firstMatch.value as? String, "Where is this going?")
        showNavigationTop(app)
        try auditAndCapture(app, "06-composer-question-entered", expecting: app.staticTexts["composer-title"], app.buttons["submit-question"])
        scrollTo(app.buttons["suggestion-2"], in: app)
        try auditAndCapture(app, "06-composer-question-entered--bottom", expecting: app.buttons["suggestion-2"])
        app.buttons["submit-question"].tap()
        XCTAssertEqual(app.staticTexts["spread-question"].label, "“Where is this going?”")
        XCTAssertFalse(app.buttons["tab-ask"].exists)
        for position in ["situation", "action", "outcome"] {
            XCTAssertTrue(app.descendants(matching: .any)["spread-slot-\(position)"].firstMatch.label.contains("empty"))
        }
        try auditAndCapture(app, "08-three-card-pick", expecting: app.staticTexts["spread-question"], app.buttons["draw-card-3"])
        app.buttons["draw-card-3"].tap()
        try auditAndCapture(app, "08-three-card-pick--one-picked", expecting: app.staticTexts["pick-prompt"], app.buttons["spread-shuffle"])
        app.buttons["draw-card-1"].tap()
        try auditAndCapture(app, "08-three-card-pick--two-picked", expecting: app.staticTexts["pick-prompt"], app.buttons["spread-shuffle"])
        app.buttons["draw-card-5"].tap()
        XCTAssertEqual(app.descendants(matching: .any)["spread-slot-situation"].firstMatch.label, "Situation, The Star, Upright")
        XCTAssertEqual(app.descendants(matching: .any)["spread-slot-action"].firstMatch.label, "Action, The Sun, Reversed")
        XCTAssertEqual(app.descendants(matching: .any)["spread-slot-outcome"].firstMatch.label, "Outcome, The Fool, Upright")
        try auditAndCapture(app, "08-three-card-pick-complete", expecting: app.staticTexts["spread-complete-title"], app.buttons["read-spread"])
        app.buttons["read-spread"].tap()
        XCTAssertTrue(app.staticTexts["reading-saved"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["reading-saved"].label, "Relationship · Saved on this phone")
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
        app.buttons["reading-done"].tap()
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
        app.launchArguments.append("--test-open-saved-reading")
        app.launch()
        XCTAssertTrue(app.staticTexts["reading-saved"].waitForExistence(timeout: 5))
        XCTAssertEqual(identifiers.map { app.staticTexts[$0].label }, original)
        app.buttons["close-reading"].tap()
        XCTAssertTrue(app.staticTexts["today-title"].waitForExistence(timeout: 5))
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
        XCTAssertEqual(app.staticTexts["reading-saved"].label, "Social · Saved on this phone")
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
            XCTAssertEqual(app.staticTexts["spread-question"].label, "“Where is this going?”")
            app.terminate()
            app.launch()
            XCTAssertTrue(app.staticTexts["today-title"].waitForExistence(timeout: 5))
            app.buttons["tab-ask"].tap()
            XCTAssertEqual(app.staticTexts["spread-question"].label, "“Where is this going?”")
            XCTAssertEqual(slots, ["situation", "action", "outcome"].map {
                app.descendants(matching: .any)["spread-slot-\($0)"].firstMatch.label
            })
            app.buttons["go-back"].tap()
            XCTAssertEqual(app.descendants(matching: .any)["question-field"].firstMatch.value as? String, "Where is this going?")
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
}
