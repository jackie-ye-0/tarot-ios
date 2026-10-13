import Foundation
import SwiftData

@Model
final class InstallIdentity {
    @Attribute(.unique) var key: String
    var seed: String

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
    private let container: ModelContainer
    private var context: ModelContext { container.mainContext }

    init(configuration: ModelConfiguration) throws {
        container = try ModelContainer(for: InstallIdentity.self, StoredDailyDraw.self,
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
        let request = FetchDescriptor<StoredDailyDraw>(predicate: #Predicate { $0.dateKey == dateKey })
        return try context.fetch(request).first.map { try JSONDecoder().decode(DailyDraw.self, from: $0.snapshot) }
    }

    func save(_ draw: DailyDraw) throws -> DailyDraw {
        if let saved = try self.draw(for: draw.dateKey) { return saved }
        context.insert(try StoredDailyDraw(draw))
        do { try context.save() } catch { context.rollback(); throw error }
        return draw
    }
}
