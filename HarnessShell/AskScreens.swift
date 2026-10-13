import SwiftUI

struct AskScreen: View {
    @Bindable var session: AppSession

    var body: some View {
        ReadingScreenLayout {
            VStack(alignment: .leading, spacing: Design.Space.section) {
                Text("What's on your mind?").typeRole(Design.TypeRole.title).accessibilityIdentifier("ask-title")
                AreaSelector(selection: $session.area)
                QuestionEntry(title: "Ask about \(session.area.subject)") { session.openComposer() }
                    .accessibilityIdentifier("ask-question-entry")
                SuggestedQuestions(questions: session.suggestions) { session.openComposer(question: $0) }
            }
            .foregroundStyle(Design.Palette.ink)
            .padding(.horizontal, Design.Space.page)
            .padding(.vertical, Design.Space.page)
        } footer: { EmptyView() }
    }
}

struct SuggestedQuestions: View {
    let questions: [String]
    let choose: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Design.Space.small) {
            Text("Or start from one of these").typeRole(.metadata)
                .foregroundStyle(Design.Palette.ink)
            ForEach(Array(questions.enumerated()), id: \.element) { index, question in
                QuestionChip(title: question) { choose(question) }
                    .accessibilityIdentifier("suggestion-\(index)")
            }
        }
    }
}

struct QuestionComposerScreen: View {
    @Bindable var session: AppSession
    @Environment(\.dynamicTypeSize) private var textSize

    var body: some View {
        ScrollViewReader { scroll in
            ReadingScreenLayout {
                VStack(alignment: .leading, spacing: Design.Space.section) {
                    if textSize.isAccessibilitySize {
                        back
                        AreaSelector(selection: $session.area)
                    } else {
                        HStack(spacing: Design.Space.small) {
                            back
                            AreaSelector(selection: $session.area)
                        }
                    }
                    VStack(alignment: .leading, spacing: Design.Space.small) {
                        Text("What would you like to ask about \(session.area.subject)?")
                            .typeRole(Design.TypeRole.title).accessibilityIdentifier("composer-title")
                        Text("Open questions work best. “What” and “how” more than “will”.")
                            .typeRole(Design.TypeRole.secondary).foregroundStyle(Design.Palette.secondary)
                    }
                    QuestionField(text: $session.question) {
                        scroll.scrollTo("question-field", anchor: .top)
                    }
                    .id("question-field")
                    SuggestedQuestions(questions: session.suggestions) { session.question = $0 }
                }
                .foregroundStyle(Design.Palette.ink)
                .padding(.horizontal, Design.Space.page)
                .padding(.top, Design.Space.related)
                .padding(.bottom, Design.Space.section)
            } footer: {
                VStack(spacing: Design.Space.group) {
                    Text("Next you'll draw three cards: one for the situation, one for an action, one for the outcome.")
                        .typeRole(Design.TypeRole.secondary).foregroundStyle(Design.Palette.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    PrimaryAction(title: session.canSubmit ? "Draw my three cards" : "Write or pick a question",
                                  arrow: session.canSubmit, action: session.submitQuestion)
                        .disabled(!session.canSubmit)
                        .accessibilityIdentifier("submit-question")
                }
            }
        }
    }

    private var back: some View {
        NavigationAction { session.screen = .ask }
    }
}

struct SpreadCards: View {
    let picks: [SpreadPick]
    var night = false
    @Environment(\.dynamicTypeSize) private var textSize

    var body: some View {
        let layout = textSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .center, spacing: Design.Space.section))
            : AnyLayout(HStackLayout(alignment: .top, spacing: Design.Space.related))
        layout {
            ForEach(Array(QuestionPosition.allCases.enumerated()), id: \.element) { index, position in
                let pick = picks.first { $0.position == position }
                VStack(spacing: Design.Space.small) {
                    if let pick {
                        TarotCardView(card: pick.card, orientation: pick.orientation, width: night ? 92 : 78, night: night)
                            .accessibilityHidden(true)
                    } else {
                        EmptySpreadSlot(number: index + 1, active: picks.count == index, width: 92)
                    }
                    if !night || pick == nil { Text(position.label).typeRole(.label) }
                    if let pick {
                        Text(pick.card.name).typeRole(night ? .metadata : Design.TypeRole.secondary)
                            .foregroundStyle(night ? Design.Palette.cream : Design.Palette.ink)
                        Text(pick.orientation.label).typeRole(Design.TypeRole.secondary)
                        if night { Text(position.label).typeRole(.label) }
                    }
                }
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
                .foregroundStyle(night ? Design.Palette.nightSecondary : Design.Palette.ink)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(pick.map { "\(position.label), \($0.card.name), \($0.orientation.label)" }
                                    ?? "\(position.label), empty, card \(index + 1) of 3")
                .accessibilityIdentifier("spread-slot-\(position.rawValue)")
            }
        }
    }
}

struct ThreeCardPickScreen: View {
    let session: AppSession

    var body: some View {
        ReadingScreenLayout(night: true, ritualDisc: true) {
            VStack(alignment: .leading, spacing: Design.Space.page) {
                HStack {
                    NavigationAction(night: true) { session.screen = .composer }
                    Spacer()
                    Text(session.picks.count == 3 ? "All three drawn" : "Card \(session.picks.count + 1) of 3")
                        .typeRole(Design.TypeRole.secondary).foregroundStyle(Design.Palette.nightSecondary)
                        .accessibilityIdentifier("spread-progress")
                    Spacer()
                }
                VStack(alignment: .leading, spacing: Design.Space.small) {
                    Text("“\(session.question)”").typeRole(.section).accessibilityIdentifier("spread-question")
                    Text("Your \(session.area.rawValue) question")
                        .typeRole(Design.TypeRole.secondary).foregroundStyle(Design.Palette.nightSecondary)
                }
                Divider().overlay(Design.Palette.nightHairline)
                SpreadCards(picks: session.picks, night: true)
                    .zIndex(1)
                if session.picks.count < 3 {
                    Text("Choose your \(QuestionPosition.allCases[session.picks.count].rawValue) card")
                        .typeRole(.section)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                        .accessibilityIdentifier("pick-prompt")
                        .zIndex(1)
                    CardFan(selected: Binding(get: { nil }, set: { _ in session.pickCard() }), compact: true, showsDisc: false)
                }
            }
            .foregroundStyle(Design.Palette.cream)
            .padding(.horizontal, Design.Space.ritual)
            .padding(.top, Design.Space.related)
            .padding(.bottom, Design.Space.section)
        } footer: {
            if session.picks.count == 3 {
                VStack(spacing: Design.Space.group) {
                    Text("Your spread is laid").typeRole(Design.TypeRole.title).foregroundStyle(Design.Palette.cream)
                        .accessibilityIdentifier("spread-complete-title")
                    Text("Three cards, chosen by you. Take a breath, then read what they say together.")
                        .typeRole(Design.TypeRole.body).foregroundStyle(Design.Palette.nightSecondary)
                    PrimaryAction(title: "Read my spread", night: true, action: session.readSpread)
                        .accessibilityIdentifier("read-spread")
                }
                .multilineTextAlignment(.center)
            } else {
                Text("Each pick fills the next position").typeRole(Design.TypeRole.caption)
                    .foregroundStyle(Design.Palette.nightSecondary)
                    .frame(minHeight: Design.Space.target)
            }
        }
    }
}

struct QuestionReadingScreen: View {
    let reading: QuestionReading
    let done: () -> Void

    var body: some View {
        ReadingScreenLayout {
            VStack(alignment: .leading, spacing: Design.Space.section) {
                NavigationAction(close: true, action: done)
                VStack(alignment: .leading, spacing: Design.Space.small) {
                    Text("“\(reading.question)”").typeRole(Design.TypeRole.title).accessibilityIdentifier("reading-question")
                    Text("\(reading.area.label) · Saved on this phone")
                        .typeRole(Design.TypeRole.secondary).foregroundStyle(Design.Palette.secondary)
                        .accessibilityIdentifier("reading-saved")
                }
                SpreadCards(picks: reading.picks)
                ForEach(reading.picks) { pick in
                    if let section = reading.sections.first(where: { $0.position == pick.position }) {
                        passage(title: "\(pick.position.label) · \(pick.card.name)\(pick.orientation == .reversed ? ", reversed" : "")",
                                text: section.text, identifier: "reading-\(pick.position.rawValue)")
                    }
                }
                passage(title: "Read together", text: reading.connectingPassage, identifier: "reading-lens")
                ReflectionPanel(question: reading.reflectionQuestion)
            }
            .foregroundStyle(Design.Palette.ink)
            .padding(.horizontal, Design.Space.page)
            .padding(.top, Design.Space.related)
            .padding(.bottom, Design.Space.section)
        } footer: {
            VStack(spacing: Design.Space.small) {
                PrimaryAction(title: "Done", action: done).accessibilityIdentifier("reading-done")
                Text("For entertainment and reflection, not a prediction")
                    .typeRole(Design.TypeRole.caption).foregroundStyle(Design.Palette.secondary)
                    .multilineTextAlignment(.center)
                    .accessibilityIdentifier("reading-disclaimer")
            }
        }
    }

    private func passage(title: String, text: String, identifier: String) -> some View {
        VStack(alignment: .leading, spacing: Design.Space.small) {
            Text(title).typeRole(.metadata).foregroundStyle(Design.Palette.areaLabel(reading.area))
            Text(text).typeRole(Design.TypeRole.body).lineSpacing(Design.Space.readingLeading)
                .fixedSize(horizontal: false, vertical: true).accessibilityIdentifier(identifier)
        }
    }
}
