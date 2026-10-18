import SwiftUI

struct SettingsScreen: View {
    @Bindable var session: AppSession
    @State private var page: Page = .settings
    @State private var export: ReadingExport?
    @State private var exporting = false
    @State private var exportFailed = false
    @State private var confirmsDeletion = false
    @State private var deletionFailed = false

    private enum Page: String {
        case settings = "Settings"
        case relationship = "Relationship status"
        case about = "About these readings"
        case privacy = "Privacy"
    }

    var body: some View {
        ReadingScreenLayout {
            VStack(alignment: .leading, spacing: Design.Space.section) {
                NavigationAction {
                    if page == .settings { session.showsSettings = false }
                    else { page = .settings }
                }
                Text(page.rawValue).typeRole(Design.TypeRole.title).accessibilityIdentifier("settings-title")
                    .testReminderEvidence(session.reminderEvidence)
                switch page {
                case .settings: overview
                case .relationship: relationship
                case .about:
                    Text(AppCopy.entertainmentDisclaimer)
                        .typeRole(Design.TypeRole.body)
                        .lineSpacing(Design.Space.readingLeading)
                        .accessibilityIdentifier("settings-disclaimer")
                case .privacy:
                    Text("Everything stays on this phone and in your phone's own backups.")
                        .typeRole(Design.TypeRole.body)
                        .lineSpacing(Design.Space.readingLeading)
                        .accessibilityIdentifier("settings-privacy-copy")
                    Text("Nothing is sent anywhere else.")
                        .typeRole(Design.TypeRole.body)
                        .lineSpacing(Design.Space.readingLeading)
                        .accessibilityIdentifier("settings-privacy-detail")
                }
            }
            .fixedSize(horizontal: false, vertical: true)
            .foregroundStyle(Design.Palette.ink)
            .padding(.horizontal, Design.Space.page)
            .padding(.top, Design.Space.related)
            .padding(.bottom, Design.Space.large)
        } footer: { EmptyView() }
        .id(page)
        .alert("Your setting could not be saved", isPresented: $session.settingsSaveFailed) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Your previous setting is unchanged. Check the free space on your phone, then try the switch or choice again.")
        }
        .sheet(item: $export, onDismiss: removeExport) { item in
            ReadingExportSheet(export: item) { export = nil }
        }
        .alert("Your export could not be prepared", isPresented: $exportFailed) {
            Button("Try again", action: prepareExport)
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Your saved readings are unchanged. Check the free space on your phone, then try again.")
        }
        .alert("Delete all your data?", isPresented: $confirmsDeletion) {
            Button("Cancel", role: .cancel) { }
            Button("Delete all data", role: .destructive) {
                do { try session.deleteAllData() }
                catch { deletionFailed = true }
            }
            .disabled(session.reminderBusy)
        } message: {
            Text("This removes your readings, notes, drafts, preferences and daily-card identity, and cancels your reminder. It cannot be undone. Copies already saved elsewhere remain.")
        }
        .alert("Your data could not be deleted", isPresented: $deletionFailed) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Your saved data is unchanged. Check the free space on your phone, then try Delete all my data again.")
        }
    }

    private var overview: some View {
        VStack(alignment: .leading, spacing: Design.Space.section) {
            VStack(alignment: .leading, spacing: Design.Space.related) {
                sectionTitle("Areas on your Today screen")
                SettingsGroup {
                    ForEach(ReadingArea.allCases) { area in
                        if area != ReadingArea.allCases.first { SettingsDivider() }
                        AreaVisibilityToggle(area: area, isOn: Binding(
                            get: { !session.hiddenAreas.contains(area) },
                            set: { session.setArea(area, visible: $0) }
                        ), locked: session.visibleAreas == [area])
                    }
                }
                Text(session.visibleAreas.count == 1
                     ? AppCopy.lastVisibleAreaHint
                     : AppCopy.hiddenAreasHint)
                    .typeRole(Design.TypeRole.caption).foregroundStyle(Design.Palette.secondary)
                    .accessibilityIdentifier("area-visibility-hint")
            }
            VStack(alignment: .leading, spacing: Design.Space.related) {
                sectionTitle("About you")
                SettingsGroup {
                    SettingsLink(title: "Relationship status", value: session.relationshipStatus?.label ?? "Not set") {
                        page = .relationship
                    }
                    .accessibilityIdentifier("settings-relationship")
                }
            }
            VStack(alignment: .leading, spacing: Design.Space.related) {
                sectionTitle("Morning reminder")
                SettingsGroup {
                    ReminderToggle(isOn: Binding(get: { session.reminderEnabled }, set: { enabled in
                        Task { await session.setReminderEnabled(enabled) }
                    }), busy: session.reminderBusy)
                }
                Text(session.reminderBusy ? "Setting up your reminder…" : session.reminderDenied
                     ? AppCopy.reminderDeniedHint : "Every day at 8:00 am on this phone.")
                    .typeRole(Design.TypeRole.caption).foregroundStyle(Design.Palette.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("reminder-hint")
            }
            VStack(alignment: .leading, spacing: Design.Space.related) {
                sectionTitle("Good to know")
                SettingsGroup {
                    SettingsLink(title: "About these readings") { page = .about }
                        .accessibilityIdentifier("settings-about")
                    SettingsDivider()
                    SettingsLink(title: "Privacy") { page = .privacy }
                        .accessibilityIdentifier("settings-privacy")
                    SettingsDivider()
                    SettingsLink(title: "Export my readings", showsChevron: false, action: prepareExport)
                        .accessibilityIdentifier("settings-export")
                        .disabled(exporting)
                    SettingsDivider()
                    SettingsLink(title: "Delete all my data", showsChevron: false, role: .destructive) {
                        confirmsDeletion = true
                    }
                    .accessibilityIdentifier("settings-delete-all")
                    .disabled(session.reminderBusy)
                }
            }
        }
    }

    private var relationship: some View {
        VStack(alignment: .leading, spacing: Design.Space.group) {
            Text("Optional. This helps relationship readings speak to where you are. You can change or clear it at any time.")
                .typeRole(Design.TypeRole.secondary).foregroundStyle(Design.Palette.secondary)
            Text(session.relationshipStatus.map { "Current status: \($0.label)" } ?? "Current status: Not set")
                .typeRole(Design.TypeRole.label).accessibilityIdentifier("settings-current-status")
            SettingsGroup {
                ForEach(RelationshipStatus.allCases) { status in
                    if status != RelationshipStatus.allCases.first { SettingsDivider() }
                    SettingsChoice(title: status.label, selected: session.relationshipStatus == status) {
                        session.setRelationshipStatus(status)
                    }
                    .accessibilityIdentifier("settings-status-\(status.rawValue)")
                }
                SettingsDivider()
                SettingsChoice(title: "Clear relationship status", selected: session.relationshipStatus == nil) {
                    session.setRelationshipStatus(nil)
                }
                .accessibilityIdentifier("settings-clear-status")
            }
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title).typeRole(.metadata).foregroundStyle(Design.Palette.secondary)
    }

    private func prepareExport() {
        guard !exporting else { return }
        do {
            export = try session.exportReadings()
            exporting = true
        }
        catch { exportFailed = true }
    }

    private func removeExport() {
        // Cleanup is retried on next export, deletion and launch if the OS temporarily refuses it.
        try? ReadingExport.removeTemporaryCopy()
        // Do not let an earlier dismissal remove a newly prepared file.
        exporting = false
    }
}
