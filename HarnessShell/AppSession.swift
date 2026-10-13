import Foundation
import Observation
import SwiftData

struct LaunchConfiguration {
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

    static func current() -> LaunchConfiguration {
        var result = LaunchConfiguration()
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        guard arguments.contains("--test-mode") else { return result }
        result.testMode = true
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
        case draw, reveal(DailyDraw), today(DailyDraw)
    }

    var screen: Screen = .draw
    var saveFailed = false
    var dayRefreshFailed = false
    private(set) var date: Date
    private(set) var timeZone: TimeZone
    private(set) var dateKey: String
    let clock: SessionClock
    private let seed: String
    private let store: DrawStore
    private let library: CardLibrary

    init(clock: SessionClock, seed: String, store: DrawStore, library: CardLibrary) throws {
        self.clock = clock
        let now = clock.now
        let zone = clock.timeZone
        date = now
        timeZone = zone
        dateKey = ReadingEngine.dateKey(for: now, timeZone: zone)
        self.seed = seed
        self.store = store
        self.library = library
        if let saved = try store.draw(for: dateKey) { screen = .today(saved) }
    }

    var dateLabel: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_AU")
        formatter.timeZone = timeZone
        formatter.dateFormat = "EEEE d MMMM"
        return formatter.string(from: date)
    }

    func turnOver(position: Int) {
        do {
            // A tap at midnight must not carry yesterday's selection into the new day.
            guard try !updateDay() else { return }
            if let saved = try store.draw(for: dateKey) { screen = .today(saved); return }
            let previous = try store.draws(from: ReadingEngine.repeatWindowStart(for: dateKey), before: dateKey)
            let draw = ReadingEngine.dailyDraw(seed: seed, dateKey: dateKey, position: position,
                                              library: library, previousDraws: previous)
            screen = .reveal(try store.save(draw))
        } catch { saveFailed = true }
    }

    func showToday(_ draw: DailyDraw) {
        do {
            guard try !updateDay() else { return }
            screen = .today(draw)
        } catch { dayRefreshFailed = true }
    }

    func refreshDay() {
        do { _ = try updateDay(); dayRefreshFailed = false }
        catch { dayRefreshFailed = true }
    }

    @discardableResult
    private func updateDay() throws -> Bool {
        let now = clock.now
        let zone = clock.timeZone
        let key = ReadingEngine.dateKey(for: now, timeZone: zone)
        let changed = key != dateKey
        if changed {
            let saved = try store.draw(for: key)
            screen = saved.map(Screen.today) ?? .draw
            dateKey = key
            saveFailed = false
        }
        date = now
        timeZone = zone
        return changed
    }
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
        let library = try CardLibrary.load()
        let store = try DrawStore(configuration: modelConfiguration)
        var randomness = SystemRandomNumberGenerator()
        let seed = try store.installSeed {
            configuration.seed ?? (0..<4).map { _ in String(randomness.next(), radix: 16) }.joined(separator: "-")
        }
        return try AppSession(clock: SessionClock(configuration: configuration), seed: seed, store: store, library: library)
    }
}
