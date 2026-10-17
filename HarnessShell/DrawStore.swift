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
    var failsNextDraftSave = false
    var failsNextDraftDiscard = false
    var failsNextReadingUpdate = false
    var failsNextReadingDelete = false
    #endif

    init(configuration: ModelConfiguration) throws {
        container = try ModelContainer(for: InstallIdentity.self, StoredDailyDraw.self, StoredQuestionReading.self, StoredSpreadDraft.self,
                                       StoredQuestionDraft.self, StoredRelationshipPreference.self,
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
            for draft in try context.fetch(FetchDescriptor<StoredQuestionDraft>()) { context.delete(draft) }
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

    func saveSpreadDraft(_ draft: SpreadDraft) throws {
        #if DEBUG
        if failsNextSpreadSave {
            failsNextSpreadSave = false
            throw StoreError.save(CocoaError(.fileWriteOutOfSpace))
        }
        #endif
        do {
            try draft.validate()
            let stored = try context.fetch(FetchDescriptor<StoredSpreadDraft>()).first
            let snapshot = try JSONEncoder().encode(draft)
            if let stored { stored.snapshot = snapshot }
            else { context.insert(StoredSpreadDraft(snapshot: snapshot)) }
            for questionDraft in try context.fetch(FetchDescriptor<StoredQuestionDraft>()) { context.delete(questionDraft) }
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

    func updateReading(id: UUID, edit: (inout QuestionReading) -> Void) throws -> QuestionReading {
        do {
            let request = FetchDescriptor<StoredQuestionReading>(predicate: #Predicate { $0.id == id })
            guard let stored = try context.fetch(request).first else { throw CocoaError(.fileNoSuchFile) }
            var reading = try JSONDecoder().decode(QuestionReading.self, from: stored.snapshot)
            edit(&reading)
            stored.snapshot = try JSONEncoder().encode(reading)
            #if DEBUG
            if failsNextReadingUpdate {
                failsNextReadingUpdate = false
                throw CocoaError(.fileWriteOutOfSpace)
            }
            #endif
            try context.save()
            return reading
        } catch {
            context.rollback()
            throw error
        }
    }

    func deleteReading(id: UUID) throws -> [ReadingArea: QuestionReading] {
        do {
            let remaining = try latestReadingsByArea(excluding: id)
            let request = FetchDescriptor<StoredQuestionReading>(predicate: #Predicate { $0.id == id })
            for stored in try context.fetch(request) { context.delete(stored) }
            #if DEBUG
            if failsNextReadingDelete {
                failsNextReadingDelete = false
                throw CocoaError(.fileWriteOutOfSpace)
            }
            #endif
            try context.save()
            return remaining
        } catch {
            context.rollback()
            throw error
        }
    }

    func latestReadingsByArea(excluding id: UUID? = nil) throws -> [ReadingArea: QuestionReading] {
        let request = FetchDescriptor<StoredQuestionReading>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        var latest: [ReadingArea: QuestionReading] = [:]
        for stored in try context.fetch(request) {
            if stored.id == id { continue }
            let reading = try JSONDecoder().decode(QuestionReading.self, from: stored.snapshot)
            if latest[reading.area] == nil { latest[reading.area] = reading }
            if latest.count == ReadingArea.allCases.count { break }
        }
        return latest
    }

    func questionDraft() throws -> QuestionDraft? {
        try context.fetch(FetchDescriptor<StoredQuestionDraft>()).first.map {
            try JSONDecoder().decode(QuestionDraft.self, from: $0.snapshot)
        }
    }

    func saveDraft(_ draft: QuestionDraft) throws {
        #if DEBUG
        if failsNextDraftSave {
            failsNextDraftSave = false
            throw StoreError.save(CocoaError(.fileWriteOutOfSpace))
        }
        #endif
        do {
            let saved = try context.fetch(FetchDescriptor<StoredQuestionDraft>()).first
            let data = try JSONEncoder().encode(draft)
            if let saved { saved.snapshot = data }
            else { context.insert(StoredQuestionDraft(snapshot: data)) }
            try context.save()
        } catch { context.rollback(); throw error }
    }

    func discardDrafts() throws {
        #if DEBUG
        if failsNextSpreadSave {
            failsNextSpreadSave = false
            throw StoreError.save(CocoaError(.fileWriteOutOfSpace))
        }
        if failsNextDraftSave {
            failsNextDraftSave = false
            throw StoreError.save(CocoaError(.fileWriteOutOfSpace))
        }
        #endif
        do {
            for draft in try context.fetch(FetchDescriptor<StoredSpreadDraft>()) { context.delete(draft) }
            for draft in try context.fetch(FetchDescriptor<StoredQuestionDraft>()) { context.delete(draft) }
            #if DEBUG
            if failsNextDraftDiscard {
                failsNextDraftDiscard = false
                throw CocoaError(.fileWriteOutOfSpace)
            }
            #endif
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
    }

    func relationshipPreference() throws -> StoredRelationshipPreference? {
        try context.fetch(FetchDescriptor<StoredRelationshipPreference>()).first
    }

    func saveRelationshipStatus(_ status: RelationshipStatus?) throws {
        do {
            if let saved = try relationshipPreference() { saved.status = status?.rawValue }
            else { context.insert(StoredRelationshipPreference(status: status)) }
            try context.save()
        } catch { context.rollback(); throw error }
    }
}

@Model
final class StoredQuestionDraft {
    @Attribute(.unique) var key: String
    var snapshot: Data

    init(snapshot: Data) {
        key = "question"
        self.snapshot = snapshot
    }
}

@Model
final class StoredRelationshipPreference {
    @Attribute(.unique) var key: String
    var status: String?

    init(status: RelationshipStatus?) {
        key = "relationship"
        self.status = status?.rawValue
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
