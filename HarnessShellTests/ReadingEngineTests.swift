import XCTest
import SwiftData
import Testing
import UIKit
@testable import HarnessShell

final class ReadingEngineTests: XCTestCase {
    func testNamedPersonValidationAndMissingFieldLabels() {
        XCTAssertFalse(NamedPerson().isComplete)
        XCTAssertEqual(NamedPerson().actionTitle, "Add a name and who they are")
        XCTAssertEqual(NamedPerson(name: " \n", relation: .friend).actionTitle, "Add a name or nickname")
        XCTAssertEqual(NamedPerson(name: "Sam").actionTitle, "Choose who they are to you")
        XCTAssertEqual(PersonRelation.allCases.map(\.rawValue), ["partner", "crush", "ex", "family", "friend", "colleague"])
        for relation in PersonRelation.allCases {
            let person = NamedPerson(name: "  Sam  ", relation: relation)
            XCTAssertTrue(person.isComplete)
            XCTAssertEqual(person.actionTitle, "Draw for you and Sam")
        }
    }

    func testNamedPersonPicksAndCompositionUseDedicatedMeaningsAndPreserveDetails() throws {
        let library = try CardLibrary.load()
        for card in library.cards {
            for meaning in [card.upright, card.reversed] {
                let positions = try XCTUnwrap(meaning.namedPersonPositions)
                XCTAssertTrue(positions.isComplete)
                XCTAssertEqual(Set(ReadingType.namedPerson.positions.map { positions.text(for: $0) }).count, 3)
            }
        }
        var picks: [SpreadPick] = []
        for _ in 0..<3 {
            picks.append(try XCTUnwrap(ReadingEngine.nextPick(after: picks, library: library, type: .namedPerson, randomIndex: { _ in 1 })))
        }
        XCTAssertEqual(picks.map(\.position), [.you, .them, .connection])
        XCTAssertEqual(Set(picks.map { $0.card.id }).count, 3)
        XCTAssertNil(ReadingEngine.nextPick(after: picks, library: library, type: .namedPerson, randomIndex: { _ in XCTFail(); return 0 }))
        let person = NamedPerson(name: "Sam", relation: .colleague, note: "How can we communicate more clearly?")
        let id = UUID()
        let date = Date(timeIntervalSince1970: 123)
        let reading = try ReadingEngine.compose(id: id, createdAt: date, area: .relationship, question: "You and Sam",
                                                picks: picks, library: library, person: person)
        XCTAssertEqual(reading.type, .namedPerson)
        XCTAssertEqual(reading.area, .relationship)
        XCTAssertEqual(reading.person, person)
        XCTAssertTrue(reading.connectingPassage.contains("Sam"))
        XCTAssertEqual(reading.sections.map(\.text), picks.map { $0.card.meaning($0.orientation).namedPersonPositions!.text(for: $0.position) })
        XCTAssertEqual(reading, try ReadingEngine.compose(id: id, createdAt: date, area: .relationship, question: "You and Sam",
                                                         picks: picks, library: library, person: person))
        XCTAssertEqual(reading, try JSONDecoder().decode(QuestionReading.self, from: JSONEncoder().encode(reading)))
        let draft = SpreadDraft(area: .relationship, question: "You and Sam", picks: Array(picks.prefix(1)), isPicking: true, person: person)
        XCTAssertNoThrow(try draft.validate())
        XCTAssertEqual(draft, try JSONDecoder().decode(SpreadDraft.self, from: JSONEncoder().encode(draft)))
        for invalid in [NamedPerson(name: "Sam"), NamedPerson(name: " \t", relation: .friend)] {
            XCTAssertThrowsError(try ReadingEngine.compose(id: id, createdAt: date, area: .relationship, question: "You and Sam",
                                                          picks: picks, library: library, person: invalid))
        }
        XCTAssertThrowsError(try ReadingEngine.compose(id: id, createdAt: date, area: .career, question: "You and Sam",
                                                      picks: picks, library: library, person: person))
        XCTAssertThrowsError(try ReadingEngine.compose(id: id, createdAt: date, area: .relationship, question: "You and Sam",
                                                      picks: picks, library: library))
    }

    func testNamedPersonCompositionUsesNeutralRelationshipLensForEveryRelation() throws {
        let library = try CardLibrary.load()
        let picks = zip(ReadingType.namedPerson.positions, library.cards.prefix(3)).map {
            SpreadPick(position: $0, card: $1, orientation: .upright)
        }
        let id = UUID()
        let date = Date(timeIntervalSince1970: 123)
        let colleague = NamedPerson(name: "Sam", relation: .colleague)
        let partner = NamedPerson(name: "Sam", relation: .partner)
        let colleagueReading = try ReadingEngine.compose(
            id: id, createdAt: date, area: .relationship, question: "You and Sam",
            picks: picks, library: library, relationshipStatus: .inRelationship, person: colleague
        )
        let partnerReading = try ReadingEngine.compose(
            id: id, createdAt: date, area: .relationship, question: "You and Sam",
            picks: picks, library: library, relationshipStatus: .inRelationship, person: partner
        )

        XCTAssertTrue(colleagueReading.connectingPassage.contains(library.questions.relationship.lens))
        XCTAssertFalse(colleagueReading.connectingPassage.contains(library.questions.relationship.relationshipLenses.inRelationship))
        var expectedPartnerReading = colleagueReading
        expectedPartnerReading.person = partner
        XCTAssertEqual(partnerReading, expectedPartnerReading)
    }

    func testNamedPersonCrisisNoteAndQuestionBothBlockComposition() throws {
        let library = try CardLibrary.load()
        let picks = zip(ReadingType.namedPerson.positions, library.cards.prefix(3)).map {
            SpreadPick(position: $0, card: $1, orientation: .upright)
        }
        for (question, note) in [("You and Sam", "I want to kill myself"), ("I want to kill myself", "An ordinary note")] {
            XCTAssertTrue(ReadingEngine.requiresSupport(question: question, note: note, content: library.crisis))
            XCTAssertThrowsError(try ReadingEngine.compose(id: UUID(), createdAt: Date(), area: .relationship, question: question,
                                                          picks: picks, library: library,
                                                          person: NamedPerson(name: "Sam", relation: .friend, note: note)))
        }
        XCTAssertFalse(ReadingEngine.requiresSupport(question: "You and Sam", note: "We disagreed about a film.", content: library.crisis))
    }

    func testNamedPersonLibraryRequiresEveryMeaningAndOlderSnapshotsStillDecode() throws {
        let library = try CardLibrary.load()
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(library)) as? [String: Any])
        var cards = try XCTUnwrap(json["cards"] as? [[String: Any]])
        var upright = try XCTUnwrap(cards[0]["upright"] as? [String: Any])
        upright.removeValue(forKey: "namedPersonPositions")
        cards[0]["upright"] = upright
        json["cards"] = cards
        XCTAssertThrowsError(try CardLibrary.decode(JSONSerialization.data(withJSONObject: json)))
        let oldCard = try JSONDecoder().decode(TarotCard.self, from: JSONSerialization.data(withJSONObject: cards[0]))
        XCTAssertNil(oldCard.upright.namedPersonPositions)
        let legacyDraft = Data(#"{"area":"career","question":"What next?","picks":[],"isPicking":true}"#.utf8)
        let restored = try JSONDecoder().decode(SpreadDraft.self, from: legacyDraft)
        XCTAssertEqual(restored.type, .question)
        XCTAssertNoThrow(try restored.validate())
    }

    @MainActor
    func testLegacyInstallWithoutWelcomeFieldSkipsWelcome() throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString,
                                                                          directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let configuration = ModelConfiguration(url: directory.appending(path: "legacy.store"),
                                               cloudKitDatabase: .none)
        try autoreleasepool {
            let legacy = try ModelContainer(for: InstallIdentity.self, StoredDailyDraw.self,
                                            configurations: configuration)
            legacy.mainContext.insert(InstallIdentity(seed: "legacy"))
            try legacy.mainContext.save()
        }
        let store = try DrawStore(configuration: configuration)
        let seed = try store.installSeed {
            XCTFail("Opening a legacy store must preserve its installation identity")
            return "replacement"
        }

        let session = try makeSession(store: store, seed: seed)

        XCTAssertEqual(seed, "legacy")
        guard case .draw = session.screen else { return XCTFail("Legacy installs should skip Welcome") }
    }

    @MainActor
    func testNewInstallShowsWelcomeOnlyOnce() throws {
        let store = try makeStore()
        let seed = try store.installSeed { "new-install" }
        let session = try makeSession(store: store, seed: seed)
        guard case .welcome = session.screen else { return XCTFail("New installs should show Welcome") }

        try session.completeWelcome()
        guard case .draw = session.screen else { return XCTFail("Completing Welcome should open Draw") }
        let relaunched = try makeSession(store: store, seed: seed)
        guard case .draw = relaunched.screen else { return XCTFail("Later launches should skip Welcome") }
    }

    @MainActor
    func testCompletingWelcomeWithTodaysDrawRoutesToToday() throws {
        let store = try makeStore()
        let seed = try store.installSeed { "existing-draw" }
        let library = try CardLibrary.load()
        let draw = ReadingEngine.dailyDraw(seed: seed, dateKey: "2026-10-11", position: 3, library: library)
        _ = try store.save(draw)
        let session = try makeSession(store: store, seed: seed, library: library)
        guard case .welcome = session.screen else { return XCTFail("New installs should show Welcome") }

        try session.completeWelcome()

        guard case let .today(saved) = session.screen else { return XCTFail("A saved card should route to Today") }
        XCTAssertEqual(saved, draw)
    }

    @MainActor
    func testReadFailureAfterSavingWelcomeRetriesPastWelcome() throws {
        let store = try makeStore()
        let seed = try store.installSeed { "read-after-save" }
        let session = try makeSession(store: store, seed: seed)
        store.failsNextWelcomeRead = true

        // LaunchView answers this error with its storage-failure screen, not the welcome save alert.
        XCTAssertThrowsError(try session.completeWelcome()) { error in
            guard case DrawStore.StoreError.read = error else { return XCTFail("Expected a read failure, got \(error)") }
        }
        XCTAssertFalse(session.welcomeSaveFailed)
        XCTAssertTrue(try store.hasCompletedWelcome())

        // That screen's Try again runs the launch routing again.
        guard case .draw = try makeSession(store: store, seed: seed).screen else {
            return XCTFail("Retrying should open Draw without showing Welcome again")
        }
    }

    @MainActor
    func testDraftDeleteFailureRetryDeletesInsteadOfSaving() throws {
        let store = try makeStore()
        let seed = try store.installSeed { "draft-delete-retry" }
        try store.completeWelcome()
        let session = try makeSession(store: store, seed: seed)
        session.openComposer(question: "What should I notice?")
        XCTAssertNotNil(try store.questionDraft())
        store.failsNextDraftSave = true

        session.backToAsk()

        XCTAssertTrue(session.draftSaveFailed)
        XCTAssertNotNil(try store.questionDraft())
        guard case .composer = session.screen else { return XCTFail("A failed discard should keep the composer open") }

        session.retryDraftSave()

        XCTAssertFalse(session.draftSaveFailed)
        XCTAssertNil(try store.questionDraft())
        guard case .ask = session.screen else { return XCTFail("Retrying the discard should return to Ask") }
    }

    @MainActor
    func testDiscardClearsQuestionDraftAfterFailedSpreadTransition() throws {
        let store = try makeStore()
        let seed = try store.installSeed { "failed-spread-transition" }
        try store.completeWelcome()
        let session = try makeSession(store: store, seed: seed)
        session.openComposer(question: "What should I carry forward?")
        store.failsNextSpreadSave = true
        session.submitQuestion()
        store.failsNextSpreadSave = true
        session.backToComposer()
        XCTAssertNil(try store.spreadDraft())
        XCTAssertNotNil(try store.questionDraft())

        session.backToAsk()

        XCTAssertNil(try store.spreadDraft())
        XCTAssertNil(try store.questionDraft())
        guard case .ask = session.screen else { return XCTFail("Discarding should return to Ask") }
        let relaunched = try makeSession(store: store, seed: seed)
        XCTAssertFalse(relaunched.hasDraft)
        XCTAssertTrue(relaunched.question.isEmpty)
    }

    @MainActor
    private func makeStore() throws -> DrawStore {
        try DrawStore(configuration: ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none))
    }

    @MainActor
    private func makeSession(store: DrawStore, seed: String, library: CardLibrary? = nil) throws -> AppSession {
        var configuration = LaunchConfiguration()
        configuration.fixedDate = try XCTUnwrap(ISO8601DateFormatter().date(from: "2026-10-11T00:00:00Z"))
        configuration.timeZone = try XCTUnwrap(TimeZone(secondsFromGMT: 0))
        return try AppSession(clock: SessionClock(configuration: configuration), seed: seed, store: store,
                              library: try library ?? CardLibrary.load(), randomIndex: { _ in 0 })
    }

    func testHistoryCombinesSnapshotsOrdersAndFiltersBySavedArea() throws {
        let library = try CardLibrary.load()
        let zone = try XCTUnwrap(TimeZone(identifier: "Australia/Sydney"))
        let instant = try XCTUnwrap(ISO8601DateFormatter().date(from: "2026-10-10T14:00:00Z"))
        let draws = ["2026-10-10", "2026-10-11", "2026-10-12"].map {
            ReadingEngine.dailyDraw(seed: "history", dateKey: $0, position: 2, library: library)
        }
        let picks = zip(QuestionPosition.allCases, library.cards.prefix(3)).map {
            SpreadPick(position: $0.0, card: $0.1, orientation: .reversed)
        }
        let readings = try ReadingArea.allCases.enumerated().map { offset, area in
            try ReadingEngine.compose(id: UUID(), createdAt: instant.addingTimeInterval(Double(offset) * 60),
                area: area, question: "What can I notice?", picks: picks, library: library)
        }
        let all = ReadingEngine.history(draws: draws, readings: readings, timeZone: zone)
        XCTAssertEqual(all, [.daily(draws[2]), .reading(readings[2]), .reading(readings[1]),
                             .reading(readings[0]), .daily(draws[1]), .daily(draws[0])])
        for reading in readings {
            XCTAssertEqual(all.filter { $0.matches(area: reading.area) }, [.reading(reading)])
        }
        XCTAssertEqual(ReadingEngine.history(draws: [], readings: [], timeZone: zone), [])
        let travelled = ReadingEngine.history(draws: draws, readings: readings, timeZone: TimeZone(secondsFromGMT: 0)!)
        XCTAssertEqual(travelled.first, .daily(draws[2]))
        XCTAssertEqual(travelled[1], .daily(draws[1]), "Only reading timestamps use the supplied zone; daily date keys never move")
    }

    func testHistoryUsesNewDailyTimestampsAndDecodesOlderSnapshots() throws {
        let library = try CardLibrary.load()
        let instant = Date(timeIntervalSince1970: 1_791_676_800)
        let old = ReadingEngine.dailyDraw(seed: "history", dateKey: "2026-10-11", position: 1, library: library)
        let before = ReadingEngine.dailyDraw(seed: "history", dateKey: "2026-10-10", position: 1,
                                             library: library, createdAt: instant.addingTimeInterval(-60))
        let after = ReadingEngine.dailyDraw(seed: "history", dateKey: "2026-10-11", position: 1,
                                            library: library, createdAt: instant.addingTimeInterval(60))
        let picks = zip(QuestionPosition.allCases, library.cards.prefix(3)).map {
            SpreadPick(position: $0.0, card: $0.1, orientation: .upright)
        }
        let reading = try ReadingEngine.compose(id: UUID(), createdAt: instant, area: .career,
            question: "What can I notice?", picks: picks, library: library)
        for zone in ["Australia/Sydney", "Pacific/Honolulu"] {
            XCTAssertEqual(ReadingEngine.history(draws: [before, after], readings: [reading], timeZone: TimeZone(identifier: zone)!),
                           [.daily(after), .reading(reading), .daily(before)])
        }
        let oldData = try JSONEncoder().encode(old)
        XCTAssertFalse(String(decoding: oldData, as: UTF8.self).contains("createdAt"))
        XCTAssertNil(try JSONDecoder().decode(DailyDraw.self, from: oldData).createdAt)
        XCTAssertEqual(try JSONDecoder().decode(DailyDraw.self, from: JSONEncoder().encode(after)), after)
        XCTAssertEqual(old.card, after.card, "The added timestamp must not enter card selection")
        XCTAssertEqual(old.orientation, after.orientation)
    }

    func testHistoryEqualTimesHaveStableOrderAndKeepDistinctReadings() throws {
        let library = try CardLibrary.load()
        let picks = zip(QuestionPosition.allCases, library.cards.prefix(3)).map {
            SpreadPick(position: $0.0, card: $0.1, orientation: .upright)
        }
        let readings = try (1...2).map { value in
            try ReadingEngine.compose(id: UUID(uuidString: "00000000-0000-0000-0000-00000000000\(value)")!,
                createdAt: Date(timeIntervalSince1970: 0), area: .career,
                question: "Same question?", picks: picks, library: library)
        }
        XCTAssertEqual(ReadingEngine.history(draws: [], readings: Array(readings.reversed()), timeZone: TimeZone(secondsFromGMT: 0)!),
                       readings.map(HistoryEntry.reading))
    }

    func testHistoryMonthLeapYearLeadingDaysAndYearNavigation() {
        let october = HistoryMonth(dateKey: "2026-10-11")
        XCTAssertEqual(october.leadingBlanks, 3)
        XCTAssertEqual(october.keys.count, 31)
        XCTAssertEqual(october.keys.first, "2026-10-01")
        XCTAssertEqual(october.keys.last, "2026-10-31")
        XCTAssertEqual(HistoryMonth(dateKey: "2024-02-29").keys.count, 29)
        XCTAssertEqual(HistoryMonth(dateKey: "2026-02-01").keys.count, 28)
        XCTAssertEqual(HistoryMonth(dateKey: "2026-12-31").moving(1).keys.first, "2027-01-01")
        XCTAssertEqual(HistoryMonth(dateKey: "2027-01-01").moving(-1).keys.first, "2026-12-01")
        XCTAssertEqual(HistoryMonth.label(for: "2026-10-11"), "Sunday 11 October 2026")
    }

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
        let source = try CardLibrary.load()
        let template = source.cards[0]
        return CardLibrary(version: 1, editorialStatus: "synthetic-test", cards: (0..<78).map {
            TarotCard(id: "card-\($0)", name: "Synthetic card \($0)", arcana: template.arcana,
                      suit: nil, rank: $0, upright: template.upright, reversed: template.reversed)
        }, questions: source.questions, crisis: source.crisis)
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

    func testSpreadPicksConsumeInjectedRandomnessOnlyAtEachPickWithoutReplacement() throws {
        let library = try CardLibrary.load()
        var supplied = [0, 0, 0, 1, 0, 0]
        var bounds: [Int] = []
        var picks: [SpreadPick] = []
        let source: (Int) -> Int = { bound in
            bounds.append(bound)
            return supplied.removeFirst()
        }
        XCTAssertTrue(bounds.isEmpty)
        for count in 1...3 {
            let before = picks
            picks.append(try XCTUnwrap(ReadingEngine.nextPick(after: picks, library: library, randomIndex: source)))
            XCTAssertEqual(Array(picks.dropLast()), before)
            XCTAssertEqual(bounds.count, count * 2)
            XCTAssertEqual(Set(picks.map { $0.card.id }).count, count)
        }
        XCTAssertEqual(bounds, [library.cards.count, 2, library.cards.count - 1, 2, library.cards.count - 2, 2])
        XCTAssertEqual(picks.map(\.position), [.situation, .action, .outcome])
        XCTAssertEqual(picks.map { $0.card.id }, Array(library.cards.prefix(3)).map(\.id))
        XCTAssertEqual(picks.map(\.orientation), [.upright, .reversed, .upright])
        XCTAssertNil(ReadingEngine.nextPick(after: picks, library: library, randomIndex: source))
        XCTAssertEqual(bounds.count, 6)
    }

    func testResumedSpreadKeepsSnapshotAndDrawsOnlyRemainingCards() throws {
        let library = try CardLibrary.load()
        let first = try XCTUnwrap(ReadingEngine.nextPick(after: [], library: library, randomIndex: { _ in 0 }))
        let draft = SpreadDraft(area: .social, question: "What brings us together?", picks: [first], isPicking: true)
        let restored = try JSONDecoder().decode(SpreadDraft.self, from: JSONEncoder().encode(draft))
        try restored.validate()
        XCTAssertEqual(restored, draft)
        var bounds: [Int] = []
        let next = try XCTUnwrap(ReadingEngine.nextPick(after: restored.picks, library: library) {
            bounds.append($0)
            return $0 - 1
        })
        XCTAssertEqual(bounds, [library.cards.count - 1, 2])
        XCTAssertEqual(next.position, .action)
        XCTAssertNotEqual(next.card.id, first.card.id)
        XCTAssertEqual(next.orientation, .reversed)
        XCTAssertEqual(restored.picks, [first])
        for picks in [[next], [first, first], [first, next, next, next]] {
            XCTAssertThrowsError(try SpreadDraft(area: .social, question: draft.question, picks: picks, isPicking: true).validate())
        }
        XCTAssertThrowsError(try SpreadDraft(area: .social, question: " ", picks: [], isPicking: true).validate())
        XCTAssertNoThrow(try SpreadDraft(area: .social, question: "", picks: [first], isPicking: false).validate())
    }

    @MainActor
    func testDraftSaveRetryKeepsPickAndReadingSaveClearsDraft() throws {
        let store = try makeStore()
        let seed = try store.installSeed { "draft-test" }
        try store.completeWelcome()
        let session = try makeSession(store: store, seed: seed)
        session.openComposer(question: "How can I begin?")
        session.submitQuestion()
        store.failsNextSpreadSave = true
        session.pickCard()
        let first = session.picks
        XCTAssertTrue(session.draftSaveFailed)
        XCTAssertEqual(first.count, 1)
        XCTAssertEqual(try store.spreadDraft()?.picks.count, 0)
        session.pickCard()
        XCTAssertEqual(session.picks, first)
        session.retryDraftSave()
        XCTAssertFalse(session.draftSaveFailed)
        XCTAssertEqual(try store.spreadDraft()?.picks, first)
        session.backToComposer()
        session.question = "What can I learn?"
        session.area = .career
        let restored = try makeSession(store: store, seed: seed)
        restored.openAsk()
        guard case .composer = restored.screen else { return XCTFail("Back should restore the composer") }
        XCTAssertEqual(restored.question, session.question)
        XCTAssertEqual(restored.area, .career)
        restored.submitQuestion()
        XCTAssertEqual(restored.picks, first)
        restored.pickCard()
        restored.pickCard()
        restored.readSpread()
        XCTAssertNil(try store.spreadDraft())
        XCTAssertEqual(try store.latestReading()?.picks, restored.picks)
    }

    @MainActor
    func testFailedDraftDiscardRetainsDraftUntilRetry() throws {
        let store = try makeStore()
        let seed = try store.installSeed { "discard-test" }
        let session = try makeSession(store: store, seed: seed)
        session.openComposer(question: "Where can I grow?")
        session.submitQuestion()
        session.pickCard()
        session.backToComposer()
        store.failsNextSpreadSave = true
        session.backToAsk()
        guard case .composer = session.screen else { return XCTFail("Failed discard must stay in the composer") }
        XCTAssertNotNil(try store.spreadDraft())
        session.retryDraftSave()
        guard case .ask = session.screen else { return XCTFail("Retry should return to Ask") }
        XCTAssertNil(try store.spreadDraft())
        XCTAssertTrue(session.picks.isEmpty)
    }

    func testEveryStarterPositionMeaningAndQuestionAreaIsComplete() throws {
        let library = try CardLibrary.load()
        XCTAssertTrue(library.questions.isComplete)
        for card in library.cards {
            for meaning in [card.upright, card.reversed] {
                let positions = try XCTUnwrap(meaning.questionPositions)
                XCTAssertTrue(positions.isComplete)
                XCTAssertEqual(Set(ReadingType.question.positions.map { positions.text(for: $0) }).count, 3)
            }
        }
        let suggestions = ReadingArea.allCases.flatMap { library.questions.content(for: $0).suggestions }
        XCTAssertEqual(Set(suggestions).count, suggestions.count)
        XCTAssertTrue(suggestions.allSatisfy { $0.hasSuffix("?") })
        XCTAssertEqual(Set(ReadingArea.allCases.map { library.questions.content(for: $0).lens }).count, 3)
    }

    func testCompositionUsesEveryPositionOrientationAndAreaLensDeterministically() throws {
        let library = try CardLibrary.load()
        let picks = zip(ReadingType.question.positions, library.cards.prefix(3)).map { position, card in
            SpreadPick(position: position, card: card, orientation: position == .action ? .reversed : .upright)
        }
        let id = UUID()
        let date = Date(timeIntervalSince1970: 1234)
        for area in ReadingArea.allCases {
            let reading = try ReadingEngine.compose(id: id, createdAt: date, area: area, question: "What matters now?",
                                                    picks: picks, library: library)
            XCTAssertEqual(reading.question, "What matters now?")
            XCTAssertEqual(reading.area, area)
            XCTAssertEqual(reading.picks, picks)
            XCTAssertEqual(reading.sections.map(\.text), picks.map {
                $0.card.meaning($0.orientation).questionPositions!.text(for: $0.position)
            })
            XCTAssertEqual(reading.connectingPassage, library.questions.content(for: area).lens)
            XCTAssertTrue(library.questions.reflections.contains(reading.reflectionQuestion))
            XCTAssertTrue(reading.reflectionQuestion.hasSuffix("?"))
            XCTAssertEqual(reading, try ReadingEngine.compose(id: id, createdAt: date, area: area,
                                                              question: "What matters now?", picks: picks, library: library))
            XCTAssertEqual(reading, try JSONDecoder().decode(QuestionReading.self, from: JSONEncoder().encode(reading)))
        }
    }

    func testEmptyQuestionsIncompleteAndRepeatedSpreadsCannotCreateReadings() throws {
        let library = try CardLibrary.load()
        for question in ["", "   ", "\n\t "] { XCTAssertFalse(ReadingEngine.canSubmit(question: question)) }
        XCTAssertTrue(ReadingEngine.canSubmit(question: "  How can I begin?  "))
        let invalid = ReadingType.question.positions.map { SpreadPick(position: $0, card: library.cards[0], orientation: .upright) }
        for picks in [[], Array(invalid.prefix(2)), invalid] {
            XCTAssertThrowsError(try ReadingEngine.compose(id: UUID(), createdAt: Date(), area: .career,
                                                           question: "How can I begin?", picks: picks, library: library))
        }
    }

    func testReadingAnnotationsRoundTripWithoutChangingOriginalContent() throws {
        let library = try CardLibrary.load()
        let picks = zip(ReadingType.question.positions, library.cards.prefix(3)).map {
            SpreadPick(position: $0, card: $1, orientation: .upright)
        }
        let original = try ReadingEngine.compose(id: UUID(), createdAt: Date(timeIntervalSince1970: 1234),
                                                area: .social, question: "Where can I belong?", picks: picks, library: library)
        XCTAssertNil(original.response)
        XCTAssertNil(original.note)
        for response in ReadingResponse.allCases {
            var annotated = original
            annotated.response = response
            annotated.note = "A thought today.\nAnother thought tomorrow."
            let reopened = try JSONDecoder().decode(QuestionReading.self, from: JSONEncoder().encode(annotated))
            XCTAssertEqual(reopened, annotated)
            annotated.response = nil
            annotated.note = nil
            XCTAssertEqual(annotated, original)
        }
        var legacy = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(original)) as? [String: Any])
        legacy.removeValue(forKey: "response")
        legacy.removeValue(forKey: "note")
        XCTAssertEqual(try JSONDecoder().decode(QuestionReading.self, from: JSONSerialization.data(withJSONObject: legacy)), original)
    }

    func testDailySnapshotFromBeforeQuestionContentStillDecodes() throws {
        let draw = ReadingEngine.dailyDraw(seed: "old", dateKey: "2026-10-11", position: 1, library: try CardLibrary.load())
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(draw)) as? [String: Any])
        var card = try XCTUnwrap(json["card"] as? [String: Any])
        for orientation in ["upright", "reversed"] {
            var meaning = try XCTUnwrap(card[orientation] as? [String: Any])
            meaning.removeValue(forKey: "questionPositions")
            card[orientation] = meaning
        }
        json["card"] = card
        let old = try JSONDecoder().decode(DailyDraw.self, from: JSONSerialization.data(withJSONObject: json))
        XCTAssertEqual(old.meaning.interpretation, draw.meaning.interpretation)
        XCTAssertEqual(old.card.id, draw.card.id)
        XCTAssertNil(old.meaning.questionPositions)
    }

    func testQuestionEditsDismissReturnAndCollapsePastedBreaks() {
        XCTAssertEqual(QuestionEdit.applying("Where can I grow?\n", to: "Where can I grow?"),
                       QuestionEdit(text: "Where can I grow?", dismissKeyboard: true))
        XCTAssertEqual(QuestionEdit.applying("Where\n can I grow?", to: "Where can I grow?"),
                       QuestionEdit(text: "Where can I grow?", dismissKeyboard: true))
        XCTAssertEqual(QuestionEdit.applying("First\r\n\r\nsecond\nthird", to: ""),
                       QuestionEdit(text: "First second third", dismissKeyboard: false))
        XCTAssertEqual(QuestionEdit.applying("  A question?  ", to: ""),
                       QuestionEdit(text: "  A question?  ", dismissKeyboard: false))
    }

}

@Model
private final class InstallIdentity {
    @Attribute(.unique) var key: String
    var seed: String

    init(seed: String) {
        key = "installation"
        self.seed = seed
    }
}

@Model
private final class StoredDailyDraw {
    @Attribute(.unique) var dateKey: String
    var snapshot: Data

    init(dateKey: String, snapshot: Data) {
        self.dateKey = dateKey
        self.snapshot = snapshot
    }
}

struct AskComposerRulesTests {
    @Test func characterLimitPreservesWholeCharactersAndExistingWords() {
        let full = String(repeating: "👩🏽‍💻", count: 300)
        #expect(QuestionEdit.applying(full + "x", to: full).text == full)
        #expect(QuestionEdit.applying("x" + full, to: full).text == full)
        #expect(QuestionEdit.applying(full + "extra", to: "").text == full)
        let almostFull = String(repeating: "a", count: 294) + " tail"
        #expect(QuestionEdit.applying("xyz" + almostFull, to: almostFull).text == "x" + almostFull)
        #expect(QuestionEdit.applying(String(full.dropLast()), to: full).text.count == 299)
        #expect(QuestionEdit.applying(full + "\n", to: full).dismissKeyboard)
        #expect(ReadingEngine.canSubmit(question: full))
        #expect(!ReadingEngine.canSubmit(question: full + "x"))
    }

    @Test(arguments: [RelationshipStatus.single, .inRelationship, .complicated, .preferNotToSay])
    func relationshipLensMatchesStatusAndOtherAreasStayUnchanged(status: RelationshipStatus) throws {
        let library = try CardLibrary.load()
        let picks = zip(ReadingType.question.positions, library.cards.prefix(3)).map {
            SpreadPick(position: $0, card: $1, orientation: .upright)
        }
        let content = library.questions.relationship
        let variants = content.relationshipLenses
        let expected: String
        switch status {
        case .single: expected = variants.single
        case .inRelationship: expected = variants.inRelationship
        case .complicated: expected = variants.complicated
        case .preferNotToSay: expected = content.lens
        }
        #expect(Set([content.lens, variants.single, variants.inRelationship, variants.complicated]).count == 4)
        for area in ReadingArea.allCases {
            let id = UUID()
            let date = Date(timeIntervalSince1970: 1234)
            let reading = try ReadingEngine.compose(id: id, createdAt: date, area: area, question: "What matters?",
                picks: picks, library: library, relationshipStatus: status)
            #expect(reading.connectingPassage == (area == .relationship ? expected : library.questions.content(for: area).lens))
            #expect(reading == (try ReadingEngine.compose(id: id, createdAt: date, area: area, question: "What matters?",
                picks: picks, library: library, relationshipStatus: status)))
        }
        let neutral = try ReadingEngine.compose(id: UUID(), createdAt: Date(), area: .relationship,
            question: "What matters?", picks: picks, library: library)
        #expect(neutral.connectingPassage == content.lens)
    }
}

struct CrisisRulesTests {
    @Test(arguments: [
        "I want to kill myself", "I want to end my life", "I do not want to live",
        "I DON’T WANT TO LIVE", "I'm thinking about self-harm", "I feel suicidal",
        "I might hurt myself", "I cannot keep myself safe", "I can't cope anymore",
        "My partner is hitting me", "Someone is abusing me", "I'm afraid of my partner",
        "I am not safe", "I'm in danger", "I want to END,   MY\nLIFE.",
        "My partner is threatening to kill me"
    ])
    func syntheticDistressStopsReading(question: String) throws {
        let library = try CardLibrary.load()
        #expect(ReadingEngine.requiresSupport(question: question, content: library.crisis))
        let picks = zip(ReadingType.question.positions, library.cards.prefix(3)).map {
            SpreadPick(position: $0, card: $1, orientation: .upright)
        }
        #expect(throws: (any Error).self) {
            try ReadingEngine.compose(id: UUID(), createdAt: Date(timeIntervalSince1970: 0), area: .social,
                                      question: question, picks: picks, library: library)
        }
    }

    @Test(arguments: [
        "What should I focus on at work?", "How can I connect with my partner?",
        "I am anxious about a presentation", "How can I support a friend?",
        "How can I end my lifelong habit of rushing?", "What skill myself and my team could practise?",
        "How do I cope with a difficult week?", "What should I notice about this relationship?",
        "Where is this going?", "How can I ask for a promotion?", "", "   "
    ])
    func ordinaryQuestionsPass(question: String) throws {
        #expect(!ReadingEngine.requiresSupport(question: question, content: try CardLibrary.load().crisis))
    }

    @Test func suggestionsPassAndIncompleteSafetyContentIsRejected() throws {
        let library = try CardLibrary.load()
        #expect(library.crisis.editorialStatus.contains("PLACEHOLDER"))
        #expect(library.crisis.editorialStatus.contains("Jackie's sign-off"))
        for area in ReadingArea.allCases {
            for question in library.questions.content(for: area).suggestions {
                #expect(!ReadingEngine.requiresSupport(question: question, content: library.crisis))
            }
        }
        var json = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(library)) as? [String: Any])
        var crisis = try #require(json["crisis"] as? [String: Any])
        for patterns in [[], ["---"]] as [[String]] {
            crisis["patterns"] = patterns
            json["crisis"] = crisis
            let invalid = try JSONSerialization.data(withJSONObject: json)
            #expect(throws: (any Error).self) { try CardLibrary.decode(invalid) }
        }
    }
}

struct AreaVisibilityTests {
    @Test(arguments: ReadingArea.allCases)
    func lastAreaCannotBeHidden(last: ReadingArea) {
        var hidden: Set<ReadingArea> = []
        for area in ReadingArea.allCases where area != last {
            hidden = ReadingEngine.settingVisibility(false, for: area, hiddenAreas: hidden)
        }
        #expect(ReadingEngine.settingVisibility(false, for: last, hiddenAreas: hidden) == hidden)
        #expect(ReadingEngine.settingVisibility(true, for: last, hiddenAreas: hidden) == hidden)
        for area in ReadingArea.allCases {
            hidden = ReadingEngine.settingVisibility(true, for: area, hiddenAreas: hidden)
        }
        #expect(hidden.isEmpty)
    }

    @MainActor @Test
    func preferencesPreserveSnapshotsAndSurviveReopening() throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let configuration = ModelConfiguration(url: directory.appending(path: "settings.store"), cloudKitDatabase: .none)
        let library = try CardLibrary.load()
        let draw = ReadingEngine.dailyDraw(seed: "settings", dateKey: "2026-10-11", position: 3, library: library)
        var picks: [SpreadPick] = []
        for _ in 0..<3 {
            picks.append(try #require(ReadingEngine.nextPick(after: picks, library: library, randomIndex: { _ in 0 })))
        }
        let reading = try ReadingEngine.compose(id: UUID(), createdAt: Date(), area: .relationship,
                                                question: "What should I notice?", picks: picks, library: library)
        try autoreleasepool {
            let store = try DrawStore(configuration: configuration)
            _ = try store.installSeed { "settings" }
            #expect(try store.hiddenAreas().isEmpty)
            _ = try store.save(draw)
            _ = try store.save(reading)
            try store.saveHiddenAreas([.relationship, .social])
            try store.saveRelationshipStatus(.complicated)
        }
        let reopened = try DrawStore(configuration: configuration)
        #expect(try reopened.hiddenAreas() == [.relationship, .social])
        #expect(try reopened.draw(for: draw.dateKey) == draw)
        #expect(try reopened.latestReadingsByArea()[.relationship] == reading)
        #expect(try reopened.relationshipPreference()?.status == RelationshipStatus.complicated.rawValue)
        try reopened.saveHiddenAreas([])
        try reopened.saveRelationshipStatus(nil)
        #expect(try reopened.latestReadingsByArea()[.relationship] == reading)
        #expect(try reopened.draw(for: draw.dateKey) == draw)
        #expect(try reopened.relationshipPreference() != nil)
        #expect(try reopened.relationshipPreference()?.status == nil)
        #expect(throws: (any Error).self) { try reopened.saveHiddenAreas(Set(ReadingArea.allCases)) }
        #expect(try reopened.hiddenAreas().isEmpty)
    }

    @MainActor @Test
    func failedSettingsSaveKeepsPreviousChoiceAndRetryWorks() throws {
        let store = try DrawStore(configuration: ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none))
        let seed = try store.installSeed { "settings-failure" }
        try store.completeWelcome()
        let session = try AppSession(clock: SessionClock(configuration: LaunchConfiguration()), seed: seed,
                                     store: store, library: CardLibrary.load(), randomIndex: { _ in 0 })
        session.showsSettings = true
        session.openComposer(question: "Keep these words")
        store.failsNextSettingsSave = true
        session.setArea(.relationship, visible: false)
        #expect(session.settingsSaveFailed)
        #expect(session.hiddenAreas.isEmpty)
        #expect(session.area == .relationship)
        session.settingsSaveFailed = false
        session.setArea(.relationship, visible: false)
        #expect(session.area == .career)
        #expect(session.question == "Keep these words")
        #expect(try store.questionDraft()?.area == .career)
        session.setRelationshipStatus(.single)
        store.failsNextSettingsSave = true
        session.setRelationshipStatus(.complicated)
        #expect(session.settingsSaveFailed)
        #expect(session.relationshipStatus == .single)
        #expect(try store.relationshipPreference()?.status == RelationshipStatus.single.rawValue)
        session.setRelationshipStatus(nil)
        #expect(session.relationshipStatus == nil)
        #expect(session.relationshipStatusAsked)
    }
}

struct MorningReminderRuleTests {
    @MainActor @Test
    func foregroundRefreshClearsRecoveredInvitationDenial() async throws {
        let store = try DrawStore(configuration: ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none))
        let seed = try store.installSeed { "reminder-recovery" }
        try store.completeWelcome()
        let library = try CardLibrary.load()
        let draw = ReadingEngine.dailyDraw(seed: seed, dateKey: "2026-10-11", position: 3, library: library)
        _ = try store.save(draw)
        var configuration = LaunchConfiguration()
        configuration.fixedDate = try #require(ISO8601DateFormatter().date(from: "2026-10-11T00:00:00Z"))
        configuration.timeZone = try #require(TimeZone(identifier: "Australia/Sydney"))
        let notifications = ReminderNotifications(fixture: "deny")
        let session = try AppSession(clock: SessionClock(configuration: configuration), seed: seed,
                                     store: store, library: library, randomIndex: { _ in 0 },
                                     notifications: notifications)

        #expect(session.showsReminderInvitation)
        await session.setReminderEnabled(true)
        #expect(session.reminderInvitationDenied)

        notifications.setTestPermission(.allowed)
        await session.refreshReminder()

        #expect(!session.reminderDenied)
        #expect(!session.reminderInvitationDenied)
    }

    @Test func invitationRequiresFirstSavedDrawAndUnansweredFirstDate() {
        var preference = ReminderPreference()
        #expect(!preference.shouldInvite(on: "2026-10-11", hasDraw: false))
        preference.firstDrawDateKey = "2026-10-11"
        #expect(!preference.shouldInvite(on: "2026-10-11", hasDraw: false))
        #expect(preference.shouldInvite(on: "2026-10-11", hasDraw: true))
        #expect(!preference.shouldInvite(on: "2026-10-12", hasDraw: true))
        preference.invitationAnswered = true
        #expect(!preference.shouldInvite(on: "2026-10-11", hasDraw: true))
        preference.invitationAnswered = false
        preference.enabled = true
        #expect(!preference.shouldInvite(on: "2026-10-11", hasDraw: true))
    }

    @Test func leavingFirstDatePermanentlyExpiresInvitation() {
        var preference = ReminderPreference(firstDrawDateKey: "2026-10-11")
        preference.expireInvitation(on: "2026-10-11")
        #expect(!preference.invitationAnswered)
        preference.expireInvitation(on: "2026-10-12")
        preference.expireInvitation(on: "2026-10-11")
        #expect(!preference.shouldInvite(on: "2026-10-11", hasDraw: true))
        var undrawn = ReminderPreference()
        undrawn.expireInvitation(on: "2026-10-12")
        #expect(!undrawn.invitationAnswered)
    }

    @Test(arguments: ["Australia/Sydney", "Pacific/Honolulu", "Europe/London"])
    func reminderUsesLocalEightAcrossDaylightSaving(zone: String) throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: zone))
        // Sydney's daylight-saving boundary is 4 October 2026.
        let before = try #require(calendar.date(from: DateComponents(year: 2026, month: 10, day: 3, hour: 9)))
        let next = try #require(calendar.nextDate(after: before, matching: MorningReminderRule.time,
                                                 matchingPolicy: .nextTime))
        let parts = calendar.dateComponents([.day, .hour, .minute], from: next)
        #expect(parts.day == 4)
        #expect(parts.hour == 8)
        #expect(parts.minute == 0)
        #expect(MorningReminderRule.time.timeZone == nil)
        #expect(MorningReminderRule.time.day == nil)
    }
}
