import Foundation
import Observation
import SwiftData

struct LaunchConfiguration {
    var exposesTestViewport = false
    var fixedDate: Date?
    var timeZone: TimeZone?
    var seed: String?
    var inMemory = false
    var testStoreID: UUID?
    var largestText = false
    var reduceMotion = false
    var disableAnimations = false
    var holdShuffle = false
    var testMode = false
    var forceStoreOpenFailure = false
    var testControls = false
    var revisedContent = false
    var earlierSnapshot = false
    var cardFaceProof = false
    var cardSizeProof = false
    var randomIndices: [Int] = []
    var openSavedReading = false

    static func current() -> LaunchConfiguration {
        var result = LaunchConfiguration()
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        guard arguments.contains("--test-mode") else { return result }
        result.testMode = true
        result.exposesTestViewport = true
        func value(_ key: String) -> String? {
            guard let index = arguments.firstIndex(of: key), index + 1 < arguments.count else { return nil }
            return arguments[index + 1]
        }
        result.fixedDate = value("--test-date").flatMap { ISO8601DateFormatter().date(from: $0) }
        result.timeZone = value("--test-time-zone").flatMap(TimeZone.init(identifier:)) ?? result.timeZone
        result.seed = value("--test-seed")
        result.inMemory = arguments.contains("--test-memory-store")
        result.testStoreID = value("--test-store-id").flatMap(UUID.init(uuidString:))
        result.largestText = arguments.contains("--test-largest-text")
        result.reduceMotion = arguments.contains("--test-reduce-motion")
        result.disableAnimations = arguments.contains("--test-disable-animations")
        result.holdShuffle = arguments.contains("--test-hold-shuffle")
        result.forceStoreOpenFailure = arguments.contains("--test-storage-open-failure")
        result.testControls = arguments.contains("--test-controls")
        result.revisedContent = arguments.contains("--test-revised-content")
        result.earlierSnapshot = arguments.contains("--test-earlier-snapshot")
        result.cardFaceProof = arguments.contains("--test-card-faces")
        result.cardSizeProof = arguments.contains("--test-card-sizes")
        result.randomIndices = value("--test-random-indices")?.split(separator: ",").compactMap { Int($0) }.filter { $0 >= 0 } ?? []
        result.openSavedReading = arguments.contains("--test-open-saved-reading")
        #endif
        return result
    }
}

@MainActor
final class SessionClock {
    private var fixedDate: Date?
    private var fixedTimeZone: TimeZone?

    init(configuration: LaunchConfiguration) {
        fixedDate = configuration.fixedDate
        fixedTimeZone = configuration.timeZone
    }

    var now: Date { fixedDate ?? Date() }
    var timeZone: TimeZone { fixedTimeZone ?? .current }

    #if DEBUG
    func advanceTestDay() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        fixedDate = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))!
    }

    func toggleTestTimeZone() {
        fixedTimeZone = TimeZone(identifier: timeZone.identifier == "Pacific/Honolulu" ? "Australia/Sydney" : "Pacific/Honolulu")!
    }
    #endif
}

@MainActor @Observable
final class AppSession {
    enum Screen {
        case draw, reveal(DailyDraw), today(DailyDraw), ask, composer, pick, reading(QuestionReading)
    }

    var screen: Screen = .draw
    var saveFailed = false
    var dayRefreshFailed = false
    var readingSaveFailed = false
    var area: ReadingArea = .relationship
    var question = ""
    private(set) var picks: [SpreadPick] = []
    private var pendingReading: QuestionReading?
    private var today: DailyDraw?
    private(set) var date: Date
    private(set) var timeZone: TimeZone
    private(set) var dateKey: String
    let clock: SessionClock
    private let seed: String
    private let store: DrawStore
    private let library: CardLibrary
    private let randomIndex: (Int) -> Int

    init(clock: SessionClock, seed: String, store: DrawStore, library: CardLibrary,
         randomIndex: @escaping (Int) -> Int) throws {
        self.clock = clock
        let now = clock.now
        let zone = clock.timeZone
        date = now
        timeZone = zone
        dateKey = ReadingEngine.dateKey(for: now, timeZone: zone)
        self.seed = seed
        self.store = store
        self.library = library
        self.randomIndex = randomIndex
        today = try store.draw(for: dateKey)
        if let today { screen = .today(today) }
    }

    var dateLabel: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_AU")
        formatter.timeZone = timeZone
        formatter.dateFormat = "EEEE d MMMM"
        return formatter.string(from: date)
    }

    func turnOver(position: Int) {
        let draw: DailyDraw
        do {
            // A tap at midnight must not carry yesterday's selection into the new day.
            guard try !updateDay() else { return }
            if let saved = try store.draw(for: dateKey) {
                today = saved
                screen = .today(saved)
                return
            }
            let previous = try store.draws(from: ReadingEngine.repeatWindowStart(for: dateKey))
            draw = ReadingEngine.dailyDraw(seed: seed, dateKey: dateKey, position: position,
                                           library: library, previousDraws: previous)
        } catch {
            dayRefreshFailed = true
            return
        }
        do {
            let saved = try store.save(draw)
            today = saved
            screen = .reveal(saved)
        }
        catch DrawStore.StoreError.read(_) { dayRefreshFailed = true }
        catch { saveFailed = true }
    }

    func showToday(_ draw: DailyDraw) {
        do {
            guard try !updateDay() else { return }
            screen = .today(draw)
        } catch { dayRefreshFailed = true }
    }

    func refreshDay() {
        do {
            _ = try updateDay()
            if dayRefreshFailed { dayRefreshFailed = false }
        }
        catch { dayRefreshFailed = true }
    }

    @discardableResult
    private func updateDay() throws -> Bool {
        let now = clock.now
        let zone = clock.timeZone
        let key = ReadingEngine.dateKey(for: now, timeZone: zone)
        // A same-date foreground or time-zone event must leave the current ritual untouched.
        guard key != dateKey else { return false }
        let saved = try store.draw(for: key)
        today = saved
        screen = saved.map(Screen.today) ?? .draw
        dateKey = key
        saveFailed = false
        date = now
        timeZone = zone
        return true
    }

    var suggestions: [String] { library.questions.content(for: area).suggestions }
    var canSubmit: Bool { ReadingEngine.canSubmit(question: question) }

    func goToToday() {
        screen = today.map(Screen.today) ?? .draw
    }

    func openComposer(question: String = "") {
        self.question = question
        picks = []
        pendingReading = nil
        screen = .composer
    }

    func submitQuestion() {
        guard canSubmit else { return }
        question = question.trimmingCharacters(in: .whitespacesAndNewlines)
        picks = []
        pendingReading = nil
        screen = .pick
    }

    func pickCard() {
        guard case .pick = screen,
              let pick = ReadingEngine.nextPick(after: picks, library: library, randomIndex: randomIndex) else { return }
        picks.append(pick)
    }

    func readSpread() {
        guard case .pick = screen, picks.count == 3 else { return }
        do {
            if pendingReading == nil {
                pendingReading = try ReadingEngine.compose(id: UUID(), createdAt: clock.now, area: area,
                                                          question: question, picks: picks, library: library)
            }
            guard let pendingReading else { return }
            screen = .reading(try store.save(pendingReading))
        } catch { readingSaveFailed = true }
    }

    #if DEBUG
    func openSavedReadingForTest() throws {
        if let reading = try store.latestReading() { screen = .reading(reading) }
    }
    #endif
}

// The only composition point. Test values never enter the reading engine through globals.
@MainActor
enum AppLaunch {
    static func makeSession(configuration: LaunchConfiguration) throws -> AppSession {
        #if DEBUG
        if configuration.forceStoreOpenFailure { throw CocoaError(.fileReadNoPermission) }
        #endif
        let modelConfiguration: ModelConfiguration
        if configuration.inMemory {
            modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        } else if let id = configuration.testStoreID {
            let directory = URL.applicationSupportDirectory.appending(path: "TestStores/\(id.uuidString)")
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            modelConfiguration = ModelConfiguration(url: directory.appending(path: "draws.store"), cloudKitDatabase: .none)
        } else {
            try FileManager.default.createDirectory(at: .applicationSupportDirectory, withIntermediateDirectories: true)
            modelConfiguration = ModelConfiguration(cloudKitDatabase: .none)
        }
        var library = try CardLibrary.load()
        #if DEBUG
        if configuration.revisedContent {
            let meaning = CardMeaning(keywords: ["Revised", "test", "content"], interpretation: "A revised library. For snapshot testing only.",
                                      daily: try DailyContent(colourName: "Clay", colourHex: "#b0654a", object: "A test bookmark", bestHour: "After 6 pm",
                                                              career: AreaReading(score: 10, line: "Revised work line."),
                                                              relationship: AreaReading(score: 20, line: "Revised connection line."),
                                                              social: AreaReading(score: 30, line: "Revised social line.")))
            library = CardLibrary(version: library.version + 1, editorialStatus: library.editorialStatus,
                                  cards: library.cards.map {
                var upright = meaning
                upright.questionPositions = $0.upright.questionPositions
                var reversed = meaning
                reversed.questionPositions = $0.reversed.questionPositions
                return TarotCard(id: $0.id, name: "Revised \($0.name)", arcana: $0.arcana, suit: $0.suit, rank: $0.rank,
                                 upright: upright, reversed: reversed)
            }, questions: library.questions)
        }
        #endif
        let store = try DrawStore(configuration: modelConfiguration)
        var randomness = SystemRandomNumberGenerator()
        let seed = try store.installSeed {
            configuration.seed ?? (0..<4).map { _ in String(randomness.next(), radix: 16) }.joined(separator: "-")
        }
        let clock = SessionClock(configuration: configuration)
        var testIndex = 0
        let randomIndex: (Int) -> Int = { upperBound in
            #if DEBUG
            if !configuration.randomIndices.isEmpty {
                let value = configuration.randomIndices[testIndex % configuration.randomIndices.count]
                testIndex += 1
                return value % upperBound
            }
            #endif
            return Int.random(in: 0..<upperBound, using: &randomness)
        }
        #if DEBUG
        if configuration.earlierSnapshot {
            let draw = ReadingEngine.dailyDraw(seed: seed, dateKey: ReadingEngine.dateKey(for: clock.now, timeZone: clock.timeZone),
                                              position: 3, library: library)
            let card = draw.card
            let earlierCard = TarotCard(id: card.id, name: card.name, arcana: card.arcana, suit: card.suit, rank: card.rank,
                                        upright: CardMeaning(keywords: card.upright.keywords, interpretation: card.upright.interpretation, daily: nil),
                                        reversed: CardMeaning(keywords: card.reversed.keywords, interpretation: card.reversed.interpretation, daily: nil))
            _ = try store.save(DailyDraw(dateKey: draw.dateKey, position: draw.position, orientation: draw.orientation,
                                        card: earlierCard, contentVersion: 1))
        }
        #endif
        let session = try AppSession(clock: clock, seed: seed, store: store,
                                     library: library, randomIndex: randomIndex)
        #if DEBUG
        if configuration.openSavedReading { try session.openSavedReadingForTest() }
        #endif
        return session
    }
}
