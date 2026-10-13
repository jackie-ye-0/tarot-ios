import Foundation
import Observation
import SwiftData

struct LaunchConfiguration {
    var fixedDate: Date?
    var timeZone = TimeZone.current
    var seed: String?
    var inMemory = false
    var testStoreID: UUID?
    var largestText = false
    var reduceMotion = false

    static func current() -> LaunchConfiguration {
        var result = LaunchConfiguration()
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        guard arguments.contains("--test-mode") else { return result }
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
        #endif
        return result
    }
}

@MainActor @Observable
final class AppSession {
    enum Screen {
        case draw, reveal(DailyDraw), today(DailyDraw)
    }

    var screen: Screen = .draw
    var saveFailed = false
    let date: Date
    let timeZone: TimeZone
    private let dateKey: String
    private let seed: String
    private let store: DrawStore
    private let library: CardLibrary

    init(clock: () -> Date, timeZone: TimeZone, seed: String, store: DrawStore, library: CardLibrary) throws {
        date = clock()
        self.timeZone = timeZone
        dateKey = ReadingEngine.dateKey(for: date, timeZone: timeZone)
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
            let draw = ReadingEngine.dailyDraw(seed: seed, dateKey: dateKey, position: position, library: library)
            screen = .reveal(try store.save(draw))
        } catch { saveFailed = true }
    }
}

// The only composition point. Test values never enter the reading engine through globals.
@MainActor
enum AppLaunch {
    static func makeSession(configuration: LaunchConfiguration) throws -> AppSession {
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
        let clock: () -> Date = { configuration.fixedDate ?? Date() }
        return try AppSession(clock: clock, timeZone: configuration.timeZone, seed: seed, store: store, library: library)
    }
}
