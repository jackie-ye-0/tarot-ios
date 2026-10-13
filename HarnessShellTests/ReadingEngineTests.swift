import XCTest
import UIKit
@testable import HarnessShell

final class ReadingEngineTests: XCTestCase {
    func testStableDailyResultAndAllPositions() throws {
        let library = try CardLibrary.load()
        let first = ReadingEngine.dailyDraw(seed: "reference-3", dateKey: "2026-10-11", position: 1, library: library)
        for position in 1...5 {
            let draw = ReadingEngine.dailyDraw(seed: "reference-3", dateKey: "2026-10-11", position: position, library: library)
            XCTAssertEqual(draw.card, first.card)
            XCTAssertEqual(draw.orientation, first.orientation)
            XCTAssertEqual(draw.position, position)
        }
    }

    func testKnownStableHashVector() throws {
        let draw = ReadingEngine.dailyDraw(seed: "reference-1", dateKey: "2026-10-11", position: 3, library: try CardLibrary.load())
        XCTAssertEqual(draw.card.id, "star")
        XCTAssertEqual(draw.orientation, .upright)
    }

    func testDatesAndSeedsVary() throws {
        let library = try CardLibrary.load()
        let cards = Set((1...28).map {
            ReadingEngine.dailyDraw(seed: "sample", dateKey: String(format: "2026-10-%02d", $0), position: 1, library: library).card.id
        })
        XCTAssertGreaterThan(cards.count, 1)
        let seeds = Set((0..<30).map {
            ReadingEngine.dailyDraw(seed: "seed-\($0)", dateKey: "2026-10-11", position: 1, library: library).card.id
        })
        XCTAssertGreaterThan(seeds.count, 1)
    }

    func testDateKeyUsesInjectedTimeZoneAcrossMidnight() throws {
        let instant = try XCTUnwrap(ISO8601DateFormatter().date(from: "2026-10-10T13:30:00Z"))
        let sydney = try XCTUnwrap(TimeZone(identifier: "Australia/Sydney"))
        let utc = try XCTUnwrap(TimeZone(secondsFromGMT: 0))
        XCTAssertEqual(ReadingEngine.dateKey(for: instant, timeZone: sydney), "2026-10-11")
        XCTAssertEqual(ReadingEngine.dateKey(for: instant, timeZone: utc), "2026-10-10")
        XCTAssertEqual(ReadingEngine.dateKey(for: instant.addingTimeInterval(-3600), timeZone: sydney), "2026-10-10")
    }

    func testStarterLibraryHasBothCompleteOrientationsAndDistinctIDs() throws {
        let library = try CardLibrary.load()
        XCTAssertGreaterThanOrEqual(library.cards.count, 6)
        XCTAssertEqual(Set(library.cards.map(\.id)).count, library.cards.count)
        XCTAssertTrue(library.editorialStatus.contains("first-draft"))
        for card in library.cards {
            XCTAssertFalse(card.name.isEmpty)
            XCTAssertFalse(card.arcana.isEmpty)
            XCTAssertNotEqual(card.upright, card.reversed)
            for meaning in [card.upright, card.reversed] {
                XCTAssertTrue((3...4).contains(meaning.keywords.count))
                XCTAssertTrue(meaning.keywords.allSatisfy { !$0.isEmpty })
                XCTAssertGreaterThanOrEqual(meaning.interpretation.split(separator: ".").count, 2)
            }
        }
    }

    func testSnapshotRoundTripKeepsOriginalContent() throws {
        let draw = ReadingEngine.dailyDraw(seed: "snapshot", dateKey: "2026-10-11", position: 5, library: try CardLibrary.load())
        XCTAssertEqual(try JSONDecoder().decode(DailyDraw.self, from: JSONEncoder().encode(draw)), draw)
    }

    func testBundledTypefacesDoNotFallBack() throws {
        for (name, family) in [("Gabarito-Regular", "Gabarito"), ("HankenGrotesk-Regular", "Hanken Grotesk")] {
            let font = try XCTUnwrap(UIFont(name: name, size: 18), "Bundled typeface missing: \(name)")
            XCTAssertEqual(font.familyName, family)
            XCTAssertEqual(font.fontName, name)
        }
    }
}
