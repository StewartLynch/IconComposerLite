import SwiftUI
import IconRendering

struct IconPreviewView: View {
    @Bindable var config: IconConfig
    @State private var isDropTargeted = false
    @State private var dragOffset: CGSize = .zero

    private let iconSize: CGFloat = 256

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                // Background only (no labels, no center content)
                SquircleView(
                    background: config.background,
                    size: iconSize,
                    cornerStyle: .squircle,
                    cornerRadiusRatio: 0.22,
                    labels: [],
                    centerContent: nil
                )

                // Draggable center content overlay
                if config.centerContentKind != .none {
                    DraggableCenterContent(config: config, iconSize: iconSize)
                }

                // Label overlay rendered natively for precise positioning
                if config.labelEnabled {
                    LabelOverlay(label: config.label, iconSize: iconSize)
                }
            }
            .frame(width: iconSize, height: iconSize)
            .clipShape(RoundedRectangle(cornerRadius: iconSize * 0.22, style: .continuous))
            .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
            .overlay {
                if isDropTargeted {
                    RoundedRectangle(cornerRadius: iconSize * 0.22, style: .continuous)
                        .strokeBorder(Color.accentColor, lineWidth: 3)
                }
            }

            Text("Icon Preview")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background.secondary)
        .dropDestination(for: URL.self) { urls, _ in
            guard let url = urls.first, isImageFile(url) else { return false }
            config.centerContentKind = .image
            config.centerImageURL = url
            return true
        } isTargeted: { targeted in
            isDropTargeted = targeted
        }
    }

    private func isImageFile(_ url: URL) -> Bool {
        let imageExtensions: Set<String> = ["png", "jpg", "jpeg", "tiff", "gif", "bmp", "heic", "webp", "svg"]
        return imageExtensions.contains(url.pathExtension.lowercased())
    }
}

// MARK: - Label Overlay

/// Renders label ribbons as native SwiftUI overlays for precise positioning
/// that matches Icon Composer's rendering.
private struct LabelOverlay: View {
    let label: LabelConfig
    let iconSize: CGFloat

    private let diagonalWidthRatio: CGFloat = 0.35
    private let ribbonThicknessRatio: CGFloat = 0.15
    private let pillHeightRatio: CGFloat = 0.12
    private let pillPaddingRatio: CGFloat = 0.05
    private let labelFontSizeRatio: CGFloat = 0.08
    private let cornerRadiusRatio: CGFloat = 0.22

    var body: some View {
        Canvas { context, size in
            let fontSize = size.width * labelFontSizeRatio

            let resolved = context.resolve(
                Text(label.contentText)
                    .font(.system(size: fontSize, weight: .bold))
                    .foregroundStyle(label.foregroundColor)
            )

            switch label.position {
            case .topLeft, .topRight, .bottomLeft, .bottomRight:
                drawCornerRibbon(context: context, size: size, resolved: resolved)
            case .top, .bottom, .left, .right:
                drawEdgeRibbon(context: context, size: size, resolved: resolved)
            case .pillLeft, .pillCenter, .pillRight:
                drawPill(context: context, size: size, resolved: resolved, fontSize: fontSize)
            }
        }
        .frame(width: iconSize, height: iconSize)
        .allowsHitTesting(false)
    }

    // MARK: - Corner Ribbons

    private func drawCornerRibbon(context: GraphicsContext, size: CGSize, resolved: GraphicsContext.ResolvedText) {
        let width = size.width * diagonalWidthRatio

        // Draw triangle background
        let path = cornerRibbonPath(size: size, width: width)
        context.fill(path, with: .color(label.backgroundColor))

        // Draw text at adjusted centroid
        let offset = width / 3.3
        let centroid: CGPoint
        let rotation: Double
        switch label.position {
        case .topRight:
            centroid = CGPoint(x: size.width - offset, y: offset)
            rotation = 45
        case .topLeft:
            centroid = CGPoint(x: offset, y: offset)
            rotation = -45
        case .bottomRight:
            centroid = CGPoint(x: size.width - offset, y: size.height - offset)
            rotation = -45
        case .bottomLeft:
            centroid = CGPoint(x: offset, y: size.height - offset)
            rotation = 45
        default: return
        }

        var drawContext = context
        drawContext.translateBy(x: centroid.x, y: centroid.y)
        drawContext.rotate(by: .degrees(rotation))
        drawContext.draw(resolved, at: .zero)
    }

    private func cornerRibbonPath(size: CGSize, width: CGFloat) -> Path {
        var path = Path()
        switch label.position {
        case .topRight:
            path.move(to: CGPoint(x: size.width, y: 0))
            path.addLine(to: CGPoint(x: size.width - width, y: 0))
            path.addLine(to: CGPoint(x: size.width, y: width))
            path.closeSubpath()
        case .topLeft:
            path.move(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: width, y: 0))
            path.addLine(to: CGPoint(x: 0, y: width))
            path.closeSubpath()
        case .bottomRight:
            path.move(to: CGPoint(x: size.width, y: size.height))
            path.addLine(to: CGPoint(x: size.width - width, y: size.height))
            path.addLine(to: CGPoint(x: size.width, y: size.height - width))
            path.closeSubpath()
        case .bottomLeft:
            path.move(to: CGPoint(x: 0, y: size.height))
            path.addLine(to: CGPoint(x: width, y: size.height))
            path.addLine(to: CGPoint(x: 0, y: size.height - width))
            path.closeSubpath()
        default: break
        }
        return path
    }

    // MARK: - Edge Ribbons

    private func drawEdgeRibbon(context: GraphicsContext, size: CGSize, resolved: GraphicsContext.ResolvedText) {
        let thickness = size.height * ribbonThicknessRatio
        let rect: CGRect
        let rotation: Double

        switch label.position {
        case .top:
            rect = CGRect(x: 0, y: 0, width: size.width, height: thickness)
            rotation = 0
        case .bottom:
            rect = CGRect(x: 0, y: size.height - thickness, width: size.width, height: thickness)
            rotation = 0
        case .left:
            rect = CGRect(x: 0, y: 0, width: thickness, height: size.height)
            rotation = -90
        case .right:
            rect = CGRect(x: size.width - thickness, y: 0, width: thickness, height: size.height)
            rotation = 90
        default: return
        }

        context.fill(Path(rect), with: .color(label.backgroundColor))

        let center = CGPoint(x: rect.midX, y: rect.midY)
        var drawContext = context
        drawContext.translateBy(x: center.x, y: center.y)
        if rotation != 0 {
            drawContext.rotate(by: .degrees(rotation))
        }
        drawContext.draw(resolved, at: .zero)
    }

    // MARK: - Pills

    private func drawPill(context: GraphicsContext, size: CGSize, resolved: GraphicsContext.ResolvedText, fontSize: CGFloat) {
        let pillHeight = size.height * pillHeightRatio
        let pillPadding = size.width * pillPaddingRatio
        let cornerSafePadding = size.width * (cornerRadiusRatio * 0.6 + 0.02)

        // Measure text to determine pill width
        let textSize = resolved.measure(in: CGSize(width: CGFloat.infinity, height: CGFloat.infinity))
        let pillWidth = textSize.width + pillPadding * 2
        let y = size.height - pillHeight - pillPadding

        let pillX: CGFloat
        switch label.position {
        case .pillLeft:
            pillX = cornerSafePadding
        case .pillCenter:
            pillX = (size.width - pillWidth) / 2
        case .pillRight:
            pillX = size.width - pillWidth - cornerSafePadding
        default: return
        }

        let pillRect = CGRect(x: pillX, y: y, width: pillWidth, height: pillHeight)
        let pillPath = Path(roundedRect: pillRect, cornerRadius: pillHeight / 2)
        context.fill(pillPath, with: .color(label.backgroundColor))

        let center = CGPoint(x: pillRect.midX, y: pillRect.midY)
        context.draw(resolved, at: center)
    }
}

// MARK: - Draggable Center Content

private struct DraggableCenterContent: View {
    @Bindable var config: IconConfig
    let iconSize: CGFloat
    @State private var dragOffset: CGSize = .zero

    private var contentSize: CGFloat {
        iconSize * config.centerSizeRatio
    }

    private var currentOffset: CGSize {
        CGSize(
            width: config.centerOffsetX * iconSize + dragOffset.width,
            height: config.centerOffsetY * iconSize + dragOffset.height
        )
    }

    var body: some View {
        centerContentView
            .offset(currentOffset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        dragOffset = value.translation
                    }
                    .onEnded { value in
                        config.centerOffsetX += value.translation.width / iconSize
                        config.centerOffsetY += value.translation.height / iconSize
                        dragOffset = .zero
                    }
            )
    }

    @ViewBuilder
    private var centerContentView: some View {
        switch config.centerContentKind {
        case .none:
            EmptyView()

        case .sfSymbol:
            if !config.centerText.isEmpty {
                Image(systemName: config.centerText)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundStyle(config.centerColor)
                    .frame(width: contentSize, height: contentSize)
            }

        case .text:
            if !config.centerText.isEmpty {
                Text(config.centerText)
                    .font(.system(size: contentSize * 0.4, weight: .bold))
                    .foregroundStyle(config.centerColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.3)
            }

        case .emoji:
            if !config.emojiText.isEmpty {
                Text(config.emojiText)
                    .font(.system(size: contentSize * 0.8))
                    .lineLimit(1)
            }

        case .image:
            if let url = config.centerImageURL, let nsImage = NSImage(contentsOf: url) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: contentSize, height: contentSize)
            }
        }
    }
}
