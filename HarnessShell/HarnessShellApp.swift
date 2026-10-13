import SwiftUI

@main
struct HarnessShellApp: App {
    private let configuration = LaunchConfiguration.current()
    var body: some Scene {
        WindowGroup {
            #if DEBUG
            if configuration.testMode && (configuration.cardFaceProof || configuration.cardSizeProof) {
                CardFaceProof(sizes: configuration.cardSizeProof, largestText: configuration.largestText)
            } else { LaunchView(configuration: configuration) }
            #else
            LaunchView(configuration: configuration)
            #endif
        }
    }
}

struct LaunchView: View {
    let configuration: LaunchConfiguration
    @State private var session: AppSession?
    @State private var failed = false
    @State private var attemptedLoad = false
    @Environment(\.dynamicTypeSize) private var systemTextSize
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.scenePhase) private var scenePhase
    #if DEBUG
    @State private var advanceOnBackground = false
    #endif

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
        #if DEBUG
        .background {
            if configuration.testMode { TestSafeAreaViewport() }
        }
        #endif
        .environment(\.dynamicTypeSize, configuration.largestText ? .accessibility5 : systemTextSize)
        .transaction { transaction in
            if !animationsEnabled {
                transaction.animation = nil
                transaction.disablesAnimations = true
            }
        }
        .onAppear { if session == nil && !failed { load() } }
        .onChange(of: scenePhase) { _, phase in
            #if DEBUG
            if phase == .background && advanceOnBackground {
                session?.clock.advanceTestDay()
                advanceOnBackground = false
            }
            #endif
            if phase == .active { session?.refreshDay() }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
            session?.refreshDay()
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSSystemTimeZoneDidChange)) { _ in
            session?.refreshDay()
        }
        #if DEBUG
        .overlay(alignment: .topTrailing) {
            if configuration.testMode && configuration.testControls, let session {
                Menu("Test controls") {
                    Button("Advance day") {
                        session.clock.advanceTestDay()
                        NotificationCenter.default.post(name: UIApplication.significantTimeChangeNotification, object: nil)
                    }.accessibilityIdentifier("test-next-day")
                    Button("Advance while backgrounded") { advanceOnBackground = true }
                        .accessibilityIdentifier("test-background-day")
                    Button("Change time zone") {
                        session.clock.toggleTestTimeZone()
                        NotificationCenter.default.post(name: .NSSystemTimeZoneDidChange, object: nil)
                    }.accessibilityIdentifier("test-time-zone")
                }
                .typeRole(Design.TypeRole.caption)
                .foregroundStyle(Design.Palette.ink)
                .padding(Design.Space.group)
                .background(Design.Palette.surface, ignoresSafeAreaEdges: [])
                .accessibilityIdentifier("test-controls")
            }
        }
        #endif
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

#if DEBUG
// A container for XCTest geometry, not a VoiceOver content element or a touch target.
private struct TestSafeAreaViewport: UIViewRepresentable {
    func makeUIView(context: Context) -> ViewportHost { ViewportHost() }
    func updateUIView(_ uiView: ViewportHost, context: Context) { uiView.setNeedsLayout() }

    final class ViewportHost: UIView {
        private let marker = UIView()

        init() {
            super.init(frame: .zero)
            isUserInteractionEnabled = false
            isAccessibilityElement = false
            marker.isUserInteractionEnabled = false
            marker.isAccessibilityElement = false
            marker.accessibilityIdentifier = "test-safe-viewport"
            addSubview(marker)
        }

        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

        override func layoutSubviews() {
            super.layoutSubviews()
            guard let window else { return }
            marker.frame = convert(window.safeAreaLayoutGuide.layoutFrame, from: window)
        }

        override func safeAreaInsetsDidChange() {
            super.safeAreaInsetsDidChange()
            setNeedsLayout()
        }
    }
}
#endif
