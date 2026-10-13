import SwiftUI

@main
struct HarnessShellApp: App {
    private let configuration = LaunchConfiguration.current()
    var body: some Scene {
        WindowGroup { LaunchView(configuration: configuration) }
    }
}

struct LaunchView: View {
    let configuration: LaunchConfiguration
    @State private var session: AppSession?
    @State private var failed = false
    @State private var attemptedLoad = false
    @Environment(\.dynamicTypeSize) private var systemTextSize
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion

    var body: some View {
        Group {
            if let session {
                ContentView(session: session, animationsEnabled: animationsEnabled,
                            holdShuffle: configuration.holdShuffle, testMode: configuration.testMode)
            }
            else if failed {
                ReadingScreenLayout {
                    VStack(alignment: .leading, spacing: Design.Space.section) {
                        Text("Your readings could not be opened")
                            .typeRole(Design.TypeRole.title)
                            .accessibilityIdentifier("storage-error-title")
                        Text("Nothing has been replaced. Try again after checking the free space on your phone.")
                            .typeRole(Design.TypeRole.body)
                    }
                    .foregroundStyle(Design.Palette.ink)
                    .padding(.horizontal, Design.Space.page)
                    .padding(.top, Design.Space.page)
                    .padding(.bottom, Design.Space.section)
                } footer: {
                    PrimaryAction(title: "Try again", action: load)
                        .accessibilityIdentifier("storage-retry")
                }
            } else { ScreenGround() }
        }
        .environment(\.dynamicTypeSize, configuration.largestText ? .accessibility5 : systemTextSize)
        .transaction { transaction in
            if !animationsEnabled {
                transaction.animation = nil
                transaction.disablesAnimations = true
            }
        }
        .onAppear { if session == nil && !failed { load() } }
    }

    private var animationsEnabled: Bool {
        !configuration.disableAnimations && !configuration.reduceMotion && !systemReduceMotion
    }

    private func load() {
        var nextConfiguration = configuration
        if attemptedLoad { nextConfiguration.forceStoreOpenFailure = false }
        attemptedLoad = true
        do { session = try AppLaunch.makeSession(configuration: nextConfiguration); failed = false }
        catch { failed = true }
    }
}
