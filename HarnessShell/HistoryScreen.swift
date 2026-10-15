import SwiftUI

struct HistoryScreen: View {
    let session: AppSession
    let animationsEnabled: Bool
    let testMode: Bool
    @State private var entries: [HistoryEntry] = []
    @State private var failed = false
    @State private var filter: ReadingArea?
    @State private var month: HistoryMonth
    @State private var opened: HistoryEntry?
    @Environment(\.dynamicTypeSize) private var textSize

    init(session: AppSession, animationsEnabled: Bool, testMode: Bool) {
        self.session = session
        self.animationsEnabled = animationsEnabled
        self.testMode = testMode
        _month = State(initialValue: HistoryMonth(dateKey: session.dateKey))
    }

    private var filtered: [HistoryEntry] { entries.filter { $0.matches(area: filter) } }
    private var drawnKeys: Set<String> {
        Set(entries.compactMap { if case .daily(let draw) = $0 { draw.dateKey } else { nil } })
    }

    var body: some View {
        let visibleEntries = filtered
        ZStack {
            if failed {
                ReadingScreenLayout {
                    VStack(alignment: .leading, spacing: Design.Space.section) {
                        Text("Your cards").typeRole(Design.TypeRole.title).accessibilityIdentifier("history-title")
                        message(title: "History could not be opened", text: "Your saved cards and readings are unchanged.")
                    }
                    .foregroundStyle(Design.Palette.ink)
                    .padding(.horizontal, Design.Space.page)
                    .padding(.vertical, Design.Space.page)
                } footer: {
                    PrimaryAction(title: "Try again", action: reload).accessibilityIdentifier("history-retry")
                }
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: Design.Space.section) {
                        Text("Your cards").typeRole(Design.TypeRole.title).accessibilityIdentifier("history-title")
                        HistoryCalendar(month: month, today: session.dateKey, drawnKeys: drawnKeys) {
                            month = month.moving($0)
                        }
                        HistoryFilters(selection: $filter)
                        if visibleEntries.isEmpty {
                            message(title: filter.map { "No \($0.rawValue) readings yet" } ?? "Your story starts here",
                                    text: filter.map { "Your \($0.rawValue) question readings will appear here, ready to revisit." }
                                        ?? "Your daily cards and question readings will build up here, ready to revisit whenever you like.")
                        } else {
                            // Retain row accessibility nodes while Dynamic Type reflows the calendar above them.
                            VStack(spacing: 0) {
                                ForEach(visibleEntries) { entry in
                                    HistoryRow(entry: entry, dateLabel: entryDate(entry)) { opened = entry }
                                    if entry.id != visibleEntries.last?.id {
                                        Divider().overlay(Design.Palette.surfaceHairline)
                                            .padding(.horizontal, Design.Space.group)
                                    }
                                }
                            }
                            .modifier(HistoryListSurface())
                        }
                    }
                    .foregroundStyle(Design.Palette.ink)
                    .padding(.horizontal, Design.Space.page)
                    .padding(.top, Design.Space.page)
                    .padding(.bottom, Design.Space.large)
                }
                .accessibilityIdentifier("screen-content")
                .clipped()
                .background { ScreenGround() }
            }
        }
        .preferredColorScheme(.light)
        .onAppear(perform: reload)
        .onChange(of: session.historyRevision) { _, _ in reload() }
        .fullScreenCover(item: $opened) { entry in
            Group {
                switch entry {
                case .daily(let draw):
                    TodayScreen(draw: draw, dateLabel: HistoryMonth.label(for: draw.dateKey),
                                animationsEnabled: animationsEnabled, testMode: testMode, ask: {},
                                backToHistory: { opened = nil })
                        .safeAreaInset(edge: .bottom, spacing: 0) {
                            RestingTabBar(selection: "History", today: {
                                opened = nil
                                session.goToToday()
                            }, ask: {
                                opened = nil
                                session.screen = .ask
                            }, history: { opened = nil })
                        }
                case .reading(let reading):
                    QuestionReadingScreen(reading: reading) { opened = nil }
                }
            }
            .environment(\.dynamicTypeSize, textSize)
        }
    }

    private func reload() {
        do { entries = try session.historyEntries(); failed = false }
        catch { failed = true }
    }

    private func entryDate(_ entry: HistoryEntry) -> String {
        let key = entry.dateKey(timeZone: session.clock.timeZone)
        if key == session.dateKey { return "Today" }
        return HistoryMonth.label(for: key, format: "d MMMM yyyy")
    }

    private func message(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: Design.Space.small) {
            Text(title).typeRole(.section).accessibilityIdentifier("history-message")
            Text(text).typeRole(Design.TypeRole.body).foregroundStyle(Design.Palette.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("history-message-body")
        }
    }
}

struct HistoryCalendar: View {
    let month: HistoryMonth
    let today: String
    let drawnKeys: Set<String>
    let move: (Int) -> Void
    @Environment(\.dynamicTypeSize) private var textSize

    var body: some View {
        VStack(spacing: Design.Space.group) {
            HStack(spacing: Design.Space.small) {
                HistoryMonthAction(forward: false) { move(-1) }
                VStack(spacing: 0) {
                    Text(month.title).typeRole(.section).accessibilityIdentifier("history-month")
                    let count = month.keys.filter { drawnKeys.contains($0) }.count
                    Text("\(count) \(count == 1 ? "card" : "cards") drawn")
                        .typeRole(Design.TypeRole.secondary).foregroundStyle(Design.Palette.secondary)
                        .accessibilityIdentifier("history-month-count")
                }
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                HistoryMonthAction(forward: true) { move(1) }
            }
            if textSize.isAccessibilitySize {
                VStack(spacing: Design.Space.small) {
                    ForEach(month.keys, id: \.self) { key in
                        HistoryCalendarDay(key: key, today: today, drawn: drawnKeys.contains(key), expanded: true)
                    }
                }
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                    ForEach(Array(["M", "T", "W", "T", "F", "S", "S"].enumerated()), id: \.offset) { _, day in
                        Text(day).typeRole(.label).foregroundStyle(Design.Palette.secondary)
                            .frame(minHeight: 24).accessibilityHidden(true)
                    }
                    ForEach(0..<month.leadingBlanks, id: \.self) { _ in
                        Spacer().frame(height: Design.Space.target).accessibilityHidden(true)
                    }
                    ForEach(month.keys, id: \.self) { key in
                        HistoryCalendarDay(key: key, today: today, drawn: drawnKeys.contains(key))
                    }
                }
            }
        }
    }
}
