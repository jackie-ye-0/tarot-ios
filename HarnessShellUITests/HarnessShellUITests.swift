import XCTest

final class HarnessShellUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    private func app(extra: [String] = [], memory: Bool = true, seed: String = "reference-1", date: String = "2026-10-11T00:00:00Z", animations: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--test-mode", "--test-date", date,
                               "--test-time-zone", "Australia/Sydney", "--test-seed", seed]
        if memory { app.launchArguments.append("--test-memory-store") }
        if !animations { app.launchArguments.append("--test-disable-animations") }
        app.launchArguments += extra
        app.launch()
        return app
    }

    // Reused by every screen test; no ignored audit categories or issue exceptions.
    private func auditAndCapture(_ app: XCUIApplication, _ name: String) throws {
        waitForRitualToSettle(app)
        try app.performAccessibilityAudit { issue in
            let detail = XCTAttachment(string: "\(issue.detailedDescription)\n\(issue.element?.debugDescription ?? "No element exposed")")
            detail.name = "Audit detail - \(name)"
            detail.lifetime = .keepAlways
            self.add(detail)
            return false // Retain diagnostics; every issue still fails the audit.
        }
        capture(app, name)
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
        let turnOver = app.buttons["turn-over"]
        XCTAssertTrue(turnOver.waitForExistence(timeout: 5))
        turnOver.tap()
        XCTAssertTrue(app.buttons["see-meaning"].waitForExistence(timeout: 5))
    }

    func testDrawRevealTodayAndDesignEvidence() throws {
        let app = app(animations: true)
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
        try auditAndCapture(app, "04-today")
        scrollTo(app.staticTexts["next-card-arrival"], in: app)
        XCTAssertEqual(app.staticTexts["next-card-arrival"].label, "Your next card arrives at midnight")
        capture(app, "04-today--bottom")
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
        // Filling yesterday creates a repeat conflict for today; its saved snapshot must still win.
        XCTAssertEqual(earlierName, name)
        XCTAssertNotEqual(earlierDetails, details)
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

    func testTimeZoneChangeWithinSameDateKeepsRevealAndCompletedMotion() {
        let app = app(extra: ["--test-controls", "--test-reduce-motion"], date: "2026-10-11T12:00:00Z", animations: true)
        reveal(app)
        let name = app.staticTexts["card-name"].label
        testControl("test-time-zone", in: app)
        XCTAssertTrue(app.buttons["see-meaning"].exists)
        XCTAssertFalse(app.staticTexts["today-title"].exists)
        testControl("test-toggle-motion", in: app)
        waitForRitualToSettle(app)
        XCTAssertEqual(app.staticTexts["card-name"].label, name)
        XCTAssertTrue(app.staticTexts["card-name"].isHittable,
                      "Turning Reduce Motion off must not hide an already revealed card's text")
        for identifier in ["card-name", "card-details", "card-keywords"] {
            assertVisible(app.staticTexts[identifier], in: app, abovePinnedFooter: true)
        }
        app.buttons["see-meaning"].tap()
        XCTAssertTrue(app.staticTexts["today-title"].waitForExistence(timeout: 5))
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
        capture(app, "04-today--largest-text-interpretation-end")
        scrollTo(app.staticTexts["next-card-arrival"], in: app)
        capture(app, "04-today--largest-text-bottom")
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
    }
}
