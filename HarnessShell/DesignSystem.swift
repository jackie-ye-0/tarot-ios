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
        static let welcomeFloat = Animation.easeInOut(duration: 3).repeatForever(autoreverses: true)
        static let activeSlotPulse = Animation.easeInOut(duration: 2).repeatForever(autoreverses: true)
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
        static let nightHairline = nightSecondary.opacity(0.3)
        static let nightParagraph = colour(0xd8cce4)
        static let blue = colour(0x6f8ca2)
        static let clay = colour(0xb0654a)
        static let sage = colour(0x7d8f6a)
        static let ochre = colour(0xc79a3f)
        static let placeholder = colour(0x7a5f57)
        static let controlTrack = colour(0xead6cd)
        static let controlBorder = colour(0xe0c9bf)
        static let disabled = colour(0xdcc6bc)
        static let disabledInk = colour(0x5f4740)
        static let error = colour(0xa3331f)
        static let surfaceHairline = colour(0xefe2dc)
        static let careerLabel = colour(0x415c70)
        static let relationshipLabel = colour(0x88452f)
        static let socialLabel = colour(0x4b5b3e)
        static let dailyCareerLabel = colour(0x3f596d)
        static let dailyRelationshipLabel = colour(0x8a4a33)
        static let dailySocialLabel = colour(0x4d5e3d)

        static func accent(for area: ReadingArea) -> Color {
            switch area {
            case .career: blue
            case .relationship: clay
            case .social: sage
            }
        }

        static func areaTint(_ area: ReadingArea) -> Color {
            switch area {
            case .career: colour(0xdfe5ea)
            case .relationship: colour(0xf0d6cb)
            case .social: colour(0xe2e6d9)
            }
        }

        static func label(for area: ReadingArea) -> Color {
            switch area {
            case .career: dailyCareerLabel
            case .relationship: dailyRelationshipLabel
            case .social: dailySocialLabel
            }
        }
        static func areaLabel(_ area: ReadingArea) -> Color {
            switch area {
            case .career: careerLabel
            case .relationship: relationshipLabel
            case .social: socialLabel
            }
        }

        static func swatch(_ colour: DailyColour) -> Color {
            self.colour(colour.rgb)
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
        case display, compactDisplay, title, section, wordmark, button, body, keywords, metadata, secondary, label, caption, tab

        var font: Font {
            switch self {
            case .display: .custom("Gabarito-Regular", size: 44, relativeTo: .largeTitle).weight(.bold)
            case .compactDisplay: .custom("Gabarito-Regular", size: 40, relativeTo: .largeTitle).weight(.bold)
            case .title: .custom("Gabarito-Regular", size: 30, relativeTo: .title).weight(.semibold)
            case .section: .custom("Gabarito-Regular", size: 22, relativeTo: .title2).weight(.semibold)
            // The app name takes the reference's cut: the smallest section size, in the display weight.
            case .wordmark: .custom("Gabarito-Regular", size: 20, relativeTo: .title2).weight(.bold)
            case .button: .custom("Gabarito-Regular", size: 18, relativeTo: .headline).weight(.semibold)
            case .body: .custom("HankenGrotesk-Regular", size: 17, relativeTo: .body)
            case .keywords: .custom("HankenGrotesk-Regular", size: 16, relativeTo: .body)
            case .metadata: .custom("HankenGrotesk-Regular", size: 16, relativeTo: .body).weight(.semibold)
            case .secondary: .custom("HankenGrotesk-Regular", size: 15, relativeTo: .subheadline)
            case .label: .custom("HankenGrotesk-Regular", size: 14, relativeTo: .subheadline).weight(.semibold)
            case .caption: .custom("HankenGrotesk-Regular", size: 13, relativeTo: .footnote)
            case .tab: .custom("HankenGrotesk-Regular", size: 12, relativeTo: .caption).weight(.semibold)
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

    /// Multi-line display copy uses line height 1.0 to 1.05; Gabarito's own is 1.2.
    @ViewBuilder func displayLineHeight() -> some View {
        // ponytail: iOS 17 keeps the font's own line height, as text renderers arrive in iOS 18.
        // Drop this check when the deployment target reaches iOS 18.
        if #available(iOS 18.0, *) { textRenderer(DisplayLeading()) } else { self }
    }
}

/// Draws each line closer to the last, taking Gabarito's 1.2 line height to Display's 1.04.
/// The text keeps its natural frame: a shorter one clips the last line's descenders.
struct DisplayLeading: TextRenderer {
    func draw(layout: Text.Layout, in context: inout GraphicsContext) {
        let lines = Array(layout)
        let pitch = lines.count > 1 ? lines[1].typographicBounds.origin.y - lines[0].typographicBounds.origin.y : 0
        for (index, line) in lines.enumerated() {
            var lowered = context
            lowered.translateBy(x: 0, y: CGFloat(lines.count - 1 - index) * pitch * (1 - 1.04 / 1.2))
            lowered.draw(line)
        }
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
    var ritualDisc = false
    var body: some View {
        (night ? Design.Palette.night : Design.Palette.ground)
            .overlay { GroundGrain(night: night) }
            .overlay {
                if ritualDisc {
                    GeometryReader { geometry in
                        Circle().fill(Design.Palette.disc)
                            .overlay { GroundGrain(night: true).clipShape(Circle()) }
                            .frame(width: geometry.size.width * 1.345, height: geometry.size.width * 1.345)
                            .position(x: geometry.size.width / 2, y: geometry.size.height * 0.82)
                    }
                }
            }
            .ignoresSafeArea()
            .accessibilityHidden(true)
    }
}

struct WelcomeCard: View {
    let animationsEnabled: Bool
    @State private var floating = false

    var body: some View {
        TarotCardView(card: nil, width: 146)
            .rotationEffect(.degrees(-3))
            // Only this card is lifted off its disc; the Draw card backs stay flat.
            .shadow(color: Design.Palette.night.opacity(0.9), radius: 20, y: 20)
            .offset(y: animationsEnabled && floating ? -6 : 0)
            .animation(animationsEnabled ? Design.Motion.welcomeFloat : nil, value: floating)
            .background {
                Circle().fill(Design.Palette.disc)
                    .overlay { GroundGrain(night: true).clipShape(Circle()) }
                    .frame(width: 460, height: 460)
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .onAppear { floating = animationsEnabled }
            .onChange(of: animationsEnabled) { _, enabled in floating = enabled }
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

private struct TestViewportEnabledKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var testViewportEnabled: Bool {
        get { self[TestViewportEnabledKey.self] }
        set { self[TestViewportEnabledKey.self] = newValue }
    }
}

// Only Debug test launches expose geometry; normal accessibility values are unchanged.
private struct TestViewportValue: ViewModifier {
    let frame: CGRect
    @Environment(\.testViewportEnabled) private var enabled

    @ViewBuilder func body(content: Content) -> some View {
        if enabled {
            content.accessibilityValue("test-viewport:\(frame.minX),\(frame.minY),\(frame.width),\(frame.height)")
        } else { content }
    }
}

/// Standard-size actions stay pinned; accessibility-size actions follow the scroll content.
struct ReadingScreenLayout<Content: View, Footer: View>: View {
    var night = false
    var fillsAvailableHeight = false
    var dawnProgress: Double? = nil
    var dawnAnimation: Animation? = nil
    var ritualDisc = false
    @ViewBuilder var content: () -> Content
    @ViewBuilder var footer: () -> Footer
    @Environment(\.dynamicTypeSize) private var textSize

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    content()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(minHeight: fillsAvailableHeight && !textSize.isAccessibilitySize ? max(0, geometry.size.height) : nil,
                               alignment: .top)
                    if textSize.isAccessibilitySize {
                        actions.padding(.top, Design.Space.section)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .accessibilityIdentifier("screen-content")
            .clipped()
            .modifier(TestViewportValue(frame: geometry.frame(in: .global)))
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if !textSize.isAccessibilitySize { actions }
        }
        .background { ground }
        .modifier(RevealStatusBar(progress: dawnProgress ?? (night ? 0 : 1)))
        .animation(dawnAnimation, value: dawnProgress)
        .preferredColorScheme(night ? .dark : .light)
    }

    private var actions: some View {
        footer()
            .padding(.horizontal, night ? Design.Space.ritual : Design.Space.page)
            .padding(.top, night ? 0 : Design.Space.related)
            .padding(.bottom, Design.Space.related)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("screen-footer")
            .background { if !ritualDisc { ground } }
    }

    @ViewBuilder private var ground: some View {
        if let dawnProgress {
            RevealGround(progress: dawnProgress).animation(dawnAnimation, value: dawnProgress)
        } else { ScreenGround(night: night, ritualDisc: ritualDisc) }
    }
}

struct PrimaryAction: View {
    let title: String
    var night = false
    var arrow = false
    let action: () -> Void
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.dynamicTypeSize) private var textSize

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: textSize.isAccessibilitySize ? 22 : 1000)
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
            .foregroundStyle(!isEnabled ? Design.Palette.disabledInk : night ? Design.Palette.night : Design.Palette.surface)
            .background(!isEnabled ? Design.Palette.disabled : night ? Design.Palette.cream : Design.Palette.ink, in: shape)
            .contentShape(shape)
        }
        .buttonStyle(ActionPressStyle())
    }
}

struct QuietAction: View {
    let title: String
    var underlined = false
    var night = true
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title)
                .typeRole(underlined ? .button : .secondary)
                .foregroundStyle(night ? (underlined ? Design.Palette.cream : Design.Palette.nightSecondary) : Design.Palette.secondary)
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
    let progress: Double
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.left")
                .resizable().scaledToFit().frame(width: 12, height: 20)
                .modifier(RevealPersistentCopy(progress: progress))
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
                        Circle().fill(Design.Palette.swatch(daily.colour)).frame(width: 10, height: 10)
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
    let card: CardIdentity?
    var orientation: Orientation = .upright
    let width: CGFloat
    var night = false

    init(card: TarotCard?, orientation: Orientation = .upright, width: CGFloat, night: Bool = false) {
        self.card = card?.identity
        self.orientation = orientation
        self.width = width
        self.night = night
    }

    init(face: CardIdentity, orientation: Orientation = .upright, width: CGFloat, night: Bool = false) {
        card = face
        self.orientation = orientation
        self.width = width
        self.night = night
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: width / 10)
        ZStack {
            shape.fill(card == nil ? Design.Palette.cardBack : Design.Palette.surface)
            Canvas { context, size in
                if let card {
                    if card.suit == nil && card.rank == 17 { drawStar(context: &context, size: size) }
                    else {
                        context.scaleBy(x: size.width / 100, y: size.height / 160)
                        let drawing = CardFaceDrawing(context: context)
                        drawing.draw(card)
                    }
                }
                else { drawBack(context: &context, size: size) }
            }
            .clipShape(shape)
            .accessibilityHidden(true)
            shape.strokeBorder(card == nil || night ? Design.Palette.gold : Design.Palette.ink,
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

    private func drawStar(context: inout GraphicsContext, size: CGSize) {
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
        var star = Path()
        let points: [(Double, Double)] = [(0,-0.3),(0.06,-0.06),(0.3,0),(0.06,0.06),(0,0.3),(-0.06,0.06),(-0.3,0),(-0.06,-0.06)]
        star.addLines(points.map { CGPoint(x: centre.x + $0.0 * w, y: centre.y + $0.1 * w) }); star.closeSubpath()
        context.fill(star, with: .color(Design.Palette.ochre))
        context.stroke(star, with: .color(Design.Palette.ink), lineWidth: w * 0.009)
        var glow = context
        glow.translateBy(x: centre.x * 0.52, y: centre.y * 0.52)
        glow.scaleBy(x: 0.48, y: 0.48)
        glow.fill(star, with: .color(Design.Palette.surface))
        for point in [(0.22,0.23),(0.79,0.21),(0.17,0.48),(0.83,0.48)] {
            let dot = Path(ellipseIn: CGRect(x: w * point.0 - w * 0.017, y: h * point.1 - w * 0.017, width: w * 0.034, height: w * 0.034))
            context.fill(dot, with: .color(Design.Palette.surface))
            context.stroke(dot, with: .color(Design.Palette.ink), lineWidth: w * 0.006)
        }
    }
}

/// One 100 × 160 coordinate system keeps the same silhouettes at every card size.
private struct CardFaceDrawing {
    var context: GraphicsContext
    private let ink = Design.Palette.ink
    private let paper = Design.Palette.surface
    private let blue = Design.Palette.blue
    private let clay = Design.Palette.clay
    private let sage = Design.Palette.sage
    private let ochre = Design.Palette.ochre

    func draw(_ card: CardIdentity) {
        var cropped = context
        cropped.clip(to: Path(roundedRect: CGRect(x: 6, y: 6, width: 88, height: 148), cornerRadius: 7.5))
        let art = CardFaceDrawing(context: cropped)
        art.rectangle(6, 6, 88, 148, fill: blue.opacity(0.24), outlined: false)
        art.polygon([(6, 124), (40, 111), (72, 127), (94, 118), (94, 154), (6, 154)], fill: sage)
        art.polygon([(6, 145), (57, 132), (94, 144), (94, 154), (6, 154)], fill: clay)
        art.line([(6, 119), (94, 119)])
        if let suit = card.suit { art.minor(suit: suit.lowercased(), rank: card.rank) }
        else { art.major(rank: card.rank) }
    }

    private func paint(_ path: Path, fill: Color, outlined: Bool = true) {
        context.fill(path, with: .color(fill))
        if outlined { context.stroke(path, with: .color(ink), style: StrokeStyle(lineWidth: 1.15, lineJoin: .round)) }
    }

    private func line(_ points: [(Double, Double)], colour: Color? = nil, width: Double = 1.4) {
        var path = Path()
        path.addLines(points.map { CGPoint(x: $0.0, y: $0.1) })
        context.stroke(path, with: .color(colour ?? ink), style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
    }

    private func polygon(_ points: [(Double, Double)], fill: Color, outlined: Bool = true) {
        var path = Path()
        path.addLines(points.map { CGPoint(x: $0.0, y: $0.1) })
        path.closeSubpath()
        paint(path, fill: fill, outlined: outlined)
    }

    private func ellipse(_ x: Double, _ y: Double, _ w: Double, _ h: Double, fill: Color, outlined: Bool = true) {
        paint(Path(ellipseIn: CGRect(x: x, y: y, width: w, height: h)), fill: fill, outlined: outlined)
    }

    private func rectangle(_ x: Double, _ y: Double, _ w: Double, _ h: Double, fill: Color, outlined: Bool = true) {
        paint(Path(CGRect(x: x, y: y, width: w, height: h)), fill: fill, outlined: outlined)
    }

    private func star(_ x: Double, _ y: Double, radius: Double, fill: Color) {
        let points = (0..<10).map { index -> (Double, Double) in
            let angle = Double(index) * .pi / 5 - .pi / 2
            let r = index.isMultiple(of: 2) ? radius : radius * 0.43
            return (x + cos(angle) * r, y + sin(angle) * r)
        }
        polygon(points, fill: fill)
    }

    private func crescent(_ x: Double, _ y: Double, radius: Double) {
        var path = Path()
        path.move(to: CGPoint(x: x + radius * 0.45, y: y - radius))
        path.addCurve(to: CGPoint(x: x + radius * 0.45, y: y + radius),
                      control1: CGPoint(x: x - radius * 1.65, y: y - radius),
                      control2: CGPoint(x: x - radius * 1.65, y: y + radius))
        path.addCurve(to: CGPoint(x: x + radius * 0.45, y: y - radius),
                      control1: CGPoint(x: x - radius * 0.65, y: y + radius * 0.45),
                      control2: CGPoint(x: x - radius * 0.65, y: y - radius * 0.45))
        path.closeSubpath()
        paint(path, fill: ochre)
    }

    private func infinity(_ x: Double, _ y: Double) {
        var path = Path()
        path.move(to: CGPoint(x: x, y: y))
        path.addCurve(to: CGPoint(x: x, y: y), control1: CGPoint(x: x - 30, y: y - 25), control2: CGPoint(x: x - 30, y: y + 25))
        path.addCurve(to: CGPoint(x: x, y: y), control1: CGPoint(x: x + 30, y: y - 25), control2: CGPoint(x: x + 30, y: y + 25))
        context.stroke(path, with: .color(ink), style: StrokeStyle(lineWidth: 2, lineCap: .round))
    }

    private func crown(_ y: Double, royal: Bool = false) {
        let tips: [(Double, Double)] = royal
            ? [(26,0), (32,10), (38,-4), (44,8), (50,-10), (56,8), (62,-4), (68,10), (74,0), (69,24), (31,24)]
            : [(28,0), (40,10), (50,-8), (60,10), (72,0), (67,23), (33,23)]
        polygon(tips.map { ($0.0, $0.1 + y) }, fill: ochre)
        line([(34,y+17), (66,y+17)])
    }

    private func symbol(_ suit: String, x: Double, y: Double, scale: Double = 1) {
        var transformed = context
        transformed.translateBy(x: x, y: y)
        transformed.scaleBy(x: scale, y: scale)
        let art = CardFaceDrawing(context: transformed)
        switch suit {
        case "wands":
            art.polygon([(-2,-13),(2,-13),(2,14),(-2,14)], fill: clay)
            art.polygon([(2,-4),(10,-11),(10,-2),(2,3)], fill: sage)
            art.polygon([(-2,5),(-10,-2),(-10,6),(-2,10)], fill: sage)
        case "cups":
            var bowl = Path()
            bowl.move(to: CGPoint(x: -11, y: -11))
            bowl.addLine(to: CGPoint(x: 11, y: -11))
            bowl.addQuadCurve(to: CGPoint(x: 0, y: 4), control: CGPoint(x: 11, y: 4))
            bowl.addQuadCurve(to: CGPoint(x: -11, y: -11), control: CGPoint(x: -11, y: 4))
            art.paint(bowl, fill: blue)
            art.line([(0,4),(0,13)], width: 2)
            art.line([(-7,13),(7,13)], width: 2)
            art.line([(-8,-7),(8,-7)], colour: paper)
        case "swords":
            art.polygon([(0,-16),(5,-7),(3,6),(-3,6),(-5,-7)], fill: paper)
            art.line([(0,-10),(0,5)], colour: blue)
            art.line([(-9,7),(9,7)], width: 2.5)
            art.rectangle(-2, 8, 4, 8, fill: clay)
        case "pentacles":
            art.ellipse(-12, -12, 24, 24, fill: ochre)
            art.star(0, 0, radius: 9, fill: paper)
        default: break // Only canonical suit metadata reaches the full-deck catalogue.
        }
    }

    private func minor(suit: String, rank: Int) {
        if rank == 1 {
            ellipse(19, 32, 62, 68, fill: paper)
            symbol(suit, x: 50, y: 65, scale: 2.1)
        } else if (2...10).contains(rank) {
            let pairs = rank / 2
            // Five rows need room between the longest suit silhouettes (the sword's tip and hilt).
            let pipScale: Double = switch rank {
            case 10: 0.52
            case 8...9: 0.68
            default: 0.85
            }
            for row in 0..<pairs {
                let y = pairs == 1 ? 80.0 : 29 + Double(row) * 77 / Double(pairs - 1)
                for x in [29.0, 71.0] { symbol(suit, x: x, y: y, scale: pipScale) }
            }
            if !rank.isMultiple(of: 2) { symbol(suit, x: 50, y: rank == 3 ? 38 : 67, scale: 0.85) }
        } else {
            switch rank {
            case 11:
                polygon([(30,102),(24,59),(45,82)], fill: sage)
                line([(29,100),(27,69)])
                ellipse(43, 22, 14, 14, fill: ochre)
            case 12:
                line([(23,111),(74,23)], width: 3)
                polygon([(74,23),(45,24),(61,44)], fill: clay)
            case 13:
                ellipse(23, 59, 54, 53, fill: sage)
                crown(30)
            case 14:
                rectangle(23, 53, 54, 57, fill: clay)
                rectangle(30, 59, 40, 48, fill: paper)
                crown(27, royal: true)
            default: break
            }
            symbol(suit, x: 50, y: 82, scale: 1.55)
        }
    }

    private func major(rank: Int) {
        switch rank {
        case 0: // The Fool: a beginning at the edge.
            ellipse(58, 21, 23, 23, fill: ochre)
            polygon([(12,92),(61,92),(40,113),(12,118)], fill: clay)
            line([(35,86),(53,41)], width: 3)
            polygon([(47,47),(30,46),(29,60),(41,61)], fill: sage)
            line([(57,98),(70,103),(75,110)])
        case 1:
            infinity(50, 37)
            line([(42,106),(58,58)], width: 5)
            star(60, 52, radius: 11, fill: ochre)
            rectangle(22, 99, 56, 7, fill: clay)
        case 2:
            rectangle(19, 43, 15, 63, fill: blue)
            rectangle(66, 43, 15, 63, fill: paper)
            crescent(51, 52, radius: 22)
            line([(40,93),(60,93)], width: 3)
        case 3:
            crown(40)
            for x in [30.0,50,70] {
                line([(x,105),(x,79)])
                polygon([(x,90),(x-6,80),(x,74),(x+6,80)], fill: sage)
            }
        case 4:
            rectangle(25, 30, 50, 66, fill: clay)
            rectangle(35, 46, 30, 43, fill: paper)
            rectangle(18, 84, 64, 18, fill: ochre)
            line([(26,103),(26,112)], width: 4)
            line([(74,103),(74,112)], width: 4)
            polygon([(42,40),(50,27),(58,40)], fill: ochre)
        case 5:
            for (index,w) in [20.0,32,44].enumerated() { rectangle(50-w/2, 26+Double(index)*12, w, 7, fill: ochre) }
            for flip in [-1.0,1] {
                ellipse(50+flip*20-7, 69, 14, 14, fill: paper)
                line([(50+flip*20,83),(50-flip*18,107),(50-flip*22,100)], width: 3)
            }
        case 6:
            ellipse(20, 43, 23, 23, fill: ochre)
            ellipse(57, 43, 23, 23, fill: clay)
            polygon([(18,102),(31,68),(47,94),(53,94),(69,68),(82,102)], fill: sage)
            line([(31,39),(50,24),(69,39)])
            ellipse(45, 79, 10, 10, fill: paper)
        case 7:
            polygon([(17,40),(50,23),(83,40)], fill: blue)
            line([(23,40),(23,93),(77,93),(77,40)])
            rectangle(24, 66, 52, 31, fill: clay)
            ellipse(24, 93, 18, 18, fill: ochre)
            ellipse(58, 93, 18, 18, fill: ochre)
            star(50, 80, radius: 10, fill: paper)
        case 8:
            infinity(50, 30)
            ellipse(24, 52, 52, 52, fill: ochre)
            polygon([(30,67),(29,47),(44,56),(56,56),(71,47),(70,67),(64,92),(50,102),(36,92)], fill: clay)
            ellipse(37, 69, 4, 4, fill: paper)
            ellipse(59, 69, 4, 4, fill: paper)
            polygon([(45,82),(55,82),(50,89)], fill: paper)
        case 9:
            polygon([(14,113),(47,65),(79,113)], fill: blue)
            line([(66,38),(66,103)], width: 3)
            line([(43,37),(43,27),(58,27),(58,37)])
            rectangle(36, 37, 28, 36, fill: paper)
            star(50, 55, radius: 11, fill: ochre)
        case 10:
            ellipse(18, 34, 64, 64, fill: ochre)
            ellipse(26, 42, 48, 48, fill: paper)
            for index in 0..<8 {
                let angle = Double(index) * .pi / 4
                line([(50,66),(50+cos(angle)*29,66+sin(angle)*29)])
            }
            ellipse(44, 60, 12, 12, fill: clay)
        case 11:
            line([(50,30),(50,106)], width: 3)
            line([(22,53),(78,53)], width: 3)
            polygon([(50,23),(55,33),(50,40),(45,33)], fill: ochre)
            for x in [28.0,72] {
                line([(x,53),(x-12,81),(x+12,81),(x,53)])
                polygon([(x-14,82),(x+14,82),(x+7,93),(x-7,93)], fill: blue)
            }
        case 12:
            line([(24,30),(76,30)], width: 4)
            line([(50,30),(50,47),(33,65),(52,77),(62,59)], width: 3)
            polygon([(42,69),(58,69),(64,89),(36,89)], fill: clay)
            ellipse(40, 91, 20, 20, fill: ochre)
        case 13:
            crescent(51, 43, radius: 19)
            line([(32,105),(32,78),(40,71)], width: 3)
            line([(31,69),(27,64)], width: 2)
            line([(63,108),(63,90)], width: 2)
            polygon([(63,97),(47,85),(54,81),(63,87),(72,77),(79,84)], fill: sage)
        case 14:
            symbol("cups", x: 31, y: 43, scale: 1.3)
            symbol("cups", x: 69, y: 91, scale: 1.3)
            line([(37,58),(60,74)], colour: blue, width: 5)
            line([(46,55),(66,68)], colour: paper, width: 2)
            polygon([(24,109),(38,84),(48,109)], fill: sage)
        case 15:
            polygon([(28,60),(23,29),(43,49),(57,49),(77,29),(72,60),(65,79),(50,90),(35,79)], fill: clay)
            for x in [33.0,50,67] { ellipse(x-7, 94, 14, 18, fill: paper) }
            for x in [41.5,58.5] { line([(x-4,103),(x+4,103)]) }
            polygon([(43,67),(57,67),(50,76)], fill: ochre)
        case 16:
            polygon([(30,108),(35,56),(62,56),(70,108)], fill: clay)
            polygon([(33,45),(29,31),(43,36),(49,24),(55,38),(68,32),(63,47)], fill: ochre)
            polygon([(74,18),(49,62),(59,64),(42,97),(73,58),(62,55),(85,18)], fill: ochre)
            rectangle(41, 71, 8, 13, fill: paper)
        case 18:
            crescent(53, 44, radius: 23)
            rectangle(17, 74, 17, 32, fill: blue)
            rectangle(66, 74, 17, 32, fill: clay)
            ellipse(35, 100, 30, 11, fill: paper)
            line([(44,79),(56,85),(44,91)], colour: blue, width: 2)
        case 19:
            ellipse(28, 38, 44, 44, fill: ochre)
            for index in 0..<12 {
                let angle = Double(index) * .pi / 6
                line([(50+cos(angle)*27,60+sin(angle)*27),(50+cos(angle)*36,60+sin(angle)*36)])
            }
            line([(38,98),(50,105),(62,98)], colour: ochre, width: 4)
        case 20:
            polygon([(25,31),(51,48),(72,45),(58,67),(49,55),(21,43)], fill: ochre)
            line([(61,69),(67,79)])
            line([(74,61),(83,65)])
            for x in [28.0,50,72] {
                ellipse(x-6, 92, 12, 12, fill: paper)
                line([(x,108),(x,114)], width: 2)
            }
        case 21:
            ellipse(22, 24, 56, 84, fill: sage)
            ellipse(32, 34, 36, 64, fill: paper)
            polygon([(50,43),(61,66),(50,89),(39,66)], fill: clay)
            for (x,y) in [(18.0,28.0),(82,28),(18,105),(82,105)] { star(x,y,radius: 7,fill: ochre) }
        default: break // The Star uses its reference landscape in TarotCardView.
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
    var compact = false
    var showsDisc = true
    let choose: (Int) -> Void

    init(selected: Int?, phase: FanPhase = .fanned, order: [Int] = Array(1...5),
         compact: Bool = false, showsDisc: Bool = true, choose: @escaping (Int) -> Void) {
        self.selected = selected
        self.phase = phase
        self.order = order
        self.compact = compact
        self.showsDisc = showsDisc
        self.choose = choose
    }

    init(selected: Binding<Int?>, compact: Bool = false, showsDisc: Bool = true) {
        self.init(selected: selected.wrappedValue, compact: compact, showsDisc: showsDisc) {
            selected.wrappedValue = $0
        }
    }

    var body: some View {
        GeometryReader { geometry in
            let width = max(0, geometry.size.width)
            let cardWidth = min(compact ? 78 : 112, width * 0.33)
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
                                .frame(maxWidth: .infinity, minHeight: compact ? 160 : 240)
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
                if showsDisc {
                    Circle().fill(Design.Palette.disc)
                        .overlay { GroundGrain(night: true).clipShape(Circle()) }
                        .frame(width: width * 1.345, height: width * 1.345)
                }
            }
        }
        .frame(height: compact ? 160 : 360)
    }

    private func horizontalOffset(distance: CGFloat, width: CGFloat) -> CGFloat {
        switch phase {
        case .gathered: distance * width * 0.04
        case .washLeft: -distance * width * 0.12
        case .washRight: distance * width * 0.15
        case .fanned: distance * width * (compact ? 0.16 : 0.20)
        }
    }

    private func verticalOffset(distance: CGFloat, selected chosen: Bool) -> CGFloat {
        switch phase {
        case .gathered: abs(distance) * 4 + 20
        case .washLeft: distance * 12 + 20
        case .washRight: -distance * 12 + 20
        case .fanned: chosen ? -27 : abs(distance) * (compact ? 12 : 18) + (selected == nil && !compact ? 20 : 0)
        }
    }

    private func rotation(distance: CGFloat, selected chosen: Bool) -> Double {
        switch phase {
        case .gathered: Double(distance) * 3
        case .washLeft: Double(-distance) * 12
        case .washRight: Double(distance) * 12
        case .fanned: chosen ? 0 : Double(distance) * (compact ? 6 : 8)
        }
    }
}

struct AreaSelector: View {
    @Binding var selection: ReadingArea
    @Environment(\.dynamicTypeSize) private var textSize

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: textSize.isAccessibilitySize ? 22 : 1000)
        let layout = textSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: 4)) : AnyLayout(HStackLayout(spacing: 4))
        layout {
            ForEach(ReadingArea.allCases) { area in
                Button { selection = area } label: {
                    Text(area.label)
                        .typeRole(.label)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, minHeight: Design.Space.target)
                        .padding(.horizontal, 4)
                        .foregroundStyle(Design.Palette.ink)
                        .background(selection == area ? Design.Palette.surface : .clear, in: shape)
                        .contentShape(shape)
                }
                .buttonStyle(ActionPressStyle())
                .accessibilityIdentifier("area-\(area.rawValue)")
                .accessibilityAddTraits(selection == area ? .isSelected : [])
            }
        }
        .padding(4)
        .background(Design.Palette.controlTrack, in: shape)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Reading area")
    }
}

struct QuestionChip: View {
    let title: String
    var fillsWidth = false
    var selected = false
    let action: () -> Void
    @Environment(\.dynamicTypeSize) private var textSize

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: textSize.isAccessibilitySize ? 22 : 1000)
        Button(action: action) {
            Text(title).typeRole(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: fillsWidth ? .infinity : nil, alignment: .leading)
                .padding(.horizontal, Design.Space.group)
                .padding(.vertical, Design.Space.related)
                .frame(minHeight: Design.Space.target)
                .foregroundStyle(selected ? Design.Palette.surface : Design.Palette.ink)
                .background(selected ? Design.Palette.ink : Design.Palette.surface, in: shape)
                .overlay { shape.strokeBorder(Design.Palette.controlBorder, lineWidth: 1) }
                .contentShape(shape)
        }
        .buttonStyle(ActionPressStyle())
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

struct NoteField: View {
    @Binding var text: String
    @FocusState.Binding var focused: Bool
    var onFocus: () -> Void

    var body: some View {
        TextEditor(text: $text)
            .typeRole(.body)
            .foregroundStyle(Design.Palette.ink)
            .tint(Design.Palette.ink)
            .scrollContentBackground(.hidden)
            .focused($focused)
            .onChange(of: focused) { _, isFocused in
                if isFocused { onFocus() }
            }
            .overlay(alignment: .topLeading) {
                if text.isEmpty {
                    Text("Write a note").typeRole(.body)
                        .foregroundStyle(Design.Palette.placeholder)
                        .fixedSize(horizontal: false, vertical: true)
                        // Match the native text editor's text-container insets.
                        .padding(.horizontal, 5)
                        .padding(.vertical, Design.Space.small)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
            }
            .frame(minHeight: 220)
            .padding(Design.Space.related)
            .background(Design.Palette.surface, in: RoundedRectangle(cornerRadius: 20))
            .overlay { RoundedRectangle(cornerRadius: 20).strokeBorder(Design.Palette.ink, lineWidth: 1.5) }
            .accessibilityLabel("Your note")
            .accessibilityIdentifier("note-field")
    }
}

struct NoteKeyboardDismissal: View {
    let dismiss: () -> Void

    var body: some View {
        HStack {
            Spacer()
            Button(action: dismiss) {
                Text("Done").typeRole(.secondary)
                    .frame(minWidth: Design.Space.target, minHeight: Design.Space.target)
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.capsule)
            .tint(Design.Palette.ink)
            .accessibilityIdentifier("note-keyboard-done")
        }
        .padding(.horizontal, Design.Space.page)
        .padding(.vertical, Design.Space.small)
        .background { ScreenGround() }
    }
}

struct ReadingMoreMenu: View {
    let hasNote: Bool
    let editNote: () -> Void
    let delete: () -> Void

    var body: some View {
        Menu {
            Button(hasNote ? "Edit note" : "Add a note", systemImage: "square.and.pencil", action: editNote)
                .accessibilityIdentifier("reading-edit-note")
            Button("Delete", systemImage: "trash", role: .destructive, action: delete)
                .accessibilityIdentifier("reading-delete")
        } label: {
            Image(systemName: "ellipsis").typeRole(.section)
                .dynamicTypeSize(.large)
                .foregroundStyle(Design.Palette.ink)
                .frame(minWidth: Design.Space.target, minHeight: Design.Space.target)
                .contentShape(Rectangle())
        }
        .accessibilityLabel("More")
        .accessibilityIdentifier("reading-more")
    }
}

struct QuestionEntry: View {
    let title: String
    let action: () -> Void
    @Environment(\.dynamicTypeSize) private var textSize
    @ScaledMetric(relativeTo: .headline) private var iconSize = 20.0

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: textSize.isAccessibilitySize ? 22 : 1000)
        Button(action: action) {
            HStack(spacing: Design.Space.related) {
                Text(title).typeRole(.body).fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                Image(systemName: "arrow.right").typeRole(.button)
                    .frame(width: iconSize, height: iconSize)
                    .padding(Design.Space.related)
                    .foregroundStyle(Design.Palette.surface)
                    .background(Design.Palette.ink, in: Circle())
                    .accessibilityHidden(true)
            }
            .foregroundStyle(Design.Palette.placeholder)
            .multilineTextAlignment(.leading)
            .padding(.leading, Design.Space.page)
            .padding(.trailing, Design.Space.small)
            .padding(.vertical, Design.Space.small)
            .background(Design.Palette.surface, in: shape)
            .overlay { shape.strokeBorder(Design.Palette.ink, lineWidth: 1.5) }
            .contentShape(shape)
        }
        .buttonStyle(ActionPressStyle())
    }
}

struct QuestionField: View {
    @Binding var text: String
    var onFocus: () -> Void = {}
    @State private var editBuffer: String
    @FocusState private var focused: Bool

    init(text: Binding<String>, onFocus: @escaping () -> Void = {}) {
        _text = text
        _editBuffer = State(initialValue: text.wrappedValue)
        self.onFocus = onFocus
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: Design.Space.small) {
            TextField("Your question", text: $editBuffer,
                      prompt: Text("Type your question...").foregroundStyle(Design.Palette.placeholder), axis: .vertical)
                .onChange(of: editBuffer) { _, proposed in
                    let edit = QuestionEdit.applying(proposed, to: text)
                    // A changed native buffer makes SwiftUI visibly undo rejected input.
                    if editBuffer != edit.text { editBuffer = edit.text }
                    if text != edit.text { text = edit.text }
                    if edit.dismissKeyboard { focused = false }
                }
                .onChange(of: text) { _, updated in
                    if editBuffer != updated { editBuffer = updated }
                }
                .typeRole(.body)
                .foregroundStyle(Design.Palette.ink)
                .tint(Design.Palette.ink)
                .lineLimit(4...6)
                .focused($focused)
                .onChange(of: focused) { _, isFocused in
                    if isFocused { onFocus() }
                }
                .submitLabel(.done)
                .padding(Design.Space.group)
                .frame(minHeight: 132, alignment: .topLeading)
                .background(Design.Palette.surface, in: RoundedRectangle(cornerRadius: 20))
                .overlay { RoundedRectangle(cornerRadius: 20).strokeBorder(Design.Palette.ink, lineWidth: 1.5) }
                .accessibilityLabel("Your question")
                .accessibilityIdentifier("question-field")
            Text(text.count == QuestionEdit.limit ? "Limit reached · \(text.count) / \(QuestionEdit.limit)" : "\(text.count) / \(QuestionEdit.limit)")
                .typeRole(.caption)
                .foregroundStyle(text.count == QuestionEdit.limit ? Design.Palette.error : Design.Palette.secondary)
                .accessibilityLabel("\(text.count) of \(QuestionEdit.limit) characters\(text.count == QuestionEdit.limit ? ", limit reached" : "")")
                .accessibilityIdentifier("question-count")
        }
    }
}

struct AskContextPanel: View {
    let area: ReadingArea
    let cardName: String
    let reading: AreaReading

    var body: some View {
        VStack(alignment: .leading, spacing: Design.Space.related) {
            Text(cardName).typeRole(.section).foregroundStyle(Design.Palette.ink)
            Text(reading.line).typeRole(.body).foregroundStyle(Design.Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("ask-area-line")
            Text("\(area.label) today: \(reading.score) of 100")
                .typeRole(.label).foregroundStyle(Design.Palette.label(for: area))
                .accessibilityLabel("\(area.label), \(reading.score) out of 100")
                .accessibilityIdentifier("ask-area-score")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Design.Space.page)
        .background(Design.Palette.areaTint(area), in: RoundedRectangle(cornerRadius: 22))
    }
}

struct ComposerPreview: View {
    @Environment(\.dynamicTypeSize) private var textSize

    var body: some View {
        let layout = textSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Design.Space.group))
            : AnyLayout(HStackLayout(alignment: .center, spacing: Design.Space.group))
        layout {
            HStack(spacing: Design.Space.small) {
                ForEach(QuestionPosition.allCases) { position in
                    RoundedRectangle(cornerRadius: 3.4)
                        .strokeBorder(Design.Palette.secondary, style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                        .frame(width: 34, height: 54.4)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("\(position.label), empty")
                        .accessibilityIdentifier("composer-preview-\(position.rawValue)")
                }
            }
            Text("Next you'll draw three cards: one for the situation, one for an action, one for the outcome.")
                .typeRole(.secondary).foregroundStyle(Design.Palette.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("composer-preview-helper")
        }
    }
}

struct NavigationAction: View {
    var close = false
    var night = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: close ? "xmark" : "chevron.left")
                .typeRole(.section)
                .dynamicTypeSize(.large) // Keep the glyph's designed size; its target remains at least 44 points.
                .foregroundStyle(night ? Design.Palette.cream : Design.Palette.ink)
                .frame(minWidth: Design.Space.target, minHeight: Design.Space.target)
                .contentShape(Rectangle())
        }
        .buttonStyle(ActionPressStyle())
        .accessibilityLabel(close ? "Close reading" : "Back")
        .accessibilityIdentifier(close ? "close-reading" : "go-back")
    }
}

struct RestingTabBar: View {
    let askSelected: Bool
    let today: () -> Void
    let ask: () -> Void

    var body: some View {
        HStack {
            tab("Today", symbol: "rectangle.portrait", selected: !askSelected, action: today)
            tab("Ask", symbol: "bubble.left", selected: askSelected, action: ask)
        }
        .padding(.top, Design.Space.small)
        .padding(.bottom, Design.Space.small)
        .background(Design.Palette.surface)
        .overlay(alignment: .top) { Rectangle().fill(Design.Palette.hairline).frame(height: 1) }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("resting-tabs")
    }

    private func tab(_ title: String, symbol: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: symbol).typeRole(.section)
                    .foregroundStyle(selected ? Design.Palette.surface : Design.Palette.ink)
                    .padding(.horizontal, Design.Space.page)
                    .padding(.vertical, 4)
                    .background(selected ? Design.Palette.ink : .clear, in: Capsule())
                    .accessibilityHidden(true)
                Text(title).typeRole(.tab)
            }
            .foregroundStyle(Design.Palette.ink)
            .frame(maxWidth: .infinity, minHeight: Design.Space.target)
            .contentShape(Rectangle())
        }
        .buttonStyle(ActionPressStyle())
        .tint(Design.Palette.ink)
        .accessibilityIdentifier("tab-\(title.lowercased())")
        .accessibilityLabel(title)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

struct EmptySpreadSlot: View {
    let number: Int
    let active: Bool
    let width: CGFloat
    var animationsEnabled = false
    @State private var pulsing = false

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: width / 10)
        shape.fill(Design.Palette.night)
            .overlay {
                shape.strokeBorder(active ? Design.Palette.gold : Design.Palette.nightSecondary.opacity(0.4),
                                   style: StrokeStyle(lineWidth: 1.5, dash: [3, 3]))
                    .opacity(active && animationsEnabled && pulsing ? 0.55 : 1)
            }
            .overlay {
                Text(String(number)).typeRole(.section).foregroundStyle(Design.Palette.gold)
            }
            .frame(width: width, height: width * 1.6)
            .accessibilityHidden(true)
            .task(id: active && animationsEnabled) {
                pulsing = false
                if active && animationsEnabled {
                    withAnimation(Design.Motion.activeSlotPulse) { pulsing = true }
                }
            }
    }
}

struct ReflectionPanel: View {
    let question: String

    var body: some View {
        VStack(alignment: .leading, spacing: Design.Space.related) {
            Text(question).typeRole(.section).fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("reflection-question")
            Text("Something to sit with").typeRole(.caption)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Design.Space.page)
        .foregroundStyle(Design.Palette.surface)
        .background(Design.Palette.ink, in: RoundedRectangle(cornerRadius: 22))
    }
}
