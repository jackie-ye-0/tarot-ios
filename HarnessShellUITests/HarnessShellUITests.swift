import XCTest

final class HarnessShellUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    private func app(extra: [String] = [], memory: Bool = true, seed: String = "reference-1", date: String = "2026-10-11T00:00:00Z") -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--test-mode", "--test-date", date,
                               "--test-time-zone", "Australia/Sydney", "--test-seed", seed]
        if memory { app.launchArguments.append("--test-memory-store") }
        app.launchArguments += extra
        app.launch()
        return app
    }

    // Reused by every screen test; no ignored audit categories or issue exceptions.
    private func auditAndCapture(_ app: XCUIApplication, _ name: String) throws {
        try app.performAccessibilityAudit()
        capture(app, name)
    }

    private func capture(_ app: XCUIApplication, _ name: String) {
        // Accessibility frames settle before the compositor after a colour-scheme change.
        Thread.sleep(forTimeInterval: 0.3)
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func visibleFrame(in app: XCUIApplication, abovePinnedFooter: Bool = false) -> CGRect {
        let window = app.windows.firstMatch.frame
        // The simulator does not always expose its status bar to XCTest.
        let top = app.statusBars.firstMatch.exists ? app.statusBars.firstMatch.frame.maxY : window.minY + 44
        let footer = app.otherElements["screen-footer"]
        let bottom = abovePinnedFooter && footer.exists ? min(window.maxY, footer.frame.minY) : window.maxY - 20
        return CGRect(x: window.minX, y: top, width: window.width, height: bottom - top)
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
        app.buttons["turn-over"].tap()
        XCTAssertTrue(app.buttons["see-meaning"].waitForExistence(timeout: 5))
    }

    func testDrawRevealTodayAndDesignEvidence() throws {
        let app = app()
        XCTAssertTrue(app.staticTexts["draw-title"].waitForExistence(timeout: 5))
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
        try auditAndCapture(app, "04-today")
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
        app.buttons["turn-over"].tap()
        XCTAssertEqual(app.staticTexts["draw-position"].label, "You picked card 5 of five")
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

    func testReversedCardUsesItsOwnMeaning() throws {
        let app = app(seed: "reference-4")
        reveal(app)
        XCTAssertEqual(app.staticTexts["card-name"].label, "The Star")
        XCTAssertEqual(app.staticTexts["card-details"].label, "Reversed · Major Arcana XVII")
        XCTAssertEqual(app.descendants(matching: .any)["revealed-card"].label, "The Star, Reversed")
        try auditAndCapture(app, "03-reveal--reversed")
        app.buttons["see-meaning"].tap()
        XCTAssertTrue(app.staticTexts["core-interpretation"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["core-interpretation"].label.contains("Hope may feel more useful"))
        capture(app, "04-today--reversed")
    }

    func testStorageOpenFailureRecoveryAndDesignEvidence() throws {
        let failed = app(extra: ["--test-storage-open-failure"])
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

    func testLargestTextAndReduceMotion() throws {
        let app = app(extra: ["--test-largest-text", "--test-reduce-motion"])
        scrollTo(app.staticTexts["draw-title"], in: app)
        capture(app, "02-draw--largest-text")
        scrollTo(app.buttons["draw-card-3"], in: app)
        capture(app, "02-draw--largest-text-bottom")
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
        capture(app, "04-today--largest-text-opening")
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
        capture(app, "04-today--largest-text-bottom")
        app.terminate()
        let reduced = self.app(extra: ["--test-reduce-motion"])
        XCTAssertTrue(reduced.buttons["draw-card-3"].waitForExistence(timeout: 5))
        assertVisible(reduced.buttons["draw-card-3"], in: reduced, abovePinnedFooter: true)
        capture(reduced, "02-draw--reduce-motion")
        reveal(reduced)
        assertVisible(reduced.staticTexts["card-name"], in: reduced, abovePinnedFooter: true)
        capture(reduced, "03-reveal--reduce-motion")
    }
}
