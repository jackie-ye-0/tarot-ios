import SwiftUI

// All visual primitives live here; screens choose semantic roles and shared components.
enum Design {
    enum Motion {
        static let washDuration = 0.45
        static let fanDuration = 0.8
        static let wash = Animation.easeInOut(duration: washDuration)
        static let fanOut = Animation.timingCurve(0.16, 1, 0.3, 1, duration: fanDuration)
        static let entrance = Animation.timingCurve(0.16, 1, 0.3, 1, duration: 0.65)
        static let flip = Animation.easeInOut(duration: 1.1)
        static let dawn = Animation.easeInOut(duration: 1.6)
        static let textDelay = 0.85
        static let stagger = 0.08
    }

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
        static let controlTrack = colour(0xead6cd)
        static let surfaceHairline = colour(0xefe2dc)
        static let careerLabel = colour(0x3f596d)
        static let relationshipLabel = colour(0x8a4a33)
        static let socialLabel = colour(0x4d5e3d)

        static func accent(for area: ReadingArea) -> Color {
            switch area {
            case .career: blue
            case .relationship: clay
            case .social: sage
            }
        }

        static func label(for area: ReadingArea) -> Color {
            switch area {
            case .career: careerLabel
            case .relationship: relationshipLabel
            case .social: socialLabel
            }
        }

        static func swatch(hex: String) -> Color {
            // Library validation requires a six-digit hex; saved values retain that colour.
            colour(UInt32(hex.dropFirst(), radix: 16) ?? 0x43302b)
        }

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
        static let titleWidth: CGFloat = 260
        static let drawHeadingHeight: CGFloat = 108
        static let readingLeading: CGFloat = 4
        static let target: CGFloat = 44
        static let button: CGFloat = 56
    }

    enum TypeRole {
        case display, compactDisplay, title, section, button, body, keywords, metadata, secondary, label, caption

        var font: Font {
            switch self {
            case .display: .custom("Gabarito-Regular", size: 44, relativeTo: .largeTitle).weight(.bold)
            case .compactDisplay: .custom("Gabarito-Regular", size: 40, relativeTo: .largeTitle).weight(.bold)
            case .title: .custom("Gabarito-Regular", size: 30, relativeTo: .title).weight(.semibold)
            case .section: .custom("Gabarito-Regular", size: 22, relativeTo: .title2).weight(.semibold)
            case .button: .custom("Gabarito-Regular", size: 18, relativeTo: .headline).weight(.semibold)
            case .body: .custom("HankenGrotesk-Regular", size: 17, relativeTo: .body)
            case .keywords: .custom("HankenGrotesk-Regular", size: 16, relativeTo: .body)
            case .metadata: .custom("HankenGrotesk-Regular", size: 16, relativeTo: .body).weight(.semibold)
            case .secondary: .custom("HankenGrotesk-Regular", size: 15, relativeTo: .subheadline)
            case .label: .custom("HankenGrotesk-Regular", size: 14, relativeTo: .subheadline).weight(.semibold)
            case .caption: .custom("HankenGrotesk-Regular", size: 13, relativeTo: .footnote)
            }
        }
        var tracking: CGFloat { self == .display ? -0.88 : self == .compactDisplay ? -0.8 : self == .title ? -0.3 : 0 }
    }
}

extension View {
    @ViewBuilder func testMotionState(enabled: Bool, settled: Bool) -> some View {
        #if DEBUG
        if enabled { accessibilityValue(settled ? "settled" : "animating") }
        else { self }
        #else
        self
        #endif
    }

    func typeRole(_ role: Design.TypeRole) -> some View {
        font(role.font).tracking(role.tracking)
    }
}

/// A reusable, deterministic fine-grain tile, generated once rather than per screen frame.
private struct GroundGrain: View {
    let night: Bool
    private static let nightTile = makeTile(night: true)
    private static let dawnTile = makeTile(night: false)

    var body: some View {
        Image(decorative: night ? Self.nightTile : Self.dawnTile, scale: 2)
            .resizable(resizingMode: .tile)
            .interpolation(.none)
            .opacity(night ? 0.10 : 0.16)
            .blendMode(night ? .screen : .multiply)
            .accessibilityHidden(true)
    }

    private static func makeTile(night: Bool) -> CGImage {
        let side = 192
        var pixels = [UInt8](repeating: 0, count: side * side)
        for index in pixels.indices {
            var bits = UInt64(index) &+ 0x9e3779b97f4a7c15
            bits = (bits ^ (bits >> 30)) &* 0xbf58476d1ce4e5b9
            bits = (bits ^ (bits >> 27)) &* 0x94d049bb133111eb
            bits ^= bits >> 31
            pixels[index] = night ? UInt8(bits & 127) : 128 + UInt8(bits & 127)
        }
        let data = CGDataProvider(data: Data(pixels) as CFData)!
        return CGImage(width: side, height: side, bitsPerComponent: 8, bitsPerPixel: 8,
                       bytesPerRow: side, space: CGColorSpaceCreateDeviceGray(),
                       bitmapInfo: CGBitmapInfo(rawValue: 0), provider: data,
                       decode: nil, shouldInterpolate: false, intent: .defaultIntent)!
    }
}

struct ScreenGround: View {
    var night = false
    var body: some View {
        (night ? Design.Palette.night : Design.Palette.ground)
            .overlay { GroundGrain(night: night) }
            .ignoresSafeArea()
            .accessibilityHidden(true)
    }
}

struct RevealGround: View {
    var progress: Double
    var body: some View {
        ScreenGround(night: true)
            .overlay { ScreenGround().opacity(progress) }
            .accessibilityHidden(true)
    }
}

/// A thin glyph halo keeps the persistent copy readable while the ground crosses mid-tones.
/// Switch complete contrast pairs rather than interpolating foreground through the ground.
struct RevealPersistentCopy: ViewModifier, Animatable {
    var progress: Double
    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func body(content: Content) -> some View {
        let dawn = progress >= 0.5
        let halo = min(1, min(progress / 0.15, (1 - progress) / 0.04))
        let backing = (dawn ? Design.Palette.ground : Design.Palette.night).opacity(max(0, halo))
        content
            .foregroundStyle(dawn ? Design.Palette.secondary : Design.Palette.nightSecondary)
            // Raster shadows preserve a single text/accessibility element.
            .shadow(color: backing, radius: 0, x: 1)
            .shadow(color: backing, radius: 0, x: -1)
            .shadow(color: backing, radius: 0, y: 1)
            .shadow(color: backing, radius: 0, y: -1)
            // Progress already interpolates this modifier. Never tween the pair itself.
            .transaction { $0.animation = nil; $0.disablesAnimations = true }
    }
}

struct RevealStatusBar: ViewModifier, Animatable {
    var progress: Double
    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func body(content: Content) -> some View {
        content.preferredColorScheme(progress < 0.47 ? .dark : .light)
    }
}

struct RevealSun: View {
    let risen: Bool
    var body: some View {
        Circle()
            .fill(RadialGradient(colors: [Design.Palette.ochre.opacity(0.28), Design.Palette.ochre.opacity(0)],
                                 center: .center, startRadius: 50, endRadius: 180))
            .frame(width: 360, height: 360)
            .offset(y: risen ? -30 : 60)
            .opacity(risen ? 1 : 0)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

struct RevealTextRise: ViewModifier {
    let visible: Bool
    let animated: Bool
    let index: Int

    func body(content: Content) -> some View {
        content
            .opacity(visible ? 1 : 0)
            .offset(y: visible ? 0 : Design.Space.related)
            .animation(animated ? Design.Motion.entrance.delay(Design.Motion.textDelay + Double(index) * Design.Motion.stagger) : nil,
                       value: visible)
    }
}

/// Both faces share one interpolated angle, switching only when the card is edge-on.
struct TurningTarotCard: View, Animatable {
    let draw: DailyDraw
    var progress: Double
    let width: CGFloat
    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    var body: some View {
        ZStack {
            TarotCardView(card: nil, width: width).opacity(progress < 0.5 ? 1 : 0)
            TarotCardView(card: draw.card, orientation: draw.orientation, width: width)
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                .opacity(progress < 0.5 ? 0 : 1)
        }
        .rotation3DEffect(.degrees(progress * 180), axis: (x: 0, y: 1, z: 0), perspective: 0.35)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(draw.card.name), \(draw.orientation.label)")
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
    var dawnProgress: Double? = nil
    var dawnAnimation: Animation? = nil
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
        .background { ground }
        .modifier(RevealStatusBar(progress: dawnProgress ?? (night ? 0 : 1)))
        .animation(dawnAnimation, value: dawnProgress)
    }

    private var actions: some View {
        footer()
            .padding(.horizontal, Design.Space.ritual)
            .padding(.bottom, Design.Space.related)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("screen-footer")
            .background { ground }
    }

    @ViewBuilder private var ground: some View {
        if let dawnProgress {
            RevealGround(progress: dawnProgress).animation(dawnAnimation, value: dawnProgress)
        } else { ScreenGround(night: night) }
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
    var underlined = false
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title)
                .typeRole(underlined ? .button : .secondary)
                .foregroundStyle(underlined ? Design.Palette.cream : Design.Palette.nightSecondary)
                // Keep the gold rule separate so the contrast audit can assess the text colour.
                .overlay(alignment: .bottom) {
                    if underlined {
                        Rectangle().fill(Design.Palette.gold)
                            .frame(height: 1)
                            .offset(y: 3)
                            .allowsHitTesting(false)
                            .accessibilityHidden(true)
                    }
                }
                .frame(minWidth: Design.Space.target, minHeight: Design.Space.target)
                .contentShape(Rectangle())
        }
        .buttonStyle(ActionPressStyle())
    }
}

struct BackToTodayAction: View {
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.left")
                .resizable().scaledToFit().frame(width: 12, height: 20)
                .foregroundStyle(Design.Palette.ink)
                .frame(width: Design.Space.target, height: Design.Space.target)
                .contentShape(Rectangle())
        }
        .buttonStyle(ActionPressStyle())
        .accessibilityLabel("Back to Today")
        .accessibilityIdentifier("back-to-today")
    }
}

struct CardExpansionMark: View {
    var body: some View {
        Image(systemName: "arrow.up.left.and.arrow.down.right")
            .resizable().scaledToFit().frame(width: 14, height: 14)
            .rotationEffect(.degrees(90))
            .foregroundStyle(Design.Palette.surface)
            .frame(width: 28, height: 28)
            .background(Design.Palette.ink, in: Circle())
            .padding(4)
            .accessibilityHidden(true)
    }
}

struct DailyExtrasView: View {
    let daily: DailyContent
    @Environment(\.dynamicTypeSize) private var textSize

    var body: some View {
        VStack(spacing: Design.Space.group) {
            Rectangle().fill(Design.Palette.hairline).frame(height: 1).accessibilityHidden(true)
            let layout = textSize.isAccessibilitySize
                ? AnyLayout(VStackLayout(alignment: .leading, spacing: Design.Space.group))
                : AnyLayout(HStackLayout(alignment: .top, spacing: Design.Space.related))
            layout {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Circle().fill(Design.Palette.swatch(hex: daily.colourHex)).frame(width: 10, height: 10)
                        Text("Colour").typeRole(.caption).foregroundStyle(Design.Palette.secondary)
                    }
                    Text(daily.colourName).typeRole(.metadata)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Colour, \(daily.colourName)")
                .accessibilityIdentifier("daily-colour")
                if !textSize.isAccessibilitySize { Divider().overlay(Design.Palette.hairline) }
                extra("Object", value: daily.object, identifier: "daily-object")
                if !textSize.isAccessibilitySize { Divider().overlay(Design.Palette.hairline) }
                extra("Best hour", value: daily.bestHour, identifier: "daily-hour")
            }
            .fixedSize(horizontal: false, vertical: true)
            Rectangle().fill(Design.Palette.hairline).frame(height: 1).accessibilityHidden(true)
        }
    }

    private func extra(_ title: String, value: String, identifier: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).typeRole(.caption).foregroundStyle(Design.Palette.secondary)
            Text(value).typeRole(.metadata)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title), \(value)")
        .accessibilityIdentifier(identifier)
    }
}

struct DailyScoreStrip: View {
    let daily: DailyContent
    @Environment(\.dynamicTypeSize) private var textSize

    var body: some View {
        let layout = textSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Design.Space.group))
            : AnyLayout(HStackLayout(alignment: .top, spacing: Design.Space.related))
        layout {
            ForEach(ReadingArea.allCases, id: \.self) { area in
                let score = daily.reading(for: area).score
                VStack(alignment: .leading, spacing: Design.Space.small) {
                    Text(area.label).typeRole(.label).foregroundStyle(Design.Palette.label(for: area))
                        .accessibilityIdentifier("score-label-\(area.rawValue)")
                    Text(score.formatted()).typeRole(.title)
                    GeometryReader { geometry in
                        Capsule().fill(Design.Palette.accent(for: area))
                            .frame(width: geometry.size.width * Double(score) / 100)
                    }
                    .frame(height: 6)
                    .background(Design.Palette.controlTrack, in: Capsule())
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(area.label), \(score) out of 100")
                .accessibilityIdentifier("score-\(area.rawValue)")
            }
        }
    }
}

struct DailyAreaLines: View {
    let daily: DailyContent
    var body: some View {
        VStack(spacing: 0) {
            ForEach(ReadingArea.allCases, id: \.self) { area in
                if area != .career {
                    Rectangle().fill(Design.Palette.surfaceHairline).frame(height: 1).accessibilityHidden(true)
                }
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: Design.Space.small) {
                        Circle().fill(Design.Palette.accent(for: area)).frame(width: 8, height: 8)
                            .accessibilityHidden(true)
                        Text(area.label).typeRole(.label).foregroundStyle(Design.Palette.label(for: area))
                            .accessibilityIdentifier("area-label-\(area.rawValue)")
                    }
                    Text(daily.reading(for: area).line).typeRole(.body)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("line-\(area.rawValue)")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Design.Space.group)
            }
        }
        .background(Design.Palette.surface, in: RoundedRectangle(cornerRadius: 20))
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
        .compositingGroup()
        .shadow(color: Design.Palette.ink.opacity(card == nil ? 0 : 0.18),
                radius: width * 0.10, x: 0, y: width * 0.08)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(card.map { "\($0.name), \(orientation.label)" } ?? "Face-down card")
    }

    private func drawBack(context: inout GraphicsContext, size: CGSize) {
        let w = size.width
        let h = size.height
        let gold = Design.Palette.gold
        context.stroke(Path(roundedRect: CGRect(x: w * 0.08, y: w * 0.08, width: w * 0.84, height: h - w * 0.16),
                            cornerRadius: w * 0.065), with: .color(gold.opacity(0.45)), lineWidth: w * 0.006)
        let centre = CGPoint(x: w * 0.5, y: h * 0.665)
        let radius = w * 0.21
        var sun = Path()
        sun.addArc(center: centre, radius: radius, startAngle: .degrees(180), endAngle: .zero, clockwise: false)
        sun.closeSubpath()
        context.fill(sun, with: .color(gold))
        var lines = Path()
        for degrees in [20.0, 48, 90, 132, 160] {
            let angle = degrees * .pi / 180
            let start = w * 0.29
            let end = w * 0.41
            lines.move(to: CGPoint(x: centre.x + cos(angle) * start, y: centre.y - sin(angle) * start))
            lines.addLine(to: CGPoint(x: centre.x + cos(angle) * end, y: centre.y - sin(angle) * end))
        }
        lines.move(to: CGPoint(x: w * 0.17, y: centre.y))
        lines.addLine(to: CGPoint(x: w * 0.83, y: centre.y))
        context.stroke(lines, with: .color(gold), style: StrokeStyle(lineWidth: w * 0.014, lineCap: .round))
        var water = Path()
        for i in 1...2 {
            water.move(to: CGPoint(x: w * (0.18 + Double(i) * 0.09), y: centre.y + Double(i) * w * 0.105))
            water.addLine(to: CGPoint(x: w * (0.82 - Double(i) * 0.09), y: centre.y + Double(i) * w * 0.105))
        }
        context.stroke(water, with: .color(gold.opacity(0.5)), lineWidth: w * 0.008)
    }

    private func drawFront(_ card: TarotCard, context: inout GraphicsContext, size: CGSize) {
        let w = size.width
        let h = size.height
        let inset = w * 0.06
        let inner = CGRect(x: inset, y: inset, width: w - inset * 2, height: h - inset * 2)
        // Round only the sky's upper corners; the landscape ends square inside the card frame.
        let radius = w * 0.075
        var crop = Path()
        crop.move(to: CGPoint(x: inner.minX, y: inner.maxY))
        crop.addLine(to: CGPoint(x: inner.minX, y: inner.minY + radius))
        crop.addQuadCurve(to: CGPoint(x: inner.minX + radius, y: inner.minY), control: inner.origin)
        crop.addLine(to: CGPoint(x: inner.maxX - radius, y: inner.minY))
        crop.addQuadCurve(to: CGPoint(x: inner.maxX, y: inner.minY + radius), control: CGPoint(x: inner.maxX, y: inner.minY))
        crop.addLine(to: CGPoint(x: inner.maxX, y: inner.maxY))
        crop.closeSubpath()
        context.clip(to: crop)
        context.fill(Path(inner), with: .color(Design.Palette.blue.opacity(0.6)))
        let horizonY = h * 0.66
        context.fill(Path(CGRect(x: 0, y: horizonY, width: w, height: h - horizonY)), with: .color(Design.Palette.surface))
        var hills = Path()
        hills.move(to: CGPoint(x: 0, y: horizonY))
        hills.addCurve(to: CGPoint(x: w, y: horizonY), control1: CGPoint(x: w * 0.4, y: h * 0.59), control2: CGPoint(x: w * 0.6, y: h * 0.73))
        hills.addLine(to: CGPoint(x: w, y: h)); hills.addLine(to: CGPoint(x: 0, y: h)); hills.closeSubpath()
        context.fill(hills, with: .color(Design.Palette.sage))
        var horizon = Path()
        horizon.move(to: CGPoint(x: inner.minX, y: horizonY))
        horizon.addLine(to: CGPoint(x: inner.maxX, y: horizonY))
        context.stroke(horizon, with: .color(Design.Palette.ink), lineWidth: w * 0.009)
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

enum FanPhase {
    case gathered, washLeft, washRight, fanned
}

struct CardFan: View {
    let selected: Int?
    var phase = FanPhase.fanned
    var order = Array(1...5)
    let choose: (Int) -> Void
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let cardWidth = min(112, width * 0.33)
            let selectedWidth = min(124, width * 0.365)
            ZStack {
                ForEach(1...5, id: \.self) { identity in
                    let position = (order.firstIndex(of: identity) ?? 0) + 1
                    let distance = CGFloat(position - 3)
                    TarotCardView(card: nil, width: cardWidth)
                        .scaleEffect(selected == position ? selectedWidth / cardWidth : 1)
                        .rotationEffect(.degrees(rotation(distance: distance, selected: selected == position)))
                        .offset(x: horizontalOffset(distance: distance, width: width),
                                y: verticalOffset(distance: distance, selected: selected == position))
                        .opacity(selected == nil || selected == position ? 1 : 0.32)
                        .zIndex(selected == position ? 6 : Double(position))
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
                // Separate, non-overlapping hit lanes preserve all five targets through selection.
                HStack(spacing: 0) {
                    ForEach(1...5, id: \.self) { position in
                        Button { choose(position) } label: {
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
                .zIndex(10) // The fixed controls stay above every animated decorative card.
            }
            .frame(width: width, height: geometry.size.height)
            .background {
                Circle().fill(Design.Palette.disc)
                    .overlay { GroundGrain(night: true).clipShape(Circle()) }
                    .frame(width: width * 1.345, height: width * 1.345)
            }
        }
        .frame(height: 360)
    }

    private func horizontalOffset(distance: CGFloat, width: CGFloat) -> CGFloat {
        switch phase {
        case .gathered: distance * width * 0.04
        case .washLeft: -distance * width * 0.12
        case .washRight: distance * width * 0.15
        case .fanned: distance * width * 0.20
        }
    }

    private func verticalOffset(distance: CGFloat, selected chosen: Bool) -> CGFloat {
        switch phase {
        case .gathered: abs(distance) * 4 + 20
        case .washLeft: distance * 12 + 20
        case .washRight: -distance * 12 + 20
        case .fanned: chosen ? -27 : abs(distance) * 18 + (selected == nil ? 20 : 0)
        }
    }

    private func rotation(distance: CGFloat, selected chosen: Bool) -> Double {
        switch phase {
        case .gathered: Double(distance) * 3
        case .washLeft: Double(-distance) * 12
        case .washRight: Double(distance) * 12
        case .fanned: chosen ? 0 : Double(distance) * 8
        }
    }
}
