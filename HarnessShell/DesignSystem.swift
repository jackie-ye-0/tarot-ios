import SwiftUI

// All visual primitives live here; screens choose semantic roles and shared components.
enum Design {
    enum Palette {
        static let ground = colour(0xf3e4dc)
        static let surface = colour(0xfbf4ef)
        static let ink = colour(0x43302b)
        static let secondary = colour(0x6b524b)
        static let hairline = colour(0xe3cdc3)
        static let night = colour(0x1b1430)
        static let disc = colour(0x2b2050)
        static let cardBack = colour(0x2b1f47)
        static let gold = colour(0xe2b65c)
        static let cream = colour(0xf6ecdf)
        static let nightSecondary = colour(0xc9bcd8)
        static let blue = colour(0x6f8ca2)
        static let clay = colour(0xb0654a)
        static let sage = colour(0x7d8f6a)
        static let ochre = colour(0xc79a3f)

        private static func colour(_ value: UInt32) -> Color {
            Color(red: Double((value >> 16) & 255) / 255,
                  green: Double((value >> 8) & 255) / 255, blue: Double(value & 255) / 255)
        }
    }

    enum Space {
        static let small: CGFloat = 8
        static let related: CGFloat = 12
        static let group: CGFloat = 16
        static let page: CGFloat = 20
        static let ritual: CGFloat = 24
        static let section: CGFloat = 28
        static let large: CGFloat = 32
        static let titleWidth: CGFloat = 300
        static let target: CGFloat = 44
        static let button: CGFloat = 56
    }

    enum TypeRole {
        case display, title, section, button, body, secondary, label, caption

        var font: Font {
            switch self {
            case .display: .custom("Gabarito-Regular", size: 42, relativeTo: .largeTitle).weight(.bold)
            case .title: .custom("Gabarito-Regular", size: 30, relativeTo: .title).weight(.semibold)
            case .section: .custom("Gabarito-Regular", size: 22, relativeTo: .title2).weight(.semibold)
            case .button: .custom("Gabarito-Regular", size: 18, relativeTo: .headline).weight(.semibold)
            case .body: .custom("HankenGrotesk-Regular", size: 17, relativeTo: .body)
            case .secondary: .custom("HankenGrotesk-Regular", size: 15, relativeTo: .subheadline)
            case .label: .custom("HankenGrotesk-Regular", size: 14, relativeTo: .subheadline).weight(.semibold)
            case .caption: .custom("HankenGrotesk-Regular", size: 13, relativeTo: .footnote)
            }
        }
        var tracking: CGFloat { self == .display ? -0.84 : self == .title ? -0.3 : 0 }
    }
}

extension View {
    func typeRole(_ role: Design.TypeRole) -> some View {
        font(role.font).tracking(role.tracking)
    }
}

struct ScreenGround: View {
    var night = false
    var body: some View {
        (night ? Design.Palette.night : Design.Palette.ground)
            .overlay {
                Canvas { context, size in
                    var speckles = Path()
                    for i in 0..<Int(size.width * size.height * 0.12) {
                        var bits = UInt64(i) &+ 0x9e3779b97f4a7c15
                        bits = (bits ^ (bits >> 30)) &* 0xbf58476d1ce4e5b9
                        bits = (bits ^ (bits >> 27)) &* 0x94d049bb133111eb
                        bits ^= bits >> 31
                        let x = CGFloat(bits & 65535) / 65535 * size.width
                        let y = CGFloat((bits >> 16) & 65535) / 65535 * size.height
                        let diameter = 0.2 + CGFloat((bits >> 32) & 255) / 255 * 0.35
                        speckles.addEllipse(in: CGRect(x: x, y: y, width: diameter, height: diameter))
                    }
                    context.fill(speckles, with: .color(night ? Design.Palette.cream : Design.Palette.ink))
                }
                .opacity(night ? 0.10 : 0.16)
                .blendMode(night ? .screen : .multiply)
            }
            .ignoresSafeArea()
            .accessibilityHidden(true)
    }
}

struct ActionPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.opacity(configuration.isPressed ? 0.75 : 1)
    }
}

/// Standard-size actions stay pinned; accessibility-size actions follow the scroll content.
struct ReadingScreenLayout<Content: View, Footer: View>: View {
    var night = false
    var fillsAvailableHeight = false
    @ViewBuilder var content: () -> Content
    @ViewBuilder var footer: () -> Footer
    @Environment(\.dynamicTypeSize) private var textSize

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    content()
                        .frame(minHeight: fillsAvailableHeight && !textSize.isAccessibilitySize ? geometry.size.height : nil,
                               alignment: .top)
                    if textSize.isAccessibilitySize {
                        actions.padding(.top, Design.Space.section)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .accessibilityIdentifier("screen-content")
            .clipped()
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if !textSize.isAccessibilitySize { actions }
        }
        .background { ScreenGround(night: night) }
        .preferredColorScheme(night ? .dark : .light)
    }

    private var actions: some View {
        footer()
            .padding(.horizontal, Design.Space.ritual)
            .padding(.bottom, Design.Space.related)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("screen-footer")
            .background { ScreenGround(night: night) }
    }
}

struct PrimaryAction: View {
    let title: String
    var night = false
    var arrow = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Design.Space.related) {
                Text(title).fixedSize(horizontal: false, vertical: true)
                if arrow { Image(systemName: "arrow.right").accessibilityHidden(true) }
            }
            .typeRole(.button)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, Design.Space.group)
            .padding(.vertical, Design.Space.group)
            .frame(minHeight: Design.Space.button)
            .foregroundStyle(night ? Design.Palette.night : Design.Palette.surface)
            .background(night ? Design.Palette.cream : Design.Palette.ink, in: Capsule())
            .contentShape(Capsule())
        }
        .buttonStyle(ActionPressStyle())
    }
}

struct QuietAction: View {
    let title: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title)
                .typeRole(.secondary)
                .foregroundStyle(Design.Palette.nightSecondary)
                .frame(minWidth: Design.Space.target, minHeight: Design.Space.target)
                .contentShape(Rectangle())
        }
        .buttonStyle(ActionPressStyle())
    }
}

struct TarotCardView: View {
    let card: TarotCard?
    var orientation: Orientation = .upright
    let width: CGFloat

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: width / 10)
        ZStack {
            shape.fill(card == nil ? Design.Palette.cardBack : Design.Palette.surface)
            Canvas { context, size in
                if let card { drawFront(card, context: &context, size: size) }
                else { drawBack(context: &context, size: size) }
            }
            .clipShape(shape)
            shape.strokeBorder(card == nil ? Design.Palette.gold : Design.Palette.ink,
                               lineWidth: max(1.3, width / 100))
        }
        .frame(width: width, height: width * 1.6)
        .rotationEffect(.degrees(orientation == .reversed ? 180 : 0))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(card.map { "\($0.name), \(orientation.label)" } ?? "Face-down card")
    }

    private func drawBack(context: inout GraphicsContext, size: CGSize) {
        let w = size.width
        let h = size.height
        let gold = Design.Palette.gold
        context.stroke(Path(roundedRect: CGRect(x: w * 0.08, y: w * 0.08, width: w * 0.84, height: h - w * 0.16),
                            cornerRadius: w * 0.065), with: .color(gold.opacity(0.45)), lineWidth: w * 0.006)
        let centre = CGPoint(x: w * 0.5, y: h * 0.62)
        let radius = w * 0.22
        var sun = Path()
        sun.addArc(center: centre, radius: radius, startAngle: .degrees(180), endAngle: .zero, clockwise: false)
        sun.closeSubpath()
        context.fill(sun, with: .color(gold))
        var lines = Path()
        for i in 0...4 {
            let angle = Double(i) * .pi / 4
            let start = w * 0.29
            let end = w * 0.39
            lines.move(to: CGPoint(x: centre.x + cos(angle) * start, y: centre.y - sin(angle) * start))
            lines.addLine(to: CGPoint(x: centre.x + cos(angle) * end, y: centre.y - sin(angle) * end))
        }
        lines.move(to: CGPoint(x: w * 0.17, y: centre.y))
        lines.addLine(to: CGPoint(x: w * 0.83, y: centre.y))
        context.stroke(lines, with: .color(gold), style: StrokeStyle(lineWidth: w * 0.014, lineCap: .round))
        var water = Path()
        for i in 1...2 {
            water.move(to: CGPoint(x: w * (0.23 + Double(i) * 0.05), y: centre.y + Double(i) * w * 0.11))
            water.addLine(to: CGPoint(x: w * (0.77 - Double(i) * 0.05), y: centre.y + Double(i) * w * 0.11))
        }
        context.stroke(water, with: .color(gold.opacity(0.5)), lineWidth: w * 0.008)
    }

    private func drawFront(_ card: TarotCard, context: inout GraphicsContext, size: CGSize) {
        let w = size.width
        let h = size.height
        let inset = w * 0.06
        let inner = CGRect(x: inset, y: inset, width: w - inset * 2, height: h - inset * 2)
        context.clip(to: Path(roundedRect: inner, cornerRadius: w * 0.075))
        context.fill(Path(inner), with: .color(Design.Palette.blue.opacity(0.6)))
        var hills = Path()
        hills.move(to: CGPoint(x: 0, y: h * 0.67))
        hills.addCurve(to: CGPoint(x: w, y: h * 0.67), control1: CGPoint(x: w * 0.4, y: h * 0.56), control2: CGPoint(x: w * 0.6, y: h * 0.79))
        hills.addLine(to: CGPoint(x: w, y: h)); hills.addLine(to: CGPoint(x: 0, y: h)); hills.closeSubpath()
        context.fill(hills, with: .color(Design.Palette.sage))
        var earth = Path()
        earth.move(to: CGPoint(x: 0, y: h * 0.9))
        earth.addCurve(to: CGPoint(x: w, y: h * 0.93), control1: CGPoint(x: w * 0.5, y: h * 0.77), control2: CGPoint(x: w * 0.6, y: h))
        earth.addLine(to: CGPoint(x: w, y: h)); earth.addLine(to: CGPoint(x: 0, y: h)); earth.closeSubpath()
        context.fill(earth, with: .color(Design.Palette.clay))
        for index in 0..<2 {
            let y = h * (0.75 + Double(index) * 0.08)
            var wave = Path()
            wave.move(to: CGPoint(x: w * 0.1, y: y))
            wave.addCurve(to: CGPoint(x: w * 0.9, y: y), control1: CGPoint(x: w * 0.46, y: y - h * 0.07), control2: CGPoint(x: w * 0.54, y: y + h * 0.07))
            context.stroke(wave, with: .color(Design.Palette.surface.opacity(index == 0 ? 1 : 0.6)), lineWidth: w * 0.008)
        }
        let centre = CGPoint(x: w * 0.5, y: h * 0.34)
        if card.rank == 17 {
            var star = Path()
            let points: [(Double, Double)] = [(0,-0.3),(0.06,-0.06),(0.3,0),(0.06,0.06),(0,0.3),(-0.06,0.06),(-0.3,0),(-0.06,-0.06)]
            star.addLines(points.map { CGPoint(x: centre.x + $0.0 * w, y: centre.y + $0.1 * w) }); star.closeSubpath()
            context.fill(star, with: .color(Design.Palette.ochre))
            context.stroke(star, with: .color(Design.Palette.ink), lineWidth: w * 0.009)
            var glow = context
            glow.translateBy(x: centre.x * 0.52, y: centre.y * 0.52)
            glow.scaleBy(x: 0.48, y: 0.48)
            glow.fill(star, with: .color(Design.Palette.surface))
        } else {
            let radius = w * (0.16 + Double(card.rank % 3) * 0.025)
            let sun = Path(ellipseIn: CGRect(x: centre.x - radius, y: centre.y - radius, width: radius * 2, height: radius * 2))
            context.fill(sun, with: .color(Design.Palette.ochre))
            context.stroke(sun, with: .color(Design.Palette.ink), lineWidth: w * 0.009)
            var rays = Path()
            let count = 5 + card.rank % 7
            for i in 0..<count {
                let a = Double(i) * .pi * 2 / Double(count)
                rays.move(to: CGPoint(x: centre.x + cos(a) * radius * 1.22, y: centre.y + sin(a) * radius * 1.22))
                rays.addLine(to: CGPoint(x: centre.x + cos(a) * radius * 1.5, y: centre.y + sin(a) * radius * 1.5))
            }
            context.stroke(rays, with: .color(Design.Palette.ink), lineWidth: w * 0.009)
        }
        for point in [(0.22,0.23),(0.79,0.21),(0.17,0.48),(0.83,0.48)] {
            let dot = Path(ellipseIn: CGRect(x: w * point.0 - w * 0.017, y: h * point.1 - w * 0.017, width: w * 0.034, height: w * 0.034))
            context.fill(dot, with: .color(Design.Palette.surface))
            context.stroke(dot, with: .color(Design.Palette.ink), lineWidth: w * 0.006)
        }
    }
}

struct CardFan: View {
    @Binding var selected: Int?
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let cardWidth = min(120, width * 0.32)
            ZStack {
                Circle().fill(Design.Palette.disc)
                    .frame(width: width * 1.25, height: width * 1.25)
                ForEach(1...5, id: \.self) { position in
                    let distance = CGFloat(position - 3)
                    TarotCardView(card: nil, width: cardWidth)
                        .rotationEffect(.degrees(selected == position ? 0 : Double(distance) * 8))
                        .offset(x: distance * width * 0.205,
                                y: selected == position ? -48 : abs(distance) * 13 + 16)
                        .opacity(selected == nil || selected == position ? 1 : 0.32)
                        .zIndex(selected == position ? 1 : 0)
                        .accessibilityHidden(true)
                }
                // Separate, non-overlapping hit lanes preserve all five targets through selection.
                HStack(spacing: 0) {
                    ForEach(1...5, id: \.self) { position in
                        Button { selected = position } label: {
                            Rectangle().fill(.clear)
                                .frame(maxWidth: .infinity, minHeight: 240)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(ActionPressStyle())
                        .accessibilityIdentifier("draw-card-\(position)")
                        .accessibilityLabel("Card \(position) of 5")
                        .accessibilityAddTraits(selected == position ? .isSelected : [])
                    }
                }
            }
            .frame(width: width, height: geometry.size.height)
        }
        .frame(height: 360)
    }
}
