import XCTest
@testable import HarnessShell

final class SmokeCounterTests: XCTestCase {
    func testStartsAtZero() {
        XCTAssertEqual(SmokeCounter().count, 0)
    }

    func testEachIncrementAddsOne() {
        var counter = SmokeCounter()
        counter.increment()
        XCTAssertEqual(counter.count, 1)
        counter.increment()
        XCTAssertEqual(counter.count, 2)
    }
}
