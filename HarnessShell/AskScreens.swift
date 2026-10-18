import SwiftUI

struct AskScreen: View {
    @Bindable var session: AppSession
    @Environment(\.dynamicTypeSize) private var textSize

    var body: some View {
        ReadingScreenLayout {
            VStack(alignment: .leading, spacing: Design.Space.section) {
                Text("What's on your mind?").typeRole(Design.TypeRole.title).accessibilityIdentifier("ask-title")
                AreaSelector(selection: $session.area, areas: session.visibleAreas)
                if let reading = session.todayAreaReading, let name = session.todayCardName {
                    AskContextPanel(area: session.area, cardName: name, reading: reading)
                }
                QuestionEntry(title: "Ask about \(session.area.subject)") { session.openComposer() }
                    .accessibilityIdentifier("ask-question-entry")
                SuggestedQuestions(questions: session.suggestions) { session.openComposer(question: $0) }
                if session.area == .relationship {
                    NamedPersonEntry(action: session.openAboutSomeone)
                }
                if session.area == .relationship && !session.relationshipStatusAsked {
                    relationshipPrompt
                }
                if let reading = session.latestReading { recentReading(reading) }
            }
            .foregroundStyle(Design.Palette.ink)
            .padding(.horizontal, Design.Space.page)
            .padding(.vertical, Design.Space.page)
        } footer: { EmptyView() }
    }

    private var relationshipPrompt: some View {
        VStack(alignment: .leading, spacing: Design.Space.small) {
            Divider().overlay(Design.Palette.hairline)
            Text("Where are you, relationship-wise?").typeRole(.metadata)
                .accessibilityIdentifier("relationship-prompt")
            ForEach(RelationshipStatus.allCases) { status in
                QuestionChip(title: status.label, fillsWidth: true) { session.setRelationshipStatus(status) }
                    .accessibilityIdentifier("relationship-status-\(status.rawValue)")
            }
            Text("Optional. Answering makes love readings speak to where you actually are.")
                .typeRole(Design.TypeRole.secondary).foregroundStyle(Design.Palette.secondary)
            QuietAction(title: "Skip", night: false) { session.setRelationshipStatus(nil) }
                .accessibilityIdentifier("skip-relationship-status")
        }
    }

    private func recentReading(_ reading: QuestionReading) -> some View {
        VStack(alignment: .leading, spacing: Design.Space.related) {
            Divider().overlay(Design.Palette.hairline)
            Text("Your last \(session.area.rawValue) reading").typeRole(.metadata)
            Button { session.screen = .reading(reading) } label: {
                let layout = textSize.isAccessibilitySize
                    ? AnyLayout(VStackLayout(alignment: .leading, spacing: Design.Space.related))
                    : AnyLayout(HStackLayout(spacing: Design.Space.related))
                layout {
                    HStack(spacing: Design.Space.small) {
                        ForEach(reading.picks) { pick in
                            TarotCardView(card: pick.card, orientation: pick.orientation, width: 24)
                        }
                    }.accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: Design.Space.small) {
                        Text("“\(reading.question)”").typeRole(.metadata)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(reading.createdAt, format: .dateTime.day().month(.wide))
                            .typeRole(Design.TypeRole.secondary).foregroundStyle(Design.Palette.secondary)
                    }
                    if !textSize.isAccessibilitySize { Spacer(minLength: 0) }
                    Image(systemName: "chevron.right").typeRole(.label).accessibilityHidden(true)
                }
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, minHeight: Design.Space.target, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(ActionPressStyle())
            .accessibilityIdentifier("latest-area-reading")
        }
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
                        AreaSelector(selection: $session.area, areas: session.visibleAreas)
                    } else {
                        HStack(spacing: Design.Space.small) {
                            back
                            AreaSelector(selection: $session.area, areas: session.visibleAreas)
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
                VStack(alignment: .leading, spacing: Design.Space.group) {
                    ComposerPreview()
                    PrimaryAction(title: session.canSubmit ? "Draw my three cards" : "Write or pick a question",
                                  arrow: session.canSubmit, action: session.submitQuestion)
                        .disabled(!session.canSubmit)
                        .accessibilityIdentifier("submit-question")
                }
            }
        }
    }

    private var back: some View {
        NavigationAction(action: session.backToAsk)
            .dynamicTypeSize(.large) // Keep the glyph's designed size; its target remains at least 44 points.
    }
}

struct AboutSomeoneScreen: View {
    @Bindable var session: AppSession
    @Environment(\.dynamicTypeSize) private var textSize
    @FocusState private var noteFocused: Bool

    var body: some View {
        ScrollViewReader { scroll in
            ReadingScreenLayout {
                VStack(alignment: .leading, spacing: Design.Space.page) {
                    NavigationAction(action: session.backToAsk)
                    VStack(alignment: .leading, spacing: Design.Space.small) {
                        Text("Who's on your mind?").typeRole(Design.TypeRole.title)
                            .accessibilityIdentifier("person-title")
                        Text("No birth details needed for them. Just a name or nickname, so the reading can speak about them.")
                            .typeRole(Design.TypeRole.secondary).foregroundStyle(Design.Palette.secondary)
                            .accessibilityIdentifier("person-explanation")
                    }
                    VStack(alignment: .leading, spacing: Design.Space.small) {
                        Text("Their name or a nickname").typeRole(.metadata)
                        PersonNameField(text: Binding(get: { session.person?.name ?? "" }, set: { session.person?.name = $0 })) {
                            scroll.scrollTo("person-name", anchor: .top)
                        }.id("person-name")
                    }
                    VStack(alignment: .leading, spacing: Design.Space.small) {
                        Text("They are your...").typeRole(.metadata)
                        let columns = textSize.isAccessibilitySize ? 1 : 3
                        Grid(horizontalSpacing: Design.Space.small, verticalSpacing: Design.Space.small) {
                            ForEach(0..<(PersonRelation.allCases.count / columns), id: \.self) { row in
                                GridRow {
                                    ForEach(0..<columns, id: \.self) { column in
                                        let relation = PersonRelation.allCases[row * columns + column]
                                        QuestionChip(title: relation.label, fillsWidth: true, centresTitle: true,
                                                     selected: session.person?.relation == relation) {
                                            session.person?.relation = relation
                                        }.accessibilityIdentifier("person-relation-\(relation.rawValue)")
                                    }
                                }
                            }
                        }
                    }
                    VStack(alignment: .leading, spacing: Design.Space.small) {
                        Text("Anything specific? (optional)").typeRole(.metadata)
                        NoteField(text: Binding(get: { session.person?.note ?? "" }, set: { session.person?.note = $0 }),
                                  focused: $noteFocused, onFocus: { scroll.scrollTo("person-note", anchor: .top) },
                                  placeholder: "We've been talking for two months and I can't read where it's going.",
                                  label: "Anything specific? Optional note", identifier: "person-note", minimumHeight: 96)
                            .id("person-note")
                    }
                }
                .foregroundStyle(Design.Palette.ink)
                .padding(.horizontal, Design.Space.page)
                .padding(.vertical, Design.Space.related)
            } footer: {
                VStack(spacing: Design.Space.group) {
                    Text("You · Them · The Connection")
                        .typeRole(Design.TypeRole.secondary).foregroundStyle(Design.Palette.secondary)
                        .multilineTextAlignment(.center)
                    PrimaryAction(title: session.person?.actionTitle ?? "Add a name and who they are", action: session.submitQuestion)
                        .disabled(!session.canSubmit)
                        .accessibilityIdentifier("submit-person")
                }
            }
            .scrollDismissesKeyboard(.never)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if noteFocused { NoteKeyboardDismissal { noteFocused = false } }
            }
        }
    }
}

struct SpreadCards: View {
    let picks: [SpreadPick]
    var type: ReadingType = .question
    var night = false
    var animationsEnabled = false
    @Environment(\.dynamicTypeSize) private var textSize

    var body: some View {
        let layout = textSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .center, spacing: Design.Space.section))
            : AnyLayout(HStackLayout(alignment: .top, spacing: Design.Space.related))
        layout {
            ForEach(Array(type.positions.enumerated()), id: \.element) { index, position in
                let pick = picks.first { $0.position == position }
                VStack(spacing: Design.Space.small) {
                    if let pick {
                        TarotCardView(card: pick.card, orientation: pick.orientation, width: night ? 92 : 78, night: night)
                            .accessibilityHidden(true)
                    } else {
                        EmptySpreadSlot(number: index + 1, active: picks.count == index, width: 92,
                                        animationsEnabled: animationsEnabled)
                    }
                    if !night || pick == nil { Text(position.label).typeRole(.label) }
                    if let pick {
                        Text(pick.card.name).typeRole(night ? .metadata : Design.TypeRole.secondary)
                            .foregroundStyle(night ? Design.Palette.cream : Design.Palette.ink)
                        Text(pick.orientation.label).typeRole(Design.TypeRole.secondary)
                            .accessibilityIdentifier("spread-orientation-\(position.rawValue)")
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
    let animationsEnabled: Bool
    let holdShuffle: Bool
    let testMode: Bool
    @State private var shuffleID = 0

    var body: some View {
        ReadingScreenLayout(night: true, ritualDisc: true) {
            VStack(alignment: .leading, spacing: Design.Space.page) {
                ZStack {
                    HStack {
                        NavigationAction(night: true, action: session.backToComposer)
                        Spacer()
                    }
                    Text(session.picks.count == 3 ? "All three drawn" : "Card \(session.picks.count + 1) of 3")
                        .typeRole(Design.TypeRole.secondary).foregroundStyle(Design.Palette.nightSecondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, Design.Space.target + Design.Space.small)
                        .accessibilityIdentifier("spread-progress")
                }
                VStack(alignment: .leading, spacing: Design.Space.small) {
                    Text("“\(session.spreadTitle)”").typeRole(.section).accessibilityIdentifier("spread-question")
                    Text(session.person == nil ? "Your \(session.area.rawValue) question" : "Your relationship reading")
                        .typeRole(Design.TypeRole.secondary).foregroundStyle(Design.Palette.nightSecondary)
                }
                Divider().overlay(Design.Palette.nightHairline)
                SpreadCards(picks: session.picks, type: session.readingType, night: true, animationsEnabled: animationsEnabled)
                    .zIndex(1)
                if session.picks.count < 3 {
                    Text(session.readingType.positions[session.picks.count].pickPrompt)
                        .typeRole(.section)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                        .accessibilityIdentifier("pick-prompt")
                        .zIndex(1)
                    SpreadPickFan(animationsEnabled: animationsEnabled, holdShuffle: holdShuffle,
                                  testMode: testMode, choose: session.pickCard)
                        .id("\(session.picks.count)-\(shuffleID)")
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
                VStack(spacing: Design.Space.small) {
                    QuietAction(title: "Shuffle", underlined: true) { shuffleID += 1 }
                        .accessibilityIdentifier("spread-shuffle")
                    Text("Shuffling never uses up a pick.").typeRole(Design.TypeRole.caption)
                        .foregroundStyle(Design.Palette.nightSecondary)
                        .multilineTextAlignment(.center)
                        .accessibilityIdentifier("spread-shuffle-helper")
                }
            }
        }
    }
}

private struct SpreadPickFan: View {
    let animationsEnabled: Bool
    let holdShuffle: Bool
    let testMode: Bool
    let choose: () -> Void
    @State private var phase = FanPhase.gathered
    @State private var order = Array(1...5)
    @State private var settled = false

    var body: some View {
        CardFan(selected: nil, phase: animationsEnabled ? phase : .fanned, order: order,
                compact: true, showsDisc: false, choose: { _ in choose() })
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("spread-fan")
            .testMotionState(enabled: testMode, settled: !animationsEnabled || settled)
            .task(id: animationsEnabled) {
                guard animationsEnabled else { return }
                do {
                    withAnimation(Design.Motion.wash) {
                        order = [order[2], order[0], order[4], order[1], order[3]]
                        phase = .washLeft
                    }
                    try await Task.sleep(for: .seconds(Design.Motion.washDuration))
                    try Task.checkCancellation()
                    if holdShuffle { return }
                    withAnimation(Design.Motion.wash) { phase = .washRight }
                    try await Task.sleep(for: .seconds(Design.Motion.washDuration))
                    try Task.checkCancellation()
                    withAnimation(Design.Motion.fanOut, completionCriteria: .removed) { phase = .fanned } completion: {
                        settled = true
                    }
                } catch is CancellationError {
                    // A pick, replay or navigation replaces this fan and cancels its sequence.
                } catch { assertionFailure("Unexpected spread shuffle timing error: \(error)") }
            }
    }
}

struct QuestionReadingScreen: View {
    let session: AppSession
    let done: () -> Void
    @State private var reading: QuestionReading
    @Environment(\.dynamicTypeSize) private var textSize
    @State private var editingNote = false
    @State private var noteDraft = ""
    @State private var confirmingDelete = false
    @State private var operationFailed = false
    @FocusState private var noteFocused: Bool

    init(reading: QuestionReading, session: AppSession, done: @escaping () -> Void) {
        _reading = State(initialValue: reading)
        self.session = session
        self.done = done
    }

    var body: some View {
        Group {
            if editingNote { noteEditor }
            else { readingContent }
        }
        .alert("Delete this reading?", isPresented: $confirmingDelete) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                do {
                    try session.deleteReading(id: reading.id)
                    done()
                }
                catch { operationFailed = true }
            }
        } message: {
            Text("This reading and its note will be removed from this phone. This cannot be undone.")
        }
        .alert("Your change could not be saved", isPresented: $operationFailed) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Your saved reading is unchanged. Free some space on your phone if needed, then try the action again.")
        }
    }

    private var readingContent: some View {
        ReadingScreenLayout {
            VStack(alignment: .leading, spacing: Design.Space.section) {
                HStack {
                    NavigationAction(close: true, action: done)
                    Spacer()
                    ShareImageButton(content: .reading(reading))
                    ReadingMoreMenu(hasNote: reading.note != nil) {
                        noteDraft = reading.note ?? ""
                        editingNote = true
                    } delete: { confirmingDelete = true }
                }
                VStack(alignment: .leading, spacing: Design.Space.small) {
                    Text("“\(reading.question)”").typeRole(Design.TypeRole.title).accessibilityIdentifier("reading-question")
                    ReadingSavedMetadata(area: reading.area)
                }
                SpreadCards(picks: reading.picks, type: reading.type)
                ForEach(reading.picks) { pick in
                    if let section = reading.sections.first(where: { $0.position == pick.position }) {
                        passage(title: "\(pick.position.label) · \(pick.card.name)\(pick.orientation == .reversed ? ", reversed" : "")",
                                text: section.text, identifier: "reading-\(pick.position.rawValue)")
                    }
                }
                passage(title: "Read together", text: reading.connectingPassage, identifier: "reading-lens")
                ReflectionPanel(question: reading.reflectionQuestion)
                responseChoices
                if let note = reading.note {
                    VStack(alignment: .leading, spacing: Design.Space.small) {
                        Text("Your note").typeRole(.metadata)
                        Text(note).typeRole(Design.TypeRole.body)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityIdentifier("reading-note")
                    }
                }
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

    private var responseChoices: some View {
        VStack(alignment: .leading, spacing: Design.Space.small) {
            Text("Did this land?").typeRole(.metadata).accessibilityIdentifier("reading-response-prompt")
            let layout = textSize.isAccessibilitySize
                ? AnyLayout(VStackLayout(alignment: .leading, spacing: Design.Space.small))
                : AnyLayout(HStackLayout(spacing: Design.Space.small))
            layout {
                ForEach(ReadingResponse.allCases) { response in
                    QuestionChip(title: response.label, fillsWidth: !textSize.isAccessibilitySize,
                                 centresTitle: !textSize.isAccessibilitySize, selected: reading.response == response) {
                        do { reading = try session.setReadingResponse(reading.response == response ? nil : response, id: reading.id) }
                        catch { operationFailed = true }
                    }
                    .accessibilityIdentifier("reading-response-\(response.rawValue)")
                }
            }
        }
    }

    private var noteEditor: some View {
        ScrollViewReader { scroll in
            ReadingScreenLayout {
                VStack(alignment: .leading, spacing: Design.Space.section) {
                    QuietAction(title: "Cancel", night: false) {
                        noteFocused = false
                        editingNote = false
                    }.accessibilityIdentifier("note-cancel")
                    Text("Your note").typeRole(Design.TypeRole.title).accessibilityIdentifier("note-title")
                    NoteField(text: $noteDraft, focused: $noteFocused) {
                        scroll.scrollTo("note-field", anchor: .top)
                    }
                    .id("note-field")
                }
                .foregroundStyle(Design.Palette.ink)
                .padding(.horizontal, Design.Space.page)
                .padding(.vertical, Design.Space.related)
            } footer: {
                PrimaryAction(title: "Save note") {
                    do {
                        reading = try session.saveReadingNote(noteDraft, id: reading.id)
                        noteFocused = false
                        editingNote = false
                    } catch { operationFailed = true }
                }
                .accessibilityIdentifier("note-save")
            }
            .scrollDismissesKeyboard(.never)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if noteFocused { NoteKeyboardDismissal { noteFocused = false } }
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

struct SupportScreen: View {
    let session: AppSession

    var body: some View {
        let content = session.crisisContent
        ReadingScreenLayout {
            VStack(alignment: .leading, spacing: Design.Space.section) {
                Text(content.title).typeRole(Design.TypeRole.title)
                    .accessibilityIdentifier("support-title")
                Text(content.introduction).typeRole(Design.TypeRole.body)
                    .accessibilityIdentifier("support-introduction")
                Text(content.region).typeRole(.metadata)
                    .accessibilityIdentifier("support-region")
                ForEach(content.resources) { resource in
                    VStack(alignment: .leading, spacing: Design.Space.related) {
                        Divider().overlay(Design.Palette.hairline)
                        Text(resource.title).typeRole(.section)
                            .accessibilityIdentifier("support-\(resource.id)-title")
                        Text(resource.contact).typeRole(.metadata)
                            .accessibilityIdentifier("support-\(resource.id)-contact")
                        Text(resource.detail).typeRole(Design.TypeRole.body)
                            .foregroundStyle(Design.Palette.secondary)
                            .accessibilityIdentifier("support-\(resource.id)-detail")
                    }
                }
                Text(content.outsideRegion).typeRole(Design.TypeRole.body)
                    .foregroundStyle(Design.Palette.secondary)
                    .accessibilityIdentifier("support-outside-region")
                if session.crisisRemovalFailed {
                    VStack(alignment: .leading, spacing: Design.Space.related) {
                        Text(content.removalFailure).typeRole(Design.TypeRole.body)
                            .accessibilityIdentifier("support-removal-failure")
                        QuietAction(title: content.retryTitle, night: false, action: session.removeCrisisDrafts)
                            .accessibilityIdentifier("support-retry-removal")
                    }
                }
            }
            .foregroundStyle(Design.Palette.ink)
            .padding(.horizontal, Design.Space.page)
            .padding(.vertical, Design.Space.page)
        } footer: {
            PrimaryAction(title: content.returnTitle, action: session.leaveSupport)
                .disabled(session.crisisRemovalFailed)
                .accessibilityIdentifier("support-today")
        }
    }
}
