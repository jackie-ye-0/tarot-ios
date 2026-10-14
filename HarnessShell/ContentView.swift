import SwiftUI

struct ContentView: View {
    @Bindable var session: AppSession
    var animationsEnabled = true
    var holdShuffle = false
    var testMode = false

    var body: some View {
        ZStack {
            switch session.screen {
            case .welcome:
                WelcomeScreen(animationsEnabled: animationsEnabled, continueAction: session.completeWelcome)
            case .draw:
                DrawScreen(session: session, animationsEnabled: animationsEnabled,
                           holdShuffle: holdShuffle, testMode: testMode).id("draw-\(session.dateKey)")
            case .reveal(let draw):
                RevealScreen(draw: draw, animationsEnabled: animationsEnabled, testMode: testMode) {
                    session.showToday(draw)
                }.id("reveal-\(draw.dateKey)")
            case .today(let draw):
                TodayScreen(draw: draw, dateLabel: session.dateLabel,
                            animationsEnabled: animationsEnabled, testMode: testMode,
                            ask: { session.screen = .ask }).id("today-\(draw.dateKey)")
            case .ask:
                AskScreen(session: session).id("ask")
            case .composer:
                QuestionComposerScreen(session: session).id("composer")
            case .pick:
                ThreeCardPickScreen(session: session).id("pick")
            case .reading(let reading):
                QuestionReadingScreen(reading: reading, done: session.goToToday).id("reading")
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            switch session.screen {
            case .today, .ask:
                RestingTabBar(askSelected: isAsk, today: session.goToToday, ask: { session.screen = .ask })
            default: EmptyView()
            }
        }
        .alert("Your welcome could not be saved", isPresented: $session.welcomeSaveFailed) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Free some space on your phone if needed, then tap Draw my first card to try again. Your saved cards are unchanged.")
        }
        .alert("Your card could not be saved", isPresented: $session.saveFailed) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Your choice is still here. Free some space on your phone if needed, then tap Turn it over to try again.")
        }
        .alert("Today's card could not be opened", isPresented: $session.dayRefreshFailed) {
            Button("Try again") { session.refreshDay() }
        } message: {
            Text("Your saved cards are unchanged. Try again after checking the free space on your phone.")
        }
        .alert("Your spread could not be saved", isPresented: $session.readingSaveFailed) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Your three cards are still here. Free some space on your phone if needed, then tap Read my spread to try again.")
        }
    }

    private var isAsk: Bool { if case .ask = session.screen { true } else { false } }
}

struct WelcomeScreen: View {
    let animationsEnabled: Bool
    let continueAction: () -> Void

    var body: some View {
        ReadingScreenLayout(night: true, fillsAvailableHeight: true) {
            VStack(alignment: .leading, spacing: 0) {
                Text("Daybreak")
                    .typeRole(.wordmark)
                    .accessibilityIdentifier("welcome-name")
                    .zIndex(1) // The decorative disc extends behind the name, never over it.
                Spacer(minLength: Design.Space.large)
                WelcomeCard(animationsEnabled: animationsEnabled)
                    .frame(maxWidth: .infinity)
                Spacer(minLength: Design.Space.large)
                VStack(alignment: .leading, spacing: Design.Space.related) {
                    Text("One card.\nEvery morning.")
                        .typeRole(.compactDisplay)
                        .displayLineHeight()
                        .accessibilityIdentifier("welcome-title")
                    Text("Pick a card, turn it over, and see how today reads for your work, your love life and the people around you.")
                        .typeRole(Design.TypeRole.body)
                        .lineSpacing(Design.Space.readingLeading)
                        .foregroundStyle(Design.Palette.nightParagraph)
                        .accessibilityIdentifier("welcome-promise")
                }
                .fixedSize(horizontal: false, vertical: true)
            }
            .foregroundStyle(Design.Palette.cream)
            .padding(.horizontal, Design.Space.ritual)
            .padding(.top, Design.Space.page)
            .padding(.bottom, Design.Space.section)
        } footer: {
            VStack(spacing: Design.Space.related) {
                PrimaryAction(title: "Draw my first card", night: true, action: continueAction)
                    .accessibilityIdentifier("welcome-draw")
                Text("A mirror, not a forecast. Readings are for entertainment and reflection, not prediction or professional advice.")
                    .typeRole(Design.TypeRole.caption)
                    .foregroundStyle(Design.Palette.nightSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("welcome-disclaimer")
            }
        }
    }
}

struct DrawScreen: View {
    let session: AppSession
    let animationsEnabled: Bool
    let holdShuffle: Bool
    let testMode: Bool
    @State private var selected: Int?
    @State private var phase = FanPhase.gathered
    @State private var shuffling = true
    @State private var shuffleID = 0
    @State private var fanID = 0
    @State private var order = Array(1...5)
    @State private var motionSettled = true
    @State private var motionGeneration = 0
    @Environment(\.dynamicTypeSize) private var textSize

    private var isShuffling: Bool { animationsEnabled && shuffling }

    var body: some View {
        ReadingScreenLayout(night: true, fillsAvailableHeight: true) {
            VStack(spacing: Design.Space.section) {
                Text(session.dateLabel)
                    .typeRole(Design.TypeRole.secondary)
                    .foregroundStyle(Design.Palette.nightSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, Design.Space.related)
                VStack(spacing: Design.Space.related) {
                    Text(selected != nil ? "This one is yours" : isShuffling ? "Washing the cards…" : "Pick the one that pulls at you")
                        .typeRole(Design.TypeRole.title)
                        .foregroundStyle(Design.Palette.cream)
                        .accessibilityIdentifier("draw-title")
                        .testMotionState(enabled: testMode,
                                         settled: !animationsEnabled || (motionSettled && (!shuffling || holdShuffle)))
                        .frame(maxWidth: selected == nil && !textSize.isAccessibilitySize ? Design.Space.titleWidth : .infinity)
                    Text(selected.map { "Card \($0) of five. Ready when you are." } ?? "Tap any card. Trust the first tug.")
                        .typeRole(Design.TypeRole.body)
                        .foregroundStyle(Design.Palette.nightSecondary)
                }
                .multilineTextAlignment(.center)
                .frame(minHeight: textSize.isAccessibilitySize ? nil : Design.Space.drawHeadingHeight, alignment: .top)
                .zIndex(1) // The decorative disc can extend behind, but never cover, the heading.
                .transaction { $0.animation = nil; $0.disablesAnimations = true }
                CardFan(selected: selected, phase: animationsEnabled ? phase : .fanned,
                        order: order, choose: { choose($0) })
                    .id(fanID)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, Design.Space.ritual)
            .padding(.top, Design.Space.page)
        } footer: {
            VStack(spacing: Design.Space.small) {
                if let selected {
                    PrimaryAction(title: "Turn it over", night: true) { session.turnOver(position: selected) }
                        .accessibilityIdentifier("turn-over")
                    QuietAction(title: "Choose a different card") {
                        choose(nil)
                    }
                    .accessibilityIdentifier("choose-different")
                } else {
                    QuietAction(title: "Shuffle again", underlined: true, action: shuffleAgain)
                        .accessibilityIdentifier("shuffle-again")
                    Text("Shuffling changes the order, not your card.")
                        .typeRole(Design.TypeRole.caption)
                        .foregroundStyle(Design.Palette.nightSecondary)
                        .multilineTextAlignment(.center)
                        .accessibilityIdentifier("shuffle-helper")
                }
            }
            .transaction { $0.animation = nil; $0.disablesAnimations = true }
        }
        .task(id: animationsEnabled ? shuffleID : -1) { [shuffleID] in
            await shuffle(generation: shuffleID)
        }
    }

    private func choose(_ position: Int?) {
        // Interrupting the ritual snaps to its result; a settled pick can gently lift.
        if isShuffling {
            var transaction = Transaction(animation: nil)
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                shuffleID += 1
                // Replacing the presentation also ends motion already targeting the final fan.
                fanID += 1
                phase = .fanned
                shuffling = false
                selected = position
                motionGeneration += 1
                motionSettled = true
            }
        } else {
            animate(animationsEnabled ? Design.Motion.entrance : nil) { selected = position }
        }
    }

    private func shuffleAgain() {
        shuffling = animationsEnabled
        motionGeneration += 1
        motionSettled = false
        shuffleID += 1
    }

    private func shuffle(generation: Int) async {
        guard generation == shuffleID else { return }
        guard selected == nil else { return }
        guard animationsEnabled else {
            order = [order[2], order[0], order[4], order[1], order[3]]
            phase = .fanned
            shuffling = false
            motionSettled = true
            return
        }
        guard shuffling else { return }
        do {
            animate(Design.Motion.wash) {
                // This order belongs only to the decorative backs, never the reading engine.
                order = [order[2], order[0], order[4], order[1], order[3]]
                phase = .washLeft
            }
            try await Task.sleep(for: .seconds(Design.Motion.washDuration))
            try Task.checkCancellation()
            guard generation == shuffleID else { return }
            // Debug launch configuration holds a real phase so XCTest can test interruption
            // without racing its automatic wait for the app to become idle.
            if holdShuffle { return }
            animate(Design.Motion.wash) { phase = .washRight }
            try await Task.sleep(for: .seconds(Design.Motion.washDuration))
            try Task.checkCancellation()
            guard generation == shuffleID else { return }
            animate(Design.Motion.fanOut) { phase = .fanned }
        } catch is CancellationError {
            // Selection, another shuffle, Reduce Motion or leaving Draw cancels this run.
        } catch { assertionFailure("Unexpected shuffle timing error: \(error)") }
    }

    private func animate(_ animation: Animation?, changes: () -> Void) {
        motionGeneration += 1
        let generation = motionGeneration
        motionSettled = false
        withAnimation(animation, completionCriteria: .removed, changes) {
            if generation == motionGeneration {
                motionSettled = true
                if case .fanned = phase { shuffling = false }
            }
        }
    }
}

struct RevealScreen: View {
    let draw: DailyDraw
    let animationsEnabled: Bool
    let testMode: Bool
    var backAction: (() -> Void)? = nil
    let continueAction: () -> Void
    @State private var appeared = false
    @State private var motionSettled = false

    private var revealed: Bool { !animationsEnabled || appeared }

    var body: some View {
        ReadingScreenLayout(dawnProgress: revealed ? 1 : 0,
                            dawnAnimation: animationsEnabled ? Design.Motion.dawn : nil) {
            VStack(spacing: Design.Space.large) {
                HStack(spacing: Design.Space.small) {
                    if let backAction {
                        BackToTodayAction(progress: revealed ? 1 : 0, action: backAction)
                    }
                    Text("You picked card \(draw.position) of five")
                        .typeRole(Design.TypeRole.secondary)
                        .modifier(RevealPersistentCopy(progress: revealed ? 1 : 0))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityIdentifier("draw-position")
                }
                .padding(.bottom, Design.Space.small)
                TurningTarotCard(draw: draw, progress: revealed ? 1 : 0, width: 214)
                    .animation(animationsEnabled ? Design.Motion.flip : nil, value: revealed)
                    .background {
                        RevealSun(risen: revealed)
                            .animation(animationsEnabled ? Design.Motion.dawn : nil, value: revealed)
                    }
                    .accessibilityIdentifier("revealed-card")
                    .testMotionState(enabled: testMode, settled: !animationsEnabled || motionSettled)
                VStack(spacing: Design.Space.small) {
                    Text(draw.card.name)
                        .typeRole(.display)
                        .accessibilityIdentifier("card-name")
                        .modifier(RevealTextRise(visible: revealed, animated: animationsEnabled, index: 0))
                    Text("\(draw.orientation.label) · \(draw.card.arcana)")
                        .typeRole(.metadata)
                        .accessibilityIdentifier("card-details")
                        .modifier(RevealTextRise(visible: revealed, animated: animationsEnabled, index: 1))
                    Text(draw.meaning.keywords.joined(separator: ", "))
                        .typeRole(.keywords)
                        .foregroundStyle(Design.Palette.secondary)
                        .accessibilityIdentifier("card-keywords")
                        .modifier(RevealTextRise(visible: revealed, animated: animationsEnabled, index: 2))
                }
                .multilineTextAlignment(.center)
                .foregroundStyle(Design.Palette.ink)
            }
            .padding(.horizontal, Design.Space.ritual)
            .padding(.top, Design.Space.page)
            .padding(.bottom, Design.Space.section)
        }
        footer: {
            VStack(spacing: Design.Space.small) {
                PrimaryAction(title: "See what it means today", arrow: true, action: continueAction)
                    .accessibilityIdentifier("see-meaning")
                Text("For entertainment and reflection")
                    .typeRole(Design.TypeRole.caption)
                    .modifier(RevealPersistentCopy(progress: revealed ? 1 : 0))
                    .multilineTextAlignment(.center)
                    .accessibilityIdentifier("reveal-disclaimer")
            }
        }
        .onAppear {
            guard animationsEnabled else {
                appeared = true
                motionSettled = true
                return
            }
            withAnimation(Design.Motion.dawn, completionCriteria: .removed) { appeared = true }
            completion: { motionSettled = true }
        }
    }
}

struct TodayScreen: View {
    let draw: DailyDraw
    let dateLabel: String
    let animationsEnabled: Bool
    let testMode: Bool
    let ask: () -> Void
    @Environment(\.dynamicTypeSize) private var textSize
    @State private var showsReveal = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Design.Space.section) {
                Text(dateLabel).typeRole(.section)
                    .accessibilityIdentifier("today-title")
                if textSize.isAccessibilitySize {
                    VStack(alignment: .leading, spacing: Design.Space.group) { card; details }
                } else {
                    HStack(spacing: Design.Space.page) { card; details }
                }
                Text(draw.meaning.interpretation)
                    .typeRole(Design.TypeRole.body)
                    .lineSpacing(Design.Space.readingLeading)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("core-interpretation")
                if let daily = draw.meaning.daily {
                    DailyExtrasView(daily: daily)
                    VStack(alignment: .leading, spacing: Design.Space.group) {
                        Text("How today sits").typeRole(.section)
                        DailyScoreStrip(daily: daily)
                    }
                    VStack(alignment: .leading, spacing: Design.Space.group) {
                        Text("What to do about it").typeRole(.section)
                        DailyAreaLines(daily: daily)
                    }
                } else {
                    Text("This earlier draw has no saved extras or area readings.")
                        .typeRole(Design.TypeRole.caption).foregroundStyle(Design.Palette.secondary)
                }
                QuestionEntry(title: "Ask the cards", action: ask)
                    .accessibilityIdentifier("today-ask")
                Text("Your next card arrives at midnight")
                    .typeRole(Design.TypeRole.caption)
                    .foregroundStyle(Design.Palette.secondary)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                    .accessibilityIdentifier("next-card-arrival")
            }
            .foregroundStyle(Design.Palette.ink)
            .padding(.horizontal, Design.Space.page)
            .padding(.top, Design.Space.page)
            .padding(.bottom, Design.Space.large)
        }
        .accessibilityIdentifier("screen-content")
        .clipped()
        .background { ScreenGround() }
        .preferredColorScheme(.light)
        .fullScreenCover(isPresented: $showsReveal) {
            RevealScreen(draw: draw, animationsEnabled: animationsEnabled, testMode: testMode,
                         backAction: { showsReveal = false }) { showsReveal = false }
                .environment(\.dynamicTypeSize, textSize)
        }
    }

    private var card: some View {
        Button { showsReveal = true } label: {
            TarotCardView(card: draw.card, orientation: draw.orientation, width: 120)
                .overlay(alignment: .bottomTrailing) { CardExpansionMark() }
        }
        .buttonStyle(ActionPressStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel("\(draw.card.name), \(draw.orientation.label)")
        .accessibilityHint("Opens the full-size card")
        .accessibilityIdentifier("today-card")
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: Design.Space.small) {
            Text(draw.card.name).typeRole(.compactDisplay).accessibilityIdentifier("card-name")
            Text("\(draw.orientation.label) · \(draw.card.arcana)")
                .typeRole(.metadata).accessibilityIdentifier("card-details")
            Text(draw.meaning.keywords.joined(separator: ", "))
                .typeRole(Design.TypeRole.secondary).foregroundStyle(Design.Palette.secondary)
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}
