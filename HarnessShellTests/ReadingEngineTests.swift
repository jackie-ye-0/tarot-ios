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

    func testBothSidesOfMidnightAcrossTimeZonesAndDaylightSaving() throws {
        for (zone, midnight, before, after) in [
            ("Australia/Sydney", "2026-10-10T13:00:00Z", "2026-10-10", "2026-10-11"),
            ("America/Los_Angeles", "2026-10-11T07:00:00Z", "2026-10-10", "2026-10-11"),
            ("Pacific/Honolulu", "2027-01-01T10:00:00Z", "2026-12-31", "2027-01-01"),
            ("Australia/Sydney", "2026-10-04T13:00:00Z", "2026-10-04", "2026-10-05"),
            ("America/Los_Angeles", "2026-11-02T08:00:00Z", "2026-11-01", "2026-11-02")
        ] {
            let date = try XCTUnwrap(ISO8601DateFormatter().date(from: midnight))
            let timeZone = try XCTUnwrap(TimeZone(identifier: zone))
            XCTAssertEqual(ReadingEngine.dateKey(for: date.addingTimeInterval(-1), timeZone: timeZone), before, zone)
            XCTAssertEqual(ReadingEngine.dateKey(for: date, timeZone: timeZone), after, zone)
        }
    }

    // The six-card starter cannot exercise a fourteen-day non-repeat run. Interpretations expand in #24–#26.
    private func syntheticDeck() throws -> CardLibrary {
        let template = try CardLibrary.load().cards[0]
        return CardLibrary(version: 1, editorialStatus: "synthetic-test", cards: (0..<78).map {
            TarotCard(id: "card-\($0)", name: "Synthetic card \($0)", arcana: template.arcana,
                      suit: nil, rank: $0, upright: template.upright, reversed: template.reversed)
        })
    }

    private func past(_ card: Int, on date: String, in library: CardLibrary) -> DailyDraw {
        DailyDraw(dateKey: date, position: 1, orientation: .upright, card: library.cards[card], contentVersion: library.version)
    }

    func testRepeatWindowIncludesFourteenthDayTodayAndFutureButNotFifteenthDay() throws {
        let library = try syntheticDeck()
        let day = "2026-10-11"
        XCTAssertEqual(ReadingEngine.repeatWindowStart(for: day), "2026-09-27")
        XCTAssertEqual(ReadingEngine.repeatWindowStart(for: "2028-03-01"), "2028-02-16")
        XCTAssertEqual(ReadingEngine.repeatWindowStart(for: "2027-01-01"), "2026-12-18")
        for (date, expected) in [("2026-09-26", 49), ("2026-09-27", 4), ("2026-10-10", 4),
                                  ("2026-10-11", 4), ("2026-10-12", 4)] {
            let draw = ReadingEngine.dailyDraw(seed: "repeat-window", dateKey: day, position: 1,
                                              library: library, previousDraws: [past(49, on: date, in: library)])
            XCTAssertEqual(draw.card.id, "card-\(expected)", date)
        }
    }

    func testWestwardTravelDoesNotRepeatTheLaterDateCard() throws {
        let library = try CardLibrary.load()
        let instant = try XCTUnwrap(ISO8601DateFormatter().date(from: "2026-10-11T00:00:00Z"))
        let sydney = try XCTUnwrap(TimeZone(identifier: "Australia/Sydney"))
        let honolulu = try XCTUnwrap(TimeZone(identifier: "Pacific/Honolulu"))
        let sydneyKey = ReadingEngine.dateKey(for: instant, timeZone: sydney)
        let honoluluKey = ReadingEngine.dateKey(for: instant, timeZone: honolulu)
        let laterDraw = ReadingEngine.dailyDraw(seed: "travel-2", dateKey: sydneyKey, position: 2, library: library)
        let unfilteredEarlierDraw = ReadingEngine.dailyDraw(seed: "travel-2", dateKey: honoluluKey,
                                                           position: 5, library: library)
        let earlierDraw = ReadingEngine.dailyDraw(seed: "travel-2", dateKey: honoluluKey, position: 5,
                                                  library: library, previousDraws: [laterDraw])

        XCTAssertEqual(sydneyKey, "2026-10-11")
        XCTAssertEqual(honoluluKey, "2026-10-10")
        XCTAssertEqual(unfilteredEarlierDraw.card.id, laterDraw.card.id)
        XCTAssertNotEqual(earlierDraw.card.id, laterDraw.card.id)
    }

    func testSaltedRetriesStopAtFirstFreshCardOrAcceptThirdRetry() throws {
        let library = try syntheticDeck()
        // Fixed vectors also prove orientation does not exempt a repeated card identity.
        let candidates = [49, 4, 5, 53]
        for excludedCount in 0...4 {
            let previous = candidates.prefix(excludedCount).enumerated().map {
                past($0.element, on: String(format: "2026-10-%02d", 10 - $0.offset), in: library)
            }
            for position in 1...5 {
                let draw = ReadingEngine.dailyDraw(seed: "repeat-window", dateKey: "2026-10-11", position: position,
                                                  library: library, previousDraws: previous)
                XCTAssertEqual(draw.card.id, "card-\(candidates[min(excludedCount, 3)])")
                XCTAssertEqual(draw.orientation, excludedCount >= 3 ? .upright : .reversed)
                XCTAssertEqual(draw.position, position)
                XCTAssertEqual(draw, ReadingEngine.dailyDraw(seed: "repeat-window", dateKey: "2026-10-11", position: position,
                                                            library: library, previousDraws: Array(previous.reversed())))
            }
        }
    }

    func testTwoYearSimulatedRunHasNoRepeatInsideFourteenDays() throws {
        let library = try syntheticDeck()
        let zone = try XCTUnwrap(TimeZone(secondsFromGMT: 0))
        let start = try XCTUnwrap(ISO8601DateFormatter().date(from: "2026-01-01T00:00:00Z"))
        var history: [DailyDraw] = []
        for day in 0..<730 {
            let key = ReadingEngine.dateKey(for: start.addingTimeInterval(Double(day) * 86_400), timeZone: zone)
            let draw = ReadingEngine.dailyDraw(seed: "long-run", dateKey: key, position: day % 5 + 1,
                                              library: library, previousDraws: history)
            XCTAssertFalse(history.suffix(14).contains { $0.card.id == draw.card.id }, key)
            history.append(draw)
        }
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
                let daily = try XCTUnwrap(meaning.daily)
                XCTAssertTrue(daily.isComplete)
                let lines = ReadingArea.allCases.map { daily.reading(for: $0).line }
                XCTAssertEqual(Set(lines).count, 3)
                for area in ReadingArea.allCases {
                    XCTAssertTrue((0...100).contains(daily.reading(for: area).score))
                }
                XCTAssertNotNil(daily.colourHex.range(of: "^#[0-9a-fA-F]{6}$", options: .regularExpression))
            }
        }
    }

    func testFullDeckIdentityHasTwentyTwoMajorsAndFourCompleteSuits() throws {
        let deck = CardIdentity.deck
        XCTAssertEqual(deck.count, 78)
        XCTAssertEqual(Set(deck.map(\.id)).count, 78)
        XCTAssertEqual(Set(deck.map(\.name)).count, 78)
        let majors = deck.filter { $0.suit == nil }
        XCTAssertEqual(majors.count, 22)
        XCTAssertEqual(majors.map(\.rank), Array(0...21))
        XCTAssertTrue(majors.allSatisfy { $0.arcana.hasPrefix("Major Arcana") })
        XCTAssertEqual(majors.first?.name, "The Fool")
        XCTAssertEqual(majors.last?.name, "The World")
        for suit in ["Wands", "Cups", "Swords", "Pentacles"] {
            let cards = deck.filter { $0.suit == suit }
            XCTAssertEqual(cards.map(\.rank), Array(1...14), suit)
            XCTAssertTrue(cards.allSatisfy { $0.arcana == "Minor Arcana" && $0.name.hasSuffix(" of \(suit)") })
            XCTAssertEqual(cards.first?.name, "Ace of \(suit)")
            XCTAssertEqual(Array(cards.suffix(4).map(\.name)), ["Page", "Knight", "Queen", "King"].map { "\($0) of \(suit)" })
        }
        // Existing stored content renders the same identity without changing its schema or wording.
        for card in try CardLibrary.load().cards {
            XCTAssertEqual(deck.first { $0.id == card.id }, card.identity)
        }
    }

    func testSnapshotRoundTripKeepsOriginalContent() throws {
        let library = try CardLibrary.load()
        let draw = ReadingEngine.dailyDraw(seed: "reference-1", dateKey: "2026-10-11", position: 5, library: library)
        let snapshot = try JSONEncoder().encode(draw)
        let revised = try amendedLibrary { daily in
            daily["colourName"] = "Clay"
            daily["colourHex"] = "#b0654a"
            daily["object"] = "A new object"
            daily["bestHour"] = "After 6 pm"
            daily["career"] = ["score": 10, "line": "A revised work line."]
        }
        let next = ReadingEngine.dailyDraw(seed: "reference-1", dateKey: "2026-10-11", position: 5,
                                          library: try CardLibrary.decode(revised))
        XCTAssertNotEqual(next.meaning.daily, draw.meaning.daily)
        XCTAssertEqual(try JSONDecoder().decode(DailyDraw.self, from: snapshot), draw)
    }

    func testLibraryRejectsMissingOrInvalidTodayContent() throws {
        let mutations: [(inout [String: Any]) -> Void] = [
            { $0["colourName"] = " " },
            { $0["colourHex"] = "#12345G" },
            { $0["colourHex"] = "#123456\n" },
            { $0["object"] = "" },
            { $0["bestHour"] = "" },
            { $0["career"] = ["score": -1, "line": "Work line."] },
            { $0["social"] = ["score": 101, "line": "Social line."] },
            { $0["relationship"] = $0["career"] },
            { $0["career"] = ["score": 72, "line": " "] },
            { $0.removeValue(forKey: "social") }
        ]
        for mutate in mutations { XCTAssertThrowsError(try CardLibrary.decode(amendedLibrary(mutate))) }
        var library = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(CardLibrary.load())) as? [String: Any])
        var cards = try XCTUnwrap(library["cards"] as? [[String: Any]])
        var meaning = try XCTUnwrap(cards[0]["upright"] as? [String: Any])
        meaning.removeValue(forKey: "daily")
        cards[0]["upright"] = meaning
        library["cards"] = cards
        XCTAssertThrowsError(try CardLibrary.decode(JSONSerialization.data(withJSONObject: library)))
    }

    func testDailyContentDecodeRejectsMalformedColour() throws {
        let daily = try XCTUnwrap(try CardLibrary.load().cards[0].upright.daily)
        var encoded = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(daily)) as? [String: Any])
        encoded["colourHex"] = "#12345G"

        XCTAssertThrowsError(try JSONDecoder().decode(DailyContent.self, from: JSONSerialization.data(withJSONObject: encoded)))
    }

    func testEarlierSnapshotOpensWithoutBackfillingNewContent() throws {
        let draw = ReadingEngine.dailyDraw(seed: "reference-1", dateKey: "2026-10-11", position: 3, library: try CardLibrary.load())
        var snapshot = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(draw)) as? [String: Any])
        var card = try XCTUnwrap(snapshot["card"] as? [String: Any])
        for orientation in ["upright", "reversed"] {
            var meaning = try XCTUnwrap(card[orientation] as? [String: Any])
            meaning.removeValue(forKey: "daily")
            card[orientation] = meaning
        }
        snapshot["card"] = card
        snapshot["contentVersion"] = 1
        let earlier = try JSONDecoder().decode(DailyDraw.self, from: JSONSerialization.data(withJSONObject: snapshot))
        XCTAssertEqual(earlier.meaning.interpretation, draw.meaning.interpretation)
        XCTAssertNil(earlier.meaning.daily)
        XCTAssertEqual(earlier.contentVersion, 1)
    }

    private func amendedLibrary(_ mutate: (inout [String: Any]) -> Void) throws -> Data {
        var library = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(CardLibrary.load())) as? [String: Any])
        var cards = try XCTUnwrap(library["cards"] as? [[String: Any]])
        var meaning = try XCTUnwrap(cards[0]["upright"] as? [String: Any])
        var daily = try XCTUnwrap(meaning["daily"] as? [String: Any])
        mutate(&daily)
        meaning["daily"] = daily
        cards[0]["upright"] = meaning
        library["cards"] = cards
        return try JSONSerialization.data(withJSONObject: library)
    }

    func testBundledTypefacesDoNotFallBack() throws {
        for (name, family) in [("Gabarito-Regular", "Gabarito"), ("HankenGrotesk-Regular", "Hanken Grotesk")] {
            let font = try XCTUnwrap(UIFont(name: name, size: 18), "Bundled typeface missing: \(name)")
            XCTAssertEqual(font.familyName, family)
            XCTAssertEqual(font.fontName, name)
        }
    }
}
