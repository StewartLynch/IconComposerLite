import SwiftUI
import IconRendering

// MARK: - Enums

enum BackgroundType: String, CaseIterable {
    case solid = "Solid Color"
    case automaticGradient = "Automatic Gradient"
    case linearGradient = "Linear Gradient"
}

enum CenterContentKind: String, CaseIterable {
    case none = "None"
    case text = "Text"
    case sfSymbol = "SF Symbol"
    case emoji = "Emoji"
    case image = "Image"
}

// MARK: - Label Config

@Observable
class LabelConfig: Identifiable {
    let id = UUID()
    var position: LabelPosition = .topRight
    var contentText: String = "BETA"
    var backgroundColor: Color = .red
    var foregroundColor: Color = .white

    func toIconLabel() -> IconLabel {
        IconLabel(
            content: .text(contentText),
            position: position,
            backgroundColor: .solid(CSSColor(backgroundColor.cssString)),
            foregroundColor: CSSColor(foregroundColor.cssString)
        )
    }
}

// MARK: - Icon Config

@Observable
class IconConfig {
    // Background
    var backgroundType: BackgroundType = .solid
    var backgroundColor: Color = .blue
    var gradientTopColor: Color = .blue
    var gradientBottomColor: Color = .purple

    // Center Content
    var centerContentKind: CenterContentKind = .sfSymbol
    var centerText: String = "swift"
    var emojiText: String = ""
    var centerImageURL: URL?
    var centerColor: Color = .white
    var centerSizeRatio: Double = 0.6
    var centerOffsetX: Double = 0  // -1.0 to 1.0, normalized to icon size
    var centerOffsetY: Double = 0  // -1.0 to 1.0, normalized to icon size

    // Label
    var labelEnabled: Bool = false
    var label: LabelConfig = LabelConfig()

    // MARK: - Computed Properties

    var background: Background {
        switch backgroundType {
        case .solid:
            return .solid(CSSColor(backgroundColor.cssString))
        case .automaticGradient:
            let lighterColor = backgroundColor.lightenedForGradient
            return .linearGradient(
                colors: [CSSColor(lighterColor.cssString), CSSColor(backgroundColor.cssString)],
                startPoint: .top,
                endPoint: .bottom
            )
        case .linearGradient:
            return .linearGradient(
                colors: [CSSColor(gradientTopColor.cssString), CSSColor(gradientBottomColor.cssString)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    var centerContent: CenterContent? {
        switch centerContentKind {
        case .none:
            return nil
        case .text:
            guard !centerText.isEmpty else { return nil }
            return CenterContent(
                content: .text(centerText),
                color: CSSColor(centerColor.cssString),
                sizeRatio: centerSizeRatio
            )
        case .sfSymbol:
            guard !centerText.isEmpty else { return nil }
            return CenterContent(
                content: .sfSymbol(centerText),
                color: CSSColor(centerColor.cssString),
                sizeRatio: centerSizeRatio
            )
        case .emoji:
            guard !emojiText.isEmpty else { return nil }
            return CenterContent(
                content: .text(emojiText),
                color: CSSColor(centerColor.cssString),
                sizeRatio: centerSizeRatio
            )
        case .image:
            guard let url = centerImageURL else { return nil }
            return CenterContent(
                content: .image(url),
                color: CSSColor(centerColor.cssString),
                sizeRatio: centerSizeRatio
            )
        }
    }

    var iconLabels: [IconLabel] {
        guard labelEnabled else { return [] }
        return [label.toIconLabel()]
    }
}

// MARK: - Color Extension

extension Color {
    /// Convert SwiftUI Color to a CSS hex string
    var cssString: String {
        guard let nsColor = NSColor(self).usingColorSpace(.deviceRGB) else {
            return "#000000"
        }
        let r = Int(max(0, min(1, nsColor.redComponent)) * 255)
        let g = Int(max(0, min(1, nsColor.greenComponent)) * 255)
        let b = Int(max(0, min(1, nsColor.blueComponent)) * 255)
        return String(format: "#%02X%02X%02X", r, g, b)
    }

    /// Create a lighter tint for the top of an automatic gradient,
    /// mimicking Icon Composer's automatic gradient behavior.
    var lightenedForGradient: Color {
        guard let nsColor = NSColor(self).usingColorSpace(.deviceRGB) else {
            return self
        }
        let mixAmount: CGFloat = 0.45
        let r = nsColor.redComponent + (1.0 - nsColor.redComponent) * mixAmount
        let g = nsColor.greenComponent + (1.0 - nsColor.greenComponent) * mixAmount
        let b = nsColor.blueComponent + (1.0 - nsColor.blueComponent) * mixAmount
        return Color(red: min(r, 1.0), green: min(g, 1.0), blue: min(b, 1.0))
    }
}
