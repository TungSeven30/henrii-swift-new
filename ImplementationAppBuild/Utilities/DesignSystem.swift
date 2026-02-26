import SwiftUI

struct ReduceMotionModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .environment(\.henriiReduceMotion, reduceMotion)
    }
}

private struct HenriiReduceMotionKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

extension EnvironmentValues {
    var henriiReduceMotion: Bool {
        get { self[HenriiReduceMotionKey.self] }
        set { self[HenriiReduceMotionKey.self] = newValue }
    }
}

extension View {
    func henriiAnimation<V: Equatable>(_ value: V) -> some View {
        modifier(HenriiAnimationModifier(value: value))
    }
}

struct HenriiAnimationModifier<V: Equatable>: ViewModifier {
    @Environment(\.henriiReduceMotion) private var reduceMotion
    let value: V

    func body(content: Content) -> some View {
        if reduceMotion {
            content.animation(.easeInOut(duration: 0.15), value: value)
        } else {
            content.animation(.spring(duration: 0.35, bounce: 0.2), value: value)
        }
    }
}

enum HenriiColors {
    static let canvasPrimary = Color("CanvasPrimary")
    static let canvasElevated = Color("CanvasElevated")
    static let accentPrimary = Color("AccentPrimary")
    static let accentSecondary = Color("AccentSecondary")
    static let dataFeeding = Color("DataFeeding")
    static let dataSleep = Color("DataSleep")
    static let dataDiaper = Color("DataDiaper")
    static let dataGrowth = Color("DataGrowth")
    static let semanticAlert = Color("SemanticAlert")
    static let semanticCelebration = Color("SemanticCelebration")
    static let textPrimary = Color("TextPrimary")
    static let textSecondary = Color("TextSecondary")
    static let textTertiary = Color("TextTertiary")
}

enum HenriiSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
    static let margin: CGFloat = 20
    static let marginTablet: CGFloat = 32

    static func horizontalMargin(for sizeClass: UserInterfaceSizeClass?) -> CGFloat {
        sizeClass == .regular ? marginTablet : margin
    }
}

enum HenriiRadius {
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let large: CGFloat = 16
}

enum HenriiMotion {
    static let cardAppear: Animation = .spring(duration: 0.35, bounce: 0.2)
    static let cardMorph: Animation = .spring(duration: 0.25, bounce: 0.1)
    static let chipAppear: Animation = .spring(duration: 0.2, bounce: 0.15)
    static let screenTransition: Animation = .easeInOut(duration: 0.3)
    static let timerPulse: Animation = .easeInOut(duration: 2.0).repeatForever(autoreverses: true)
    static let reducedMotion: Animation = .easeInOut(duration: 0.15)

    static func preferred(reduceMotion: Bool) -> Animation {
        reduceMotion ? .easeInOut(duration: 0.15) : cardAppear
    }
}

enum HenriiHaptics {
    static let logConfirm: SensoryFeedback = .success
    static let timerStart: SensoryFeedback = .impact(weight: .medium)
    static let timerStop: SensoryFeedback = .impact(weight: .heavy)
    static let timerPause: SensoryFeedback = .impact(weight: .medium)
    static let chipSelect: SensoryFeedback = .selection
    static let destructive: SensoryFeedback = .warning
    static let undo: SensoryFeedback = .success
}

extension Font {
    static let henriiLargeTitle: Font = .system(.largeTitle, design: .rounded, weight: .bold)
    static let henriiTitle2: Font = .system(.title2, design: .rounded, weight: .bold)
    static let henriiHeadline: Font = .system(.headline, design: .rounded, weight: .semibold)
    static let henriiBody: Font = .system(.body, design: .rounded)
    static let henriiCallout: Font = .system(.callout, design: .rounded)
    static let henriiSubheadline: Font = .system(.subheadline)
    static let henriiFootnote: Font = .system(.footnote)
    static let henriiCaption: Font = .system(.caption)
    static func henriiData(size: CGFloat = 17) -> Font {
        .system(size: size, weight: .medium, design: .monospaced)
    }
}
