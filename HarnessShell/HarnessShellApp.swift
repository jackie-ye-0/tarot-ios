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
    @Environment(\.dynamicTypeSize) private var systemTextSize
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion

    var body: some View {
        Group {
            if let session { ContentView(session: session) }
            else if failed {
                VStack(spacing: Design.Space.section) {
                    Text("Your readings could not be opened").typeRole(.title)
                    Text("Nothing has been replaced. Try again after checking the free space on your phone.")
                        .typeRole(.body)
                    PrimaryAction(title: "Try again", action: load)
                }
                .foregroundStyle(Design.Palette.ink)
                .padding(Design.Space.page)
                .background { ScreenGround() }
            } else { ScreenGround() }
        }
        .environment(\.dynamicTypeSize, configuration.largestText ? .accessibility5 : systemTextSize)
        .transaction { transaction in
            if configuration.reduceMotion || systemReduceMotion {
                transaction.animation = nil
                transaction.disablesAnimations = true
            }
        }
        .onAppear { if session == nil && !failed { load() } }
    }

    private func load() {
        do { session = try AppLaunch.makeSession(configuration: configuration); failed = false }
        catch { failed = true }
    }
}
