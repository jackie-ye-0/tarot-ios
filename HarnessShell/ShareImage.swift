import SwiftUI
import UIKit

/// Only saved reading content is shared; annotations stay on this phone.
enum ShareImageContent {
    case card(DailyDraw)
    case reading(QuestionReading)
}

struct ShareImageButton: View {
    let content: ShareImageContent
    var showsTitle = false
    @State private var sharedImage: SharedImage?
    @State private var failed = false

    var body: some View {
        ShareAction(showsTitle: showsTitle, action: prepareImage)
            .accessibilityIdentifier("share-image")
            .sheet(item: $sharedImage) { item in
                ImageShareSheet(image: item.image) { sharedImage = nil }
            }
            .alert("The image could not be prepared", isPresented: $failed) {
                Button("Try again", action: prepareImage)
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Your saved reading is unchanged. Try sharing again.")
            }
    }

    @MainActor private func prepareImage() {
        let renderer = ImageRenderer(content: SharedReadingImage(content: content)
            .environment(\.dynamicTypeSize, .large)
            .environment(\.colorScheme, .light))
        renderer.scale = 2
        renderer.isOpaque = true
        guard let image = renderer.uiImage else {
            failed = true
            return
        }
        sharedImage = SharedImage(image: image)
    }
}

private struct SharedImage: Identifiable {
    let id = UUID()
    let image: UIImage
}

private struct ImageShareSheet: UIViewControllerRepresentable {
    let image: UIImage
    let completed: () -> Void

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        // UIKit finishing an activity must also dismiss SwiftUI's presentation container.
        controller.completionWithItemsHandler = { _, _, _, _ in completed() }
        return controller
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) { }
}

private struct SharedReadingImage: View {
    let content: ShareImageContent

    var body: some View {
        VStack(alignment: .leading, spacing: Design.Space.section) {
            switch content {
            case .card(let draw):
                VStack(spacing: Design.Space.section) {
                    TarotCardView(card: draw.card, orientation: draw.orientation, width: 214)
                    Text(draw.card.name).typeRole(.display)
                    Text(draw.orientation.label).typeRole(.metadata)
                    disclaimer("For entertainment and reflection")
                }
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
            case .reading(let reading):
                VStack(alignment: .leading, spacing: Design.Space.small) {
                    Text("“\(reading.question)”").typeRole(Design.TypeRole.title)
                    Text(reading.area.label).typeRole(Design.TypeRole.secondary).foregroundStyle(Design.Palette.secondary)
                }
                SpreadCards(picks: reading.picks)
                ForEach(reading.sections, id: \.position) { section in
                    if let pick = reading.picks.first(where: { $0.position == section.position }) {
                        passage("\(pick.position.label) · \(pick.card.name)\(pick.orientation == .reversed ? ", reversed" : "")",
                                text: section.text, area: reading.area)
                    }
                }
                passage("Read together", text: reading.connectingPassage, area: reading.area)
                ReflectionPanel(question: reading.reflectionQuestion)
                disclaimer("For entertainment and reflection, not a prediction")
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
            }
        }
        .foregroundStyle(Design.Palette.ink)
        .padding(.horizontal, Design.Space.page)
        .padding(.vertical, Design.Space.section)
        .frame(width: 390)
        .fixedSize(horizontal: false, vertical: true)
        .background { ScreenGround() }
    }

    private func passage(_ title: String, text: String, area: ReadingArea) -> some View {
        VStack(alignment: .leading, spacing: Design.Space.small) {
            Text(title).typeRole(.metadata).foregroundStyle(Design.Palette.areaLabel(area))
            Text(text).typeRole(Design.TypeRole.body).lineSpacing(Design.Space.readingLeading)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func disclaimer(_ text: String) -> some View {
        Text(text).typeRole(Design.TypeRole.caption).foregroundStyle(Design.Palette.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }
}
