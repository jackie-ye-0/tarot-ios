import SwiftUI

struct SettingsScreen: View {
    @Bindable var session: AppSession
    @State private var page: Page = .settings

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
                switch page {
                case .settings: overview
                case .relationship: relationship
                case .about:
                    Text(AppCopy.entertainmentDisclaimer)
                        .typeRole(Design.TypeRole.body)
                        .lineSpacing(Design.Space.readingLeading)
                        .accessibilityIdentifier("settings-disclaimer")
                case .privacy:
                    Text("Everything stays on this phone. Your readings, questions, drafts and preferences are stored here.")
                        .typeRole(Design.TypeRole.body)
                        .lineSpacing(Design.Space.readingLeading)
                        .accessibilityIdentifier("settings-privacy-copy")
                    Text("There is no account, server, analytics or AI call. Nothing is sent to us or anyone else.")
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
                     ? "Keep at least one area on so Today and Ask have an area to show."
                     : "Hidden areas keep their past readings.")
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
                sectionTitle("Good to know")
                SettingsGroup {
                    SettingsLink(title: "About these readings") { page = .about }
                        .accessibilityIdentifier("settings-about")
                    SettingsDivider()
                    SettingsLink(title: "Privacy") { page = .privacy }
                        .accessibilityIdentifier("settings-privacy")
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
}
