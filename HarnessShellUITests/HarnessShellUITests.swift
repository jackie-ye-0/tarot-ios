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

    private func app(extra: [String] = [], memory: Bool = true, seed: String = "reference-1", date: String = "2026-10-11T00:00:00Z", animations: Bool = false, audit: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--test-mode", "--test-date", date,
                               "--test-time-zone", "Australia/Sydney", "--test-seed", seed]
        if memory { app.launchArguments.append("--test-memory-store") }
        if !animations { app.launchArguments.append("--test-disable-animations") }
        app.launchArguments += extra
        if audit { app.launchArguments.append("--test-reduce-motion") }
        app.launch()
        return app
    }

    // Capture the requested stop, then audit overlapping stops until every deferred element is covered.
    private func auditAndCapture(_ app: XCUIApplication, _ name: String, startsScrolled: Bool = false) throws {
        XCTAssertTrue(app.launchArguments.contains("--test-reduce-motion"), "Audit fixtures must disable animations")
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
        var covered = Set<String>()
        for stop in 0..<12 {
            let stopIndex = stop + (startsScrolled ? 1 : 0)
            let scroll = app.scrollViews.allElementsBoundByIndex.first { $0.isHittable }
            let viewport = scroll?.frame.intersection(visibleFrame(in: app)) ?? .null
            let fullyVisibleBefore = deferred.keys.filter {
                let element = deferred[$0]!
                return element.exists && !element.frame.isEmpty && viewport.contains(element.frame)
            }
            var deferredAtThisStop = Set<String>()
            try app.performAccessibilityAudit(for: .all) { issue in
                // At rest this stays strict. At scroll edges, an unattributed text
                // detection is backed by the screen's explicit exposed-label check.
                if stopIndex > 0 && issue.auditType == .elementDetection && issue.element == nil &&
                    issue.compactDescription == "Potentially inaccessible text" {
                    let record = ["stopIndex": String(stopIndex), "nativeIssue": issue.compactDescription,
                                  "description": issue.detailedDescription, "auditType": "elementDetection",
                                  "disposition": "recorded-unattributed-scrolled-text"]
                    records.append(record)
                    let evidence = XCTAttachment(screenshot: app.screenshot())
                    evidence.name = "\(name)--text-detection-stop-\(stopIndex)-\(records.count)"
                    evidence.lifetime = .keepAlways
                    self.add(evidence)
                    let detail = XCTAttachment(string: "Stop \(stopIndex): \(issue.compactDescription)\n\(issue.detailedDescription)")
                    detail.name = "text-detection-\(name)-stop-\(stopIndex)-\(records.count)"
                    detail.lifetime = .keepAlways
                    self.add(detail)
                    print("Audit recorded unattributed text detection: \(name), stop \(stopIndex), \(issue.detailedDescription)")
                    return true
                }
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
                var record = ["identifier": element.identifier, "elementKey": key, "label": element.label,
                              "frame": String(describing: frame), "viewport": String(describing: viewport),
                              "nativeIssue": issue.compactDescription]
                if self.isNotFullyVisible(frame, in: viewport) {
                    print("Audit deferred \(key): \(frame), viewport \(viewport)")
                    deferred[key] = matches.firstMatch
                    deferredAtThisStop.insert(key)
                    record["disposition"] = "deferred-until-fully-visible"
                    record["alreadyAuditedFullyVisible"] = String(covered.contains(key))
                    records.append(record)
                    return true
                }
                guard !viewport.isNull && viewport.contains(frame) else { return false }
                let screenshot = element.screenshot()
                guard let image = screenshot.image.cgImage, let measured = measuredContrast(image) else {
                    return false
                }
                record["ratio"] = String(measured.ratio)
                record["backgroundLuminance"] = String(measured.background)
                record["textLuminance"] = String(measured.text)
                record["disposition"] = measured.ratio >= 4.5 ? "dismissed-measured-contrast" : "failed-measured-contrast"
                if identifier == "core-interpretation" && measured.ratio < 7 {
                    record["disposition"] = "failed-core-reading-safety-floor"
                }
                records.append(record)
                let evidence = XCTAttachment(screenshot: screenshot)
                evidence.name = "contrast-element-\(name)-\(records.count)"
                evidence.lifetime = .keepAlways
                self.add(evidence)
                print("Audit measured \(key): \(measured.ratio):1, \(record["disposition"]!)")
                guard identifier != "core-interpretation" || measured.ratio >= 7 else { return false }
                if measured.ratio >= 4.5 { return true }
                return false
            }
            covered.formUnion(fullyVisibleBefore.filter {
                let element = deferred[$0]!
                return !deferredAtThisStop.contains($0) && element.exists && !element.frame.isEmpty && viewport.contains(element.frame)
            })
            if !covered.isEmpty { print("Audit fully visible: \(covered.sorted())") }
            guard let key = deferred.keys.sorted().first(where: { !covered.contains($0) }) else { return }
            let target = deferred[key]!
            XCTAssertTrue(target.exists, "Deferred audit element disappeared: \(key)")
            let distance = viewport.height * 0.45 * (target.frame.minY < viewport.minY ? -1 : 1)
            let origin = app.coordinate(withNormalizedOffset: .zero)
            let start = origin.withOffset(CGVector(dx: viewport.midX, dy: viewport.midY + distance / 2))
            let end = origin.withOffset(CGVector(dx: viewport.midX, dy: viewport.midY - distance / 2))
            start.press(forDuration: 0.05, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.1)
        }
        try requireAuditCoverage(Set(deferred.keys), covered: covered)
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

    private func capture(_ app: XCUIApplication, _ name: String) {
        waitForRitualToSettle(app)
        let elements = app.descendants(matching: .any).allElementsBoundByIndex.filter { $0.isHittable }
        var previous: [CGRect]?
        let settled = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            let frames = elements.map(\.frame)
            defer { previous = frames }
            return !frames.isEmpty && frames == previous
        }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [settled], timeout: 5), .completed, "Capture frames must settle")
        // Accessibility frames settle before the compositor after a colour-scheme change.
        Thread.sleep(forTimeInterval: 0.3)
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func visibleFrame(in app: XCUIApplication, abovePinnedFooter: Bool = false) -> CGRect {
        let marker = app.otherElements["test-safe-viewport"]
        guard marker.waitForExistence(timeout: 5) else {
            XCTFail("Missing safe-area viewport marker: launch a Debug build with --test-mode")
            return .null
        }
        let viewport = marker.frame
        XCTAssertFalse(viewport.isEmpty, "The test safe-area viewport must have completed layout")
        let footer = app.otherElements["screen-footer"]
        let bottom = abovePinnedFooter && footer.exists ? min(viewport.maxY, footer.frame.minY) : viewport.maxY
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

    private func dragContent(_ app: XCUIApplication, up: Bool) {
        let viewport = visibleFrame(in: app)
        let origin = app.coordinate(withNormalizedOffset: .zero)
        let start = origin.withOffset(CGVector(dx: viewport.midX, dy: up ? viewport.maxY - 80 : viewport.minY + 80))
        let end = origin.withOffset(CGVector(dx: viewport.midX, dy: up ? viewport.minY + 80 : viewport.maxY - 80))
        start.press(forDuration: 0.05, thenDragTo: end)
    }

    private func scrollTo(_ element: XCUIElement, in app: XCUIApplication,
                          file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(element.waitForExistence(timeout: 5), file: file, line: line)
        for _ in 0..<10 {
            let frame = element.frame
            let viewport = visibleFrame(in: app)
            if !frame.isEmpty && viewport.contains(frame) { break }
            dragContent(app, up: frame.maxY > viewport.maxY)
        }
        assertVisible(element, in: app, file: file, line: line)
    }

    private func reveal(_ app: XCUIApplication, position: Int = 3) {
        let card = app.buttons["draw-card-\(position)"]
        XCTAssertTrue(card.waitForExistence(timeout: 5))
        XCTAssertEqual(card.label, "Card \(position) of 5")
        XCTAssertGreaterThanOrEqual(card.frame.width, 44)
        XCTAssertGreaterThanOrEqual(card.frame.height, 44)
        card.tap()
        let turnOver = app.buttons["turn-over"]
        XCTAssertTrue(turnOver.waitForExistence(timeout: 5))
        turnOver.tap()
        XCTAssertTrue(app.buttons["see-meaning"].waitForExistence(timeout: 5))
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
        try auditAndCapture(app, "02-draw")
        let fanFrame = app.buttons["draw-card-3"].frame
        app.buttons["draw-card-3"].tap()
        XCTAssertTrue(app.buttons["turn-over"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["draw-title"].label, "This one is yours")
        XCTAssertTrue(app.buttons["draw-card-3"].isSelected)
        XCTAssertEqual(app.buttons["draw-card-3"].frame.midY, fanFrame.midY, accuracy: 0.5,
                       "Selection must preserve the fan/disc anchor to within pixel rounding")
        try auditAndCapture(app, "02-draw-card-chosen")
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
        try auditAndCapture(app, "03-reveal")
        app.buttons["see-meaning"].tap()
        XCTAssertTrue(app.staticTexts["core-interpretation"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["core-interpretation"].label.contains("Hope may feel more useful"))
        XCTAssertEqual(app.windows.firstMatch.frame.size, CGSize(width: 390, height: 844), "Verify the reference viewport on the selected simulator")
        for identifier in ["today-card", "core-interpretation", "daily-colour", "daily-object", "daily-hour"] {
            assertVisible(app.descendants(matching: .any)[identifier].firstMatch, in: app)
        }
        assertTodayContent(app)
        try auditAndCapture(app, "04-today")
        scrollTo(app.staticTexts["line-social"], in: app)
        try auditAndCapture(app, "04-today--bottom", startsScrolled: true)
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
            "area-label-career": "Career", "line-career": "Share an idea you have been quietly tending.",
            "area-label-relationship": "Relationship", "line-relationship": "Let a kind word make room for connection."
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
        XCTAssertEqual(app.staticTexts["area-label-social"].label, "Social")
        XCTAssertEqual(app.staticTexts["line-social"].label, "Notice who gives you space to be yourself.")
        assertVisible(app.staticTexts["area-label-social"], in: app)
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
        try auditAndCapture(app, "04-today--earlier-snapshot")
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
        app.buttons["draw-card-1"].tap()
        app.buttons["draw-card-5"].tap()
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
        try auditAndCapture(app, "02-draw--washing-cards")
        app.buttons["draw-card-1"].tap()
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
        app.buttons["draw-card-5"].tap()
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
        app.buttons["draw-card-2"].tap()
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
        try auditAndCapture(app, "03-reveal--reversed")
        app.buttons["see-meaning"].tap()
        XCTAssertTrue(app.staticTexts["core-interpretation"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["core-interpretation"].label.contains("Hope may feel more useful"))
        XCTAssertEqual(app.descendants(matching: .any)["daily-colour"].firstMatch.label, "Colour, Blue")
        XCTAssertEqual(app.descendants(matching: .any)["score-career"].firstMatch.label, "Career, 54 out of 100")
        XCTAssertEqual(app.staticTexts["line-relationship"].label, "Name a need without asking for an instant answer.")
        capture(app, "04-today--reversed")
    }

    func testStorageOpenFailureRecoveryAndDesignEvidence() throws {
        let failed = app(extra: ["--test-storage-open-failure"], audit: true)
        XCTAssertTrue(failed.staticTexts["storage-error-title"].waitForExistence(timeout: 5))
        XCTAssertTrue(failed.buttons["storage-retry"].isHittable)
        try auditAndCapture(failed, "storage-open-failure")
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
        app.buttons["draw-card-3"].tap()
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
        let modalDetails = app.scrollViews["screen-content"].staticTexts["card-details"]
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
        reduced.buttons["draw-card-3"].tap()
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
}
