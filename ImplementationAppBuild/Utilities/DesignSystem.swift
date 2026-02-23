import SwiftUI

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
}

enum HenriiRadius {
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let large: CGFloat = 16
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
