import Foundation
import SwiftData

@Model
final class InstallIdentity {
    @Attribute(.unique) var key: String
    var seed: String
    var welcomeCompleted: Bool?

    init(seed: String, welcomeCompleted: Bool?) {
        key = "installation"
        self.seed = seed
        self.welcomeCompleted = welcomeCompleted
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
    var failsNextWelcomeRead = false
    var failsNextWelcomeSave = false
    var failsNextSpreadSave = false
    #endif

    init(configuration: ModelConfiguration) throws {
        container = try ModelContainer(for: InstallIdentity.self, StoredDailyDraw.self, StoredQuestionReading.self, StoredSpreadDraft.self,
                                       configurations: configuration)
        context.autosaveEnabled = false
    }

    func installSeed(create: () -> String) throws -> String {
        if let identity = try context.fetch(FetchDescriptor<InstallIdentity>()).first {
            return identity.seed
        }
        let seed = create()
        context.insert(InstallIdentity(seed: seed, welcomeCompleted: false))
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
        #if DEBUG
        // One failure only, so a test can also follow the storage-failure retry.
        if failsNextWelcomeRead {
            failsNextWelcomeRead = false
            throw StoreError.read(CocoaError(.fileReadCorruptFile))
        }
        #endif
        guard let identity = try context.fetch(FetchDescriptor<InstallIdentity>()).first else { return false }
        return identity.welcomeCompleted ?? true
    }

    func completeWelcome() throws {
        #if DEBUG
        // One failure only, so a test can also follow the retry that the alert promises.
        if failsNextWelcomeSave {
            failsNextWelcomeSave = false
            throw StoreError.save(CocoaError(.fileWriteOutOfSpace))
        }
        #endif
        let identity: InstallIdentity?
        do { identity = try context.fetch(FetchDescriptor<InstallIdentity>()).first } catch { throw StoreError.read(error) }
        guard let identity else { throw StoreError.read(CocoaError(.fileReadCorruptFile)) }
        identity.welcomeCompleted = true
        do { try context.save() } catch { context.rollback(); throw StoreError.save(error) }
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
        do {
            let existing = try context.fetch(request).first
            let saved = try existing.map { try JSONDecoder().decode(QuestionReading.self, from: $0.snapshot) } ?? reading
            if existing == nil { context.insert(try StoredQuestionReading(reading)) }
            for draft in try context.fetch(FetchDescriptor<StoredSpreadDraft>()) { context.delete(draft) }
            try context.save()
            return saved
        } catch {
            context.rollback()
            throw error
        }
    }

    func spreadDraft() throws -> SpreadDraft? {
        guard let stored = try context.fetch(FetchDescriptor<StoredSpreadDraft>()).first else { return nil }
        let draft = try JSONDecoder().decode(SpreadDraft.self, from: stored.snapshot)
        try draft.validate()
        return draft
    }

    func saveSpreadDraft(_ draft: SpreadDraft?) throws {
        #if DEBUG
        if failsNextSpreadSave {
            failsNextSpreadSave = false
            throw StoreError.save(CocoaError(.fileWriteOutOfSpace))
        }
        #endif
        do {
            try draft?.validate()
            let stored = try context.fetch(FetchDescriptor<StoredSpreadDraft>()).first
            if let draft {
                let snapshot = try JSONEncoder().encode(draft)
                if let stored { stored.snapshot = snapshot }
                else { context.insert(StoredSpreadDraft(snapshot: snapshot)) }
            } else if let stored { context.delete(stored) }
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
    }

    func latestReading() throws -> QuestionReading? {
        var request = FetchDescriptor<StoredQuestionReading>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        request.fetchLimit = 1
        return try context.fetch(request).first.map { try JSONDecoder().decode(QuestionReading.self, from: $0.snapshot) }
    }
}

@Model
final class StoredSpreadDraft {
    @Attribute(.unique) var key: String
    var snapshot: Data

    init(snapshot: Data) {
        key = "spread"
        self.snapshot = snapshot
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
