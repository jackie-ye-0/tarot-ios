import Foundation
import SwiftData

@Model
final class InstallIdentity {
    @Attribute(.unique) var key: String
    var seed: String
    var welcomeCompleted: Bool = false

    init(seed: String) {
        key = "installation"
        self.seed = seed
    }
}

@Model
final class StoredDailyDraw {
    @Attribute(.unique) var dateKey: String
    var snapshot: Data

    init(_ draw: DailyDraw) throws {
        dateKey = draw.dateKey
        snapshot = try JSONEncoder().encode(draw)
    }
}

@MainActor
final class DrawStore {
    enum StoreError: Error {
        case read(any Error)
        case save(any Error)
    }

    private let container: ModelContainer
    private var context: ModelContext { container.mainContext }
    #if DEBUG
    var failsNextWelcomeSave = false
    #endif

    init(configuration: ModelConfiguration) throws {
        container = try ModelContainer(for: InstallIdentity.self, StoredDailyDraw.self, StoredQuestionReading.self,
                                       configurations: configuration)
        context.autosaveEnabled = false
    }

    func installSeed(create: () -> String) throws -> String {
        if let identity = try context.fetch(FetchDescriptor<InstallIdentity>()).first {
            return identity.seed
        }
        let seed = create()
        context.insert(InstallIdentity(seed: seed))
        do { try context.save() } catch { context.rollback(); throw error }
        return seed
    }

    func draw(for dateKey: String) throws -> DailyDraw? {
        do {
            let request = FetchDescriptor<StoredDailyDraw>(predicate: #Predicate { $0.dateKey == dateKey })
            return try context.fetch(request).first.map { try JSONDecoder().decode(DailyDraw.self, from: $0.snapshot) }
        } catch { throw StoreError.read(error) }
    }

    func hasCompletedWelcome() throws -> Bool {
        try context.fetch(FetchDescriptor<InstallIdentity>()).first?.welcomeCompleted ?? false
    }

    func completeWelcome() throws {
        #if DEBUG
        // One failure only, so a test can also follow the retry that the alert promises.
        if failsNextWelcomeSave {
            failsNextWelcomeSave = false
            throw CocoaError(.fileWriteOutOfSpace)
        }
        #endif
        guard let identity = try context.fetch(FetchDescriptor<InstallIdentity>()).first else {
            throw CocoaError(.fileReadCorruptFile)
        }
        identity.welcomeCompleted = true
        do { try context.save() } catch { context.rollback(); throw error }
    }

    func save(_ draw: DailyDraw) throws -> DailyDraw {
        if let saved = try self.draw(for: draw.dateKey) { return saved }
        do {
            context.insert(try StoredDailyDraw(draw))
            try context.save()
            return draw
        } catch {
            context.rollback()
            throw StoreError.save(error)
        }
    }

    func draws(from start: String) throws -> [DailyDraw] {
        do {
            let request = FetchDescriptor<StoredDailyDraw>(predicate: #Predicate { $0.dateKey >= start })
            return try context.fetch(request).map { try JSONDecoder().decode(DailyDraw.self, from: $0.snapshot) }
        } catch { throw StoreError.read(error) }
    }

    func save(_ reading: QuestionReading) throws -> QuestionReading {
        let id = reading.id
        let request = FetchDescriptor<StoredQuestionReading>(predicate: #Predicate { $0.id == id })
        if let saved = try context.fetch(request).first {
            return try JSONDecoder().decode(QuestionReading.self, from: saved.snapshot)
        }
        context.insert(try StoredQuestionReading(reading))
        do { try context.save() } catch { context.rollback(); throw error }
        return reading
    }

    func latestReading() throws -> QuestionReading? {
        var request = FetchDescriptor<StoredQuestionReading>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        request.fetchLimit = 1
        return try context.fetch(request).first.map { try JSONDecoder().decode(QuestionReading.self, from: $0.snapshot) }
    }
}

@Model
final class StoredQuestionReading {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var snapshot: Data

    init(_ reading: QuestionReading) throws {
        id = reading.id
        createdAt = reading.createdAt
        snapshot = try JSONEncoder().encode(reading)
    }
}
