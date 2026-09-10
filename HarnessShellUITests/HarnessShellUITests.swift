import XCTest

final class HarnessShellUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testIncrementAndRetainScreenshot() {
        let app = XCUIApplication()
        app.launch()
        let count = app.staticTexts["smoke-count"]
        XCTAssertTrue(count.waitForExistence(timeout: 5))
        XCTAssertEqual(count.label, "0")
        app.buttons["smoke-increment"].tap()
        XCTAssertEqual(count.label, "1")
        app.buttons["smoke-increment"].tap()
        XCTAssertEqual(count.label, "2")
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Passing counter interaction"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }

    func testRelaunchResetsCount() {
        let app = XCUIApplication()
        app.launch()
        app.buttons["smoke-increment"].tap()
        XCTAssertEqual(app.staticTexts["smoke-count"].label, "1")
        app.terminate()
        app.launch()
        XCTAssertEqual(app.staticTexts["smoke-count"].label, "0")
    }
}
