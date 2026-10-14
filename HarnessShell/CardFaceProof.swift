#if DEBUG
import SwiftUI

/// Real-app rendering evidence, reachable only with explicit Debug test launch arguments.
struct CardFaceProof: View {
    var sizes = false
    var largestText = false
    @Environment(\.dynamicTypeSize) private var systemTextSize
    @State private var page = 0
    private let sizeSamples = [17, 31, 46, 59, 76, 35, 49, 63, 77]

    var body: some View {
        ReadingScreenLayout {
            VStack(spacing: Design.Space.section) {
                Text(sizes ? "Card sizes" : "Card faces \(page * 3 + 1)–\(page * 3 + 3) of 78")
                    .typeRole(Design.TypeRole.title)
                    .accessibilityIdentifier("face-proof-title")
                if sizes {
                    let face = CardIdentity.deck[sizeSamples[page]]
                    Text(face.name).typeRole(.section)
                    ForEach([214, 120, 84, 36], id: \.self) { width in
                        VStack(spacing: Design.Space.small) {
                            Text("\(width) points · Reversed").typeRole(Design.TypeRole.caption)
                            TarotCardView(face: face, orientation: .reversed, width: CGFloat(width))
                                .accessibilityIdentifier("face-size-\(width)")
                        }
                    }
                } else {
                    ForEach(page * 3..<page * 3 + 3, id: \.self) { index in
                        let face = CardIdentity.deck[index]
                        VStack(spacing: Design.Space.small) {
                            Text(face.name)
                                .typeRole(.label)
                                .accessibilityIdentifier("face-name-\(index)")
                            HStack(spacing: Design.Space.large) {
                                faceSample(face, index: index, orientation: .upright)
                                faceSample(face, index: index, orientation: .reversed)
                            }
                        }
                    }
                }
            }
            .foregroundStyle(Design.Palette.ink)
            .padding(Design.Space.page)
            .frame(maxWidth: .infinity)
            .id(page)
        } footer: {
            PrimaryAction(title: lastPage ? "Start again" : "Next cards") {
                page = lastPage ? 0 : page + 1
            }
            .accessibilityIdentifier("face-proof-next")
        }
        .environment(\.dynamicTypeSize, largestText ? .accessibility5 : systemTextSize)
    }

    private var lastPage: Bool { page == (sizes ? sizeSamples.count - 1 : 25) }

    private func faceSample(_ face: CardIdentity, index: Int, orientation: Orientation) -> some View {
        VStack(spacing: Design.Space.small) {
            TarotCardView(face: face, orientation: orientation, width: 72)
                .accessibilityIdentifier("face-\(index)-\(orientation.rawValue)")
            Text(orientation.label).typeRole(Design.TypeRole.caption)
        }
    }
}
#endif
