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
    var revisedContent = false
    var earlierSnapshot = false
    var cardFaceProof = false
    var cardSizeProof = false
    var randomIndices: [Int] = []
    var openSavedReading = false
    var welcomeCompleted = false
    var welcomeSaveFailure = false
    var spreadSaveFailure = false
    var readingUpdateFailure = false
    var readingDeleteFailure = false
    var crisisDiscardFailure = false
    var settingsSaveFailure = false
    var historyDays = 0
    var historyReadFailure = false
    var reminderInvitationAnswered = false
    var reminderSaveFailure = false
    var notificationFixture: String?
    var deleteAllFailure = false
    var exportFailure = false

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
        result.revisedContent = arguments.contains("--test-revised-content")
        result.earlierSnapshot = arguments.contains("--test-earlier-snapshot")
        result.cardFaceProof = arguments.contains("--test-card-faces")
        result.cardSizeProof = arguments.contains("--test-card-sizes")
        result.randomIndices = value("--test-random-indices")?.split(separator: ",").compactMap { Int($0) }.filter { $0 >= 0 } ?? []
        result.openSavedReading = arguments.contains("--test-open-saved-reading")
        result.welcomeCompleted = arguments.contains("--test-welcome-completed")
        result.welcomeSaveFailure = arguments.contains("--test-welcome-save-failure")
        result.spreadSaveFailure = arguments.contains("--test-spread-save-failure")
        result.readingUpdateFailure = arguments.contains("--test-reading-update-failure")
        result.readingDeleteFailure = arguments.contains("--test-reading-delete-failure")
        result.crisisDiscardFailure = arguments.contains("--test-crisis-discard-failure")
        result.settingsSaveFailure = arguments.contains("--test-settings-save-failure")
        result.historyDays = min(1000, max(0, value("--test-history-days").flatMap(Int.init) ?? 0))
        result.historyReadFailure = arguments.contains("--test-history-read-failure")
        result.reminderInvitationAnswered = arguments.contains("--test-reminder-answered")
        result.reminderSaveFailure = arguments.contains("--test-reminder-save-failure")
        result.notificationFixture = arguments.contains("--test-real-notifications") ? nil
            : (value("--test-notification-permission") ?? "allow")
        result.deleteAllFailure = arguments.contains("--test-delete-all-failure")
        result.exportFailure = arguments.contains("--test-export-failure")
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
        case welcome, draw, reveal(DailyDraw), today(DailyDraw), ask, composer, aboutSomeone, pick, reading(QuestionReading), support, history
    }

    private enum DraftSaveOperation {
        case persistQuestion, persistSpread, discard
    }

    var screen: Screen = .draw
    var saveFailed = false
    var dayRefreshFailed = false
    var readingSaveFailed = false
    var welcomeSaveFailed = false
    var draftSaveFailed = false
    var relationshipSaveFailed = false
    private(set) var crisisRemovalFailed = false
    var showsSettings = false
    var settingsSaveFailed = false
    var reminderSaveFailed = false
    private(set) var reminderFailureMessage = ""
    private(set) var reminderBusy = false
    private(set) var reminderDenied = false
    private(set) var reminderInvitationDenied = false
    private var reminderScheduled = false
    private(set) var reminderPreference: ReminderPreference
    private let notifications: ReminderNotifications
    #if DEBUG
    private(set) var reminderTestState = ""
    #endif
    private(set) var hiddenAreas: Set<ReadingArea> = []
    var area: ReadingArea = .relationship { didSet { persistDraft(); persistSpreadDraft() } }
    var question = "" { didSet { persistDraft(); persistSpreadDraft() } }
    var person: NamedPerson? { didSet { persistDraft(); persistSpreadDraft() } }
    private(set) var hasDraft = false
    private(set) var relationshipStatus: RelationshipStatus?
    private(set) var relationshipStatusAsked = false
    private var latestReadings: [ReadingArea: QuestionReading] = [:]
    private var failedDraftSaveOperation: DraftSaveOperation?
    private(set) var picks: [SpreadPick] = []
    private var hasSpreadDraft = false
    private var draftIsPicking = true
    private var pendingReading: QuestionReading?
    private var today: DailyDraw?
    private(set) var date: Date
    private(set) var timeZone: TimeZone
    private(set) var dateKey: String
    let clock: SessionClock
    private var seed: String?
    private let store: DrawStore
    private let library: CardLibrary
    private let randomIndex: (Int) -> Int
    private let createSeed: () -> String

    init(clock: SessionClock, seed: String, store: DrawStore, library: CardLibrary,
         randomIndex: @escaping (Int) -> Int, notifications: ReminderNotifications? = nil,
         createSeed: @escaping () -> String = { UUID().uuidString }) throws {
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
        self.createSeed = createSeed
        self.notifications = notifications ?? ReminderNotifications()
        reminderPreference = try store.reminderPreference()
        let originalPreference = reminderPreference
        reminderPreference.expireInvitation(on: dateKey)
        if reminderPreference != originalPreference { try store.saveReminderPreference(reminderPreference) }
        if let draft = try store.spreadDraft() {
            area = draft.area
            question = draft.question
            person = draft.person
            picks = draft.picks
            draftIsPicking = draft.isPicking
            hasSpreadDraft = true
        }
        screen = try launchScreen()
        hiddenAreas = try store.hiddenAreas()
        if hiddenAreas.contains(area), let first = visibleAreas.first { area = first }
        // An interrupted removal must never restore a matching draft into the pick.
        if ReadingEngine.requiresSupport(question: question, note: person?.note ?? "", content: library.crisis) { showSupport() }
    }

    /// Welcome until it is completed, then Today once today's card is drawn, otherwise Draw.
    private func launchScreen() throws -> Screen {
        if try !store.hasCompletedWelcome() { return .welcome }
        today = try store.draw(for: dateKey)
        latestReadings = try store.latestReadingsByArea()
        if let preference = try store.relationshipPreference() {
            relationshipStatusAsked = true
            relationshipStatus = preference.status.flatMap(RelationshipStatus.init(rawValue:))
        }
        if !hasSpreadDraft, let draft = try store.questionDraft() {
            area = draft.area
            question = draft.question
            person = draft.person
            hasDraft = true
        }
        return today.map(Screen.today) ?? .draw
    }

    var historyRevision: Int { store.historyRevision }

    func historyEntries() throws -> [HistoryEntry] {
        #if DEBUG
        if failHistoryRead {
            failHistoryRead = false
            throw CocoaError(.fileReadNoPermission)
        }
        #endif
        return try store.history(timeZone: clock.timeZone)
    }

    var dateLabel: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_AU")
        formatter.timeZone = timeZone
        formatter.dateFormat = "EEEE d MMMM"
        return formatter.string(from: date)
    }

    /// A read failure throws for the caller's storage-failure screen; Welcome is saved by then, so its retry routes past it.
    func completeWelcome() throws {
        do {
            // A deletion leaves no identity until the user starts again.
            if seed == nil { seed = try store.installSeed(create: createSeed) }
            try store.completeWelcome()
        }
        catch DrawStore.StoreError.save(_) {
            welcomeSaveFailed = true
            return
        }
        try updateDay()
        screen = try launchScreen()
    }

    func turnOver(position: Int) {
        guard let seed else { return }
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
                                           library: library, previousDraws: previous, createdAt: clock.now)
        } catch {
            dayRefreshFailed = true
            return
        }
        do {
            let saved = try store.save(draw)
            today = saved
            if reminderPreference.firstDrawDateKey == nil { reminderPreference.firstDrawDateKey = saved.dateKey }
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
        var preference = reminderPreference
        preference.expireInvitation(on: key)
        if preference != reminderPreference {
            try store.saveReminderPreference(preference)
            reminderPreference = preference
        }
        today = saved
        // The disclaimer must remain in place until the welcome action is taken.
        switch screen {
        case .welcome, .support: break
        default: screen = saved.map(Screen.today) ?? .draw
        }
        dateKey = key
        reminderInvitationDenied = false
        saveFailed = false
        date = now
        timeZone = zone
        return true
    }

    var crisisContent: CrisisContent { library.crisis }
    var suggestions: [String] { library.questions.content(for: area).suggestions }
    var canSubmit: Bool { person.map(\.isComplete) ?? ReadingEngine.canSubmit(question: question) }
    var readingType: ReadingType { person == nil ? .question : .namedPerson }
    var spreadTitle: String { person.map { "You and \($0.displayName)" } ?? question }
    private var composerScreen: Screen { person == nil ? .composer : .aboutSomeone }
    // Visibility changes the Ask selection, never the type or area of a named-person draft.
    private var draftArea: ReadingArea { person == nil ? area : .relationship }
    var todayAreaReading: AreaReading? { today?.meaning.daily?.reading(for: area) }
    var todayCardName: String? { today?.card.name }
    var latestReading: QuestionReading? { latestReadings[area] }
    var visibleAreas: [ReadingArea] { ReadingArea.allCases.filter { !hiddenAreas.contains($0) } }

    func setArea(_ area: ReadingArea, visible: Bool) {
        let hidden = ReadingEngine.settingVisibility(visible, for: area, hiddenAreas: hiddenAreas)
        guard hidden != hiddenAreas else { return }
        do {
            try store.saveHiddenAreas(hidden)
            hiddenAreas = hidden
            if hidden.contains(self.area), let first = visibleAreas.first { self.area = first }
        } catch { settingsSaveFailed = true }
    }

    var showsReminderInvitation: Bool {
        reminderPreference.shouldInvite(on: dateKey, hasDraw: today != nil)
    }

    var reminderEnabled: Bool { reminderPreference.enabled && reminderScheduled && !reminderDenied }

    var reminderEvidence: String? {
        #if DEBUG
        return reminderTestState.isEmpty ? nil : reminderTestState
        #else
        return nil
        #endif
    }

    func dismissReminderInvitation() {
        guard !reminderBusy else { return }
        do {
            var preference = reminderPreference
            preference.invitationAnswered = true
            try store.saveReminderPreference(preference)
            reminderPreference = preference
        } catch {
            reminderFailureMessage = "Try your reminder choice again."
            reminderSaveFailed = true
        }
    }

    func setReminderEnabled(_ enabled: Bool) async {
        guard !reminderBusy else { return }
        let wasInvitation = showsReminderInvitation
        reminderBusy = true
        defer { finishReminderOperation() }
        do {
            // Save the answer before asking; denial or a scheduling error must not ask again.
            var preference = reminderPreference
            preference.invitationAnswered = true
            if !enabled { preference.enabled = false }
            try store.saveReminderPreference(preference)
            reminderPreference = preference
            if !enabled {
                notifications.cancel()
                reminderScheduled = false
                return
            }
            var permission = await notifications.permission()
            if permission == .notDetermined {
                permission = try await notifications.requestPermission() ? .allowed : .denied
            }
            reminderDenied = permission == .denied
            reminderInvitationDenied = wasInvitation && reminderDenied
            guard permission == .allowed else {
                notifications.cancel()
                reminderScheduled = false
                return
            }
            try await notifications.schedule()
            reminderScheduled = true
            preference.enabled = true
            do { try store.saveReminderPreference(preference) }
            catch { notifications.cancel(); reminderScheduled = false; throw error }
            reminderPreference = preference
        } catch {
            reminderFailureMessage = showsSettings
                ? "Try turning this reminder \(enabled ? "on" : "off") again."
                : "Try turning the reminder on in the app's Settings."
            reminderSaveFailed = true
        }
    }

    /// Reconcile on launch and foreground without ever asking for permission.
    func refreshReminder() async {
        guard !reminderBusy else { return }
        reminderBusy = true
        defer { finishReminderOperation() }
        let permission = await notifications.permission()
        reminderDenied = permission == .denied
        if !reminderDenied { reminderInvitationDenied = false }
        do {
            if reminderPreference.enabled && permission == .allowed {
                try await notifications.schedule()
                reminderScheduled = true
            } else {
                notifications.cancel()
                reminderScheduled = false
                if reminderPreference.enabled {
                    var preference = reminderPreference
                    preference.enabled = false
                    try store.saveReminderPreference(preference)
                    reminderPreference = preference
                }
            }
        } catch {
            notifications.cancel()
            reminderScheduled = false
            reminderFailureMessage = showsSettings
                ? "Try the reminder switch again."
                : "Try the reminder switch in the app's Settings."
            reminderSaveFailed = true
        }
    }

    private func finishReminderOperation() {
        reminderBusy = false
        #if DEBUG
        reminderTestState = notifications.testState
        #endif
    }

    func persistDraft() {
        guard hasDraft else { return }
        do {
            try store.saveDraft(QuestionDraft(area: draftArea, question: question, person: person))
            draftSaveFailed = false
            failedDraftSaveOperation = nil
        } catch {
            failedDraftSaveOperation = .persistQuestion
            draftSaveFailed = true
        }
    }

    func backToAsk() {
        do {
            try store.discardDrafts()
            hasDraft = false
            hasSpreadDraft = false
            draftSaveFailed = false
            failedDraftSaveOperation = nil
            question = ""
            person = nil
            picks = []
            pendingReading = nil
            screen = .ask
        } catch {
            failedDraftSaveOperation = .discard
            draftSaveFailed = true
        }
    }

    func retryDraftSave() {
        switch failedDraftSaveOperation {
        case .persistQuestion: persistDraft()
        case .persistSpread: persistSpreadDraft()
        case .discard: backToAsk()
        case nil: break
        }
    }

    func setRelationshipStatus(_ status: RelationshipStatus?) {
        do {
            try store.saveRelationshipStatus(status)
            relationshipStatus = status
            relationshipStatusAsked = true
        } catch {
            if showsSettings { settingsSaveFailed = true }
            else { relationshipSaveFailed = true }
        }
    }

    func goToToday() {
        screen = today.map(Screen.today) ?? .draw
    }

    func openComposer(question: String? = nil) {
        if person != nil { self.question = ""; person = nil }
        hasDraft = true
        if let question { self.question = question }
        else { persistDraft() }
        picks = []
        pendingReading = nil
        screen = .composer
    }

    func openAboutSomeone() {
        guard area == .relationship else { return }
        if person == nil { question = ""; person = NamedPerson() }
        hasDraft = true
        picks = []
        pendingReading = nil
        persistDraft()
        screen = .aboutSomeone
    }

    func openAsk() {
        screen = hasSpreadDraft ? (draftIsPicking ? .pick : composerScreen) : .ask
    }

    func backToComposer() {
        draftIsPicking = false
        persistSpreadDraft()
        screen = composerScreen
    }

    private func persistSpreadDraft() {
        guard hasSpreadDraft else { return }
        pendingReading = nil
        do {
            try store.saveSpreadDraft(SpreadDraft(area: draftArea, question: question, picks: picks, isPicking: draftIsPicking, person: person))
            draftSaveFailed = false
            failedDraftSaveOperation = nil
        } catch {
            failedDraftSaveOperation = .persistSpread
            draftSaveFailed = true
        }
    }

    func submitQuestion() {
        guard canSubmit else { return }
        if ReadingEngine.requiresSupport(question: spreadTitle, note: person?.note ?? "", content: library.crisis) {
            showSupport()
            return
        }
        question = spreadTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        if let name = person?.displayName { person?.name = name }
        if !hasSpreadDraft { picks = [] }
        pendingReading = nil
        hasSpreadDraft = true
        hasDraft = false
        draftIsPicking = true
        persistSpreadDraft()
        screen = .pick
    }

    private func showSupport() {
        // Stop autosaving before clearing memory; never echo or log the question.
        hasDraft = false
        hasSpreadDraft = false
        question = ""
        person = nil
        picks = []
        pendingReading = nil
        draftSaveFailed = false
        failedDraftSaveOperation = nil
        screen = .support
        removeCrisisDrafts()
    }

    func removeCrisisDrafts() {
        do {
            try store.discardDrafts()
            crisisRemovalFailed = false
        } catch { crisisRemovalFailed = true }
    }

    func leaveSupport() {
        guard !crisisRemovalFailed else { return }
        goToToday()
    }

    func pickCard() {
        guard case .pick = screen, !draftSaveFailed,
              let pick = ReadingEngine.nextPick(after: picks, library: library, type: readingType, randomIndex: randomIndex) else { return }
        picks.append(pick)
        persistSpreadDraft()
    }

    func readSpread() {
        guard case .pick = screen, picks.count == 3 else { return }
        do {
            if pendingReading == nil {
                pendingReading = try ReadingEngine.compose(id: UUID(), createdAt: clock.now, area: draftArea,
                                                          question: question, picks: picks, library: library,
                                                          relationshipStatus: relationshipStatus, person: person)
            }
            guard let pendingReading else { return }
            let saved = try store.save(pendingReading)
            latestReadings[saved.area] = saved
            hasDraft = false
            hasSpreadDraft = false
            draftSaveFailed = false
            question = ""
            person = nil
            screen = .reading(saved)
        } catch { readingSaveFailed = true }
    }

    func setReadingResponse(_ response: ReadingResponse?, id: UUID) throws -> QuestionReading {
        let saved = try store.updateReading(id: id) { $0.response = response }
        if latestReadings[saved.area]?.id == id { latestReadings[saved.area] = saved }
        return saved
    }

    func saveReadingNote(_ note: String, id: UUID) throws -> QuestionReading {
        let saved = try store.updateReading(id: id) {
            $0.note = note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : note
        }
        if latestReadings[saved.area]?.id == id { latestReadings[saved.area] = saved }
        return saved
    }

    func deleteReading(id: UUID) throws {
        latestReadings = try store.deleteReading(id: id)
        pendingReading = nil
        picks = []
    }

    func exportReadings() throws -> ReadingExport {
        #if DEBUG
        if failExport {
            failExport = false
            throw CocoaError(.fileWriteOutOfSpace)
        }
        #endif
        return try ReadingExport.prepare(text: ReadingEngine.exportText(entries: store.history(timeZone: clock.timeZone)))
    }

    func deleteAllData() throws {
        // An in-flight permission/scheduling operation must finish before its saved state can be removed.
        guard !reminderBusy else { throw CocoaError(.userCancelled) }
        try ReadingExport.removeTemporaryCopy()
        try store.deleteAllData()
        notifications.cancelForDataDeletion()
        reminderPreference = ReminderPreference()
        reminderScheduled = false
        reminderDenied = false
        reminderInvitationDenied = false
        reminderSaveFailed = false
        reminderFailureMessage = ""
        #if DEBUG
        reminderTestState = notifications.testState
        #endif
        // Disable draft observers before clearing their values, so deletion cannot recreate a draft.
        hasDraft = false
        hasSpreadDraft = false
        question = ""
        person = nil
        area = .relationship
        picks = []
        pendingReading = nil
        today = nil
        latestReadings = [:]
        relationshipStatus = nil
        relationshipStatusAsked = false
        hiddenAreas = []
        seed = nil
        failedDraftSaveOperation = nil
        draftIsPicking = true
        saveFailed = false
        dayRefreshFailed = false
        readingSaveFailed = false
        welcomeSaveFailed = false
        draftSaveFailed = false
        relationshipSaveFailed = false
        crisisRemovalFailed = false
        settingsSaveFailed = false
        showsSettings = false
        screen = .welcome
    }

    #if DEBUG
    var failHistoryRead = false
    var failExport = false

    func openSavedReadingForTest() throws {
        if let reading = try store.latestReading() { screen = .reading(reading) }
    }
    #endif
}

// The only composition point. Test values never enter the reading engine through globals.
@MainActor
enum AppLaunch {
    static func makeSession(configuration: LaunchConfiguration) throws -> AppSession {
        // Also remove an export left behind if the process was interrupted during sharing.
        try ReadingExport.removeTemporaryCopy()
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
                upright.questionPositions = QuestionPositionMeanings(situation: "Revised situation.", action: "Revised action.", outcome: "Revised outcome.")
                upright.namedPersonPositions = NamedPersonPositionMeanings(you: "Revised you.", them: "Revised them.", connection: "Revised connection.")
                var reversed = meaning
                reversed.questionPositions = upright.questionPositions
                reversed.namedPersonPositions = upright.namedPersonPositions
                return TarotCard(id: $0.id, name: "Revised \($0.name)", arcana: $0.arcana, suit: $0.suit, rank: $0.rank,
                                 upright: upright, reversed: reversed)
            }, questions: QuestionContent(career: library.questions.career, relationship: library.questions.relationship,
                                           social: library.questions.social, reflections: ["A revised reflection?"]), crisis: library.crisis)
        }
        #endif
        let store = try DrawStore(configuration: modelConfiguration)
        var randomness = SystemRandomNumberGenerator()
        let createSeed = {
            configuration.seed ?? (0..<4).map { _ in String(randomness.next(), radix: 16) }.joined(separator: "-")
        }
        let seed = try store.installSeed(create: createSeed)
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
        if configuration.testMode && configuration.welcomeCompleted { try store.completeWelcome() }
        store.failsNextWelcomeSave = configuration.welcomeSaveFailure
        store.failsNextSpreadSave = configuration.spreadSaveFailure
        store.failsNextReadingUpdate = configuration.readingUpdateFailure
        store.failsNextReadingDelete = configuration.readingDeleteFailure
        store.failsNextDraftDiscard = configuration.crisisDiscardFailure
        store.failsNextSettingsSave = configuration.settingsSaveFailure
        store.failsNextDeleteAll = configuration.deleteAllFailure
        if configuration.historyDays > 0 {
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = clock.timeZone
            for offset in 0..<configuration.historyDays {
                let date = calendar.date(byAdding: .day, value: -offset, to: clock.now)!
                _ = try store.save(ReadingEngine.dailyDraw(seed: seed,
                    dateKey: ReadingEngine.dateKey(for: date, timeZone: clock.timeZone), position: 3, library: library,
                    createdAt: date.addingTimeInterval(-3600)))
            }
            for (offset, area) in ReadingArea.allCases.enumerated() {
                let picks = zip(QuestionPosition.allCases, library.cards.prefix(3)).map {
                    SpreadPick(position: $0.0, card: $0.1, orientation: .upright)
                }
                let id = UUID(uuidString: "00000000-0000-0000-0000-00000000000\(offset + 1)")!
                let date = calendar.date(byAdding: .day, value: -offset * 8, to: clock.now)!
                _ = try store.save(ReadingEngine.compose(id: id, createdAt: date, area: area,
                    question: library.questions.content(for: area).suggestions[0], picks: picks, library: library))
            }
        }
        if configuration.reminderInvitationAnswered {
            var preference = try store.reminderPreference()
            preference.invitationAnswered = true
            try store.saveReminderPreference(preference)
        }
        store.failsNextReminderSave = configuration.reminderSaveFailure
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
        let notifications: ReminderNotifications
        #if DEBUG
        notifications = ReminderNotifications(fixture: configuration.notificationFixture)
        #else
        notifications = ReminderNotifications()
        #endif
        let session = try AppSession(clock: clock, seed: seed, store: store,
                                     library: library, randomIndex: randomIndex, notifications: notifications, createSeed: createSeed)
        #if DEBUG
        session.failHistoryRead = configuration.historyReadFailure
        session.failExport = configuration.exportFailure
        if configuration.openSavedReading { try session.openSavedReadingForTest() }
        #endif
        return session
    }
}
