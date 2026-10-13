import SwiftUI

struct ContentView: View {
    @Bindable var session: AppSession

    var body: some View {
        Group {
            switch session.screen {
            case .draw:
                DrawScreen(session: session).id("draw")
            case .reveal(let draw):
                RevealScreen(draw: draw) { session.screen = .today(draw) }.id("reveal")
            case .today(let draw):
                TodayScreen(draw: draw, dateLabel: session.dateLabel).id("today")
            }
        }
        .alert("Your card could not be saved", isPresented: $session.saveFailed) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Your choice is still here. Free some space on your phone if needed, then tap Turn it over to try again.")
        }
    }
}

struct DrawScreen: View {
    let session: AppSession
    @State private var selected: Int?
    @Environment(\.dynamicTypeSize) private var textSize

    var body: some View {
        ReadingScreenLayout(night: true, fillsAvailableHeight: true) {
            VStack(spacing: Design.Space.section) {
                Text(session.dateLabel)
                    .typeRole(Design.TypeRole.secondary)
                    .foregroundStyle(Design.Palette.nightSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, Design.Space.related)
                VStack(spacing: Design.Space.related) {
                    Text(selected == nil ? "Pick the one that pulls at you" : "This one is yours")
                        .typeRole(Design.TypeRole.title)
                        .foregroundStyle(Design.Palette.cream)
                        .accessibilityIdentifier("draw-title")
                        .frame(maxWidth: selected == nil && !textSize.isAccessibilitySize ? Design.Space.titleWidth : .infinity)
                    Text(selected.map { "Card \($0) of five. Ready when you are." } ?? "Tap any card. Trust the first tug.")
                        .typeRole(Design.TypeRole.body)
                        .foregroundStyle(Design.Palette.nightSecondary)
                }
                .multilineTextAlignment(.center)
                .frame(minHeight: textSize.isAccessibilitySize ? nil : Design.Space.drawHeadingHeight, alignment: .top)
                .zIndex(1) // The decorative disc can extend behind, but never cover, the heading.
                CardFan(selected: $selected)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, Design.Space.ritual)
            .padding(.top, Design.Space.page)
        } footer: {
            VStack(spacing: Design.Space.small) {
                if let selected {
                    PrimaryAction(title: "Turn it over", night: true) { session.turnOver(position: selected) }
                        .accessibilityIdentifier("turn-over")
                    QuietAction(title: "Choose a different card") { self.selected = nil }
                } else {
                    Text("Choose a card to begin")
                        .typeRole(Design.TypeRole.caption)
                        .foregroundStyle(Design.Palette.nightSecondary)
                        .frame(minHeight: Design.Space.target)
                }
            }
        }
    }
}

struct RevealScreen: View {
    let draw: DailyDraw
    let continueAction: () -> Void

    var body: some View {
        ReadingScreenLayout {
            VStack(spacing: Design.Space.large) {
                Text("You picked card \(draw.position) of five")
                    .typeRole(Design.TypeRole.secondary)
                    .foregroundStyle(Design.Palette.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityIdentifier("draw-position")
                    .padding(.bottom, Design.Space.small)
                TarotCardView(card: draw.card, orientation: draw.orientation, width: 214)
                    .accessibilityIdentifier("revealed-card")
                VStack(spacing: Design.Space.small) {
                    Text(draw.card.name)
                        .typeRole(.display)
                        .accessibilityIdentifier("card-name")
                    Text("\(draw.orientation.label) · \(draw.card.arcana)")
                        .typeRole(.metadata)
                        .accessibilityIdentifier("card-details")
                    Text(draw.meaning.keywords.joined(separator: ", "))
                        .typeRole(.keywords)
                        .foregroundStyle(Design.Palette.secondary)
                        .accessibilityIdentifier("card-keywords")
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
                    .foregroundStyle(Design.Palette.secondary)
                    .multilineTextAlignment(.center)
                    .accessibilityIdentifier("reveal-disclaimer")
            }
        }
    }
}

struct TodayScreen: View {
    let draw: DailyDraw
    let dateLabel: String
    @Environment(\.dynamicTypeSize) private var textSize

    var body: some View {
        ReadingScreenLayout {
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
            }
            .foregroundStyle(Design.Palette.ink)
            .padding(.horizontal, Design.Space.page)
            .padding(.top, Design.Space.page)
            .padding(.bottom, Design.Space.large)
        }
        footer: { EmptyView() }
    }

    private var card: some View {
        TarotCardView(card: draw.card, orientation: draw.orientation, width: 120)
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
