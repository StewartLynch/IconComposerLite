import AppKit
import CoreText
import Foundation
import IconComposerFormat
import IconRendering
import SwiftUI
import SVGXML
import UniformTypeIdentifiers

enum IconExporter {

    /// Present a save panel and export the icon as a .icon bundle.
    @MainActor
    static func export(config: IconConfig) {
        let panel = NSSavePanel()
        panel.title = "Export Icon Bundle"
        panel.allowedContentTypes = [.folder]
        panel.nameFieldStringValue = "AppIcon.icon"
        panel.canCreateDirectories = true

        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            try generateIconBundle(config: config, at: url)
        } catch {
            let alert = NSAlert(error: error)
            alert.runModal()
        }
    }

    /// Generate a .icon bundle at the given URL from the config.
    @MainActor
    static func generateIconBundle(config: IconConfig, at url: URL) throws {
        var document = IconDocument()
        var bundle = IconBundle(document: document)
        let size = 1024

        // Set the document fill.
        // For linear-gradient we use a placeholder here and patch icon.json after writing,
        // since the IconFill type doesn't support the linear-gradient format.
        switch config.backgroundType {
        case .solid:
            let bgColor = parseToIconColor(CSSColor(config.backgroundColor.cssString))
            document.fill = .solid(bgColor)
        case .automaticGradient:
            let bgColor = parseToIconColor(CSSColor(config.backgroundColor.cssString))
            document.fill = .automaticGradient(bgColor)
        case .linearGradient:
            // Placeholder — will be patched after write
            document.fill = .automatic
        }

        // Create layers
        var layers: [IconLayer] = []

        // Render center content as SVG asset
        if let center = config.centerContent {
            let svgContent = renderCenterContentSVG(
                center: center,
                size: size,
                offsetX: config.centerOffsetX,
                offsetY: config.centerOffsetY
            )
            let assetName = "center.svg"
            bundle.setAsset(name: assetName, data: Data(svgContent.utf8))

            var layer = IconLayer(name: "center", imageName: assetName)
            layer.glass = true
            layers.append(layer)
        }

        // Render labels as SVG assets
        for (index, label) in config.iconLabels.enumerated() {
            let svgContent = renderLabelSVG(label: label, size: size)
            let assetName = "label-\(index)-\(label.position.rawValue).svg"
            bundle.setAsset(name: assetName, data: Data(svgContent.utf8))

            let layer = IconLayer(name: label.position.rawValue, imageName: assetName)
            layers.append(layer)
        }

        // Configure the group
        var group = IconGroup(layers: layers)

        group.shadow = IconShadow(kind: .layerColor, opacity: 0.5)
        group.translucency = IconTranslucency(enabled: true, value: 0.15)

        group.specular = true

        document.groups = [group]
        document.supportedPlatforms = SupportedPlatforms(
            circles: ["watchOS"],
            squares: .shared
        )

        bundle.document = document

        // Remove existing bundle if present
        let fm = FileManager.default
        if fm.fileExists(atPath: url.path) {
            try fm.removeItem(at: url)
        }

        try bundle.write(to: url)

        // Patch icon.json for linear-gradient fill, which IconFill doesn't support natively
        if config.backgroundType == .linearGradient {
            try patchLinearGradientFill(
                at: url,
                topColor: CSSColor(config.gradientTopColor.cssString),
                bottomColor: CSSColor(config.gradientBottomColor.cssString)
            )
        }
    }

    /// Replace the fill in icon.json with a linear-gradient array.
    /// Icon Composer format: `{ "linear-gradient": ["colorspace:top", "colorspace:bottom"] }`
    private static func patchLinearGradientFill(
        at bundleURL: URL,
        topColor: CSSColor,
        bottomColor: CSSColor
    ) throws {
        let iconJSONURL = bundleURL.appendingPathComponent("icon.json")
        let data = try Data(contentsOf: iconJSONURL)
        guard var json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }

        let top = parseToIconColor(topColor)
        let bottom = parseToIconColor(bottomColor)
        json["fill"] = ["linear-gradient": [top.stringValue, bottom.stringValue]]

        let patched = try JSONSerialization.data(
            withJSONObject: json,
            options: [.prettyPrinted, .sortedKeys]
        )
        try patched.write(to: iconJSONURL)
    }

    // MARK: - Color Conversion

    private static func parseToIconColor(_ cssColor: CSSColor) -> IconColor {
        guard let components = cssColor.parse() else {
            return IconColor(colorSpace: .srgb, components: [1.0, 1.0, 1.0, 1.0])
        }
        return IconColor(
            colorSpace: .srgb,
            components: [components.red, components.green, components.blue, components.alpha]
        )
    }

    // MARK: - SVG Rendering

    @MainActor
    private static func renderCenterContentSVG(
        center: CenterContent,
        size: Int,
        offsetX: Double = 0,
        offsetY: Double = 0
    ) -> String {
        let iconSize = CGSize(width: size, height: size)
        let doc = SVGDocument(width: iconSize.width, height: iconSize.height)

        let contentSize = iconSize.width * center.sizeRatio
        let centerPoint = CGPoint(
            x: iconSize.width / 2 + offsetX * iconSize.width,
            y: iconSize.height / 2 + offsetY * iconSize.height
        )
        let foreground = center.resolvedColor.svgString()

        switch center.content {
        case .text(let text):
            if text.unicodeScalars.contains(where: { $0.properties.isEmoji && $0.value > 0x238C }) {
                addEmojiElement(to: doc, emoji: text, at: centerPoint, size: contentSize)
            } else {
                addTextElement(to: doc, text: text, at: centerPoint, fontSize: contentSize, foreground: foreground)
            }

        case .sfSymbol(let name):
            addSFSymbolElement(to: doc, name: name, at: centerPoint, fontSize: contentSize, foreground: foreground)

        case .image(let url):
            addImageElement(to: doc, url: url, at: centerPoint, size: contentSize)
        }

        return doc.render()
    }

    @MainActor
    private static func renderLabelSVG(label: IconLabel, size: Int) -> String {
        let iconSize = CGSize(width: size, height: size)
        let doc = SVGDocument(width: iconSize.width, height: iconSize.height)

        switch label.position {
        case .topLeft, .topRight, .bottomLeft, .bottomRight:
            renderCornerRibbon(label: label, size: iconSize, to: doc)
        case .top, .bottom, .left, .right:
            renderEdgeRibbon(label: label, size: iconSize, to: doc)
        case .pillLeft, .pillCenter, .pillRight:
            renderPill(label: label, size: iconSize, to: doc)
        }

        return doc.render()
    }

    // MARK: - Text/Symbol Element Helpers

    @MainActor
    private static func addTextElement(
        to doc: SVGDocument,
        text: String,
        at point: CGPoint,
        fontSize: CGFloat,
        foreground: String,
        rotation: Double = 0
    ) {
        let font = CTFontCreateWithName("SF Pro Bold" as CFString, fontSize, nil)

        let characters = Array(text.utf16)
        var glyphs = [CGGlyph](repeating: 0, count: characters.count)
        CTFontGetGlyphsForCharacters(font, characters, &glyphs, characters.count)

        var advances = [CGSize](repeating: .zero, count: glyphs.count)
        let totalWidth = CTFontGetAdvancesForGlyphs(font, .default, glyphs, &advances, glyphs.count)

        let capHeight = CTFontGetCapHeight(font)

        let startX = point.x - totalWidth / 2
        let startY = point.y + capHeight / 2

        let path = CGMutablePath()
        var currentX = startX

        for (index, glyph) in glyphs.enumerated() {
            if let glyphPath = CTFontCreatePathForGlyph(font, glyph, nil) {
                let transform = CGAffineTransform(translationX: currentX, y: startY)
                    .scaledBy(x: 1, y: -1)
                path.addPath(glyphPath, transform: transform)
            }
            currentX += advances[index].width
        }

        let svgPathData = cgPathToSVGPath(path)
        var pathElement = XMLElement.path(d: svgPathData, fill: foreground)
        if rotation != 0 {
            pathElement.attributes["transform"] = SVGTransform.rotate(rotation, around: point)
        }
        doc.addElement(pathElement)
    }

    @MainActor
    private static func addSFSymbolElement(
        to doc: SVGDocument,
        name: String,
        at point: CGPoint,
        fontSize: CGFloat,
        foreground: String
    ) {
        let config = NSImage.SymbolConfiguration(pointSize: fontSize, weight: .regular)
        guard let baseImage = NSImage(systemSymbolName: name, accessibilityDescription: nil) else {
            // Fallback to text
            addTextElement(to: doc, text: "[\(name)]", at: point, fontSize: fontSize * 0.3, foreground: foreground)
            return
        }

        let configuredImage = baseImage.withSymbolConfiguration(config)

        // Tint the image
        let cssColor = CSSColor(foreground)
        let nsColor = cssColor.color().map({ NSColor($0) }) ?? .white

        let symbolSize = configuredImage?.size ?? baseImage.size
        let finalImage = NSImage(size: symbolSize, flipped: false) { rect in
            configuredImage?.draw(in: rect)
            nsColor.set()
            rect.fill(using: .sourceIn)
            return true
        }

        guard let tiffData = finalImage.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else { return }

        let base64 = pngData.base64EncodedString()
        let dataURL = "data:image/png;base64,\(base64)"

        // Scale the image to fit within the desired content size
        let scale = min(fontSize / symbolSize.width, fontSize / symbolSize.height)
        let displayWidth = symbolSize.width * scale
        let displayHeight = symbolSize.height * scale
        let x = point.x - displayWidth / 2
        let y = point.y - displayHeight / 2

        doc.addElement(XMLElement.image(
            href: dataURL,
            x: x,
            y: y,
            width: displayWidth,
            height: displayHeight
        ))
    }

    @MainActor
    private static func addEmojiElement(
        to doc: SVGDocument,
        emoji: String,
        at point: CGPoint,
        size: CGFloat
    ) {
        let drawSize = NSSize(width: size, height: size)
        let image = NSImage(size: drawSize, flipped: false) { rect in
            let attributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: size * 0.8)
            ]
            let string = NSAttributedString(string: emoji, attributes: attributes)
            let stringSize = string.size()
            let origin = NSPoint(
                x: (rect.width - stringSize.width) / 2,
                y: (rect.height - stringSize.height) / 2
            )
            string.draw(at: origin)
            return true
        }

        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else { return }

        let base64 = pngData.base64EncodedString()
        let dataURL = "data:image/png;base64,\(base64)"
        let x = point.x - size / 2
        let y = point.y - size / 2

        doc.addElement(XMLElement.image(href: dataURL, x: x, y: y, width: size, height: size))
    }

    @MainActor
    private static func addImageElement(
        to doc: SVGDocument,
        url: URL,
        at point: CGPoint,
        size: CGFloat
    ) {
        guard let imageData = try? Data(contentsOf: url) else { return }
        let mimeType: String
        switch url.pathExtension.lowercased() {
        case "png": mimeType = "image/png"
        case "jpg", "jpeg": mimeType = "image/jpeg"
        case "svg": mimeType = "image/svg+xml"
        default: mimeType = "image/png"
        }

        let base64 = imageData.base64EncodedString()
        let dataURL = "data:\(mimeType);base64,\(base64)"
        let x = point.x - size / 2
        let y = point.y - size / 2

        doc.addElement(XMLElement.image(href: dataURL, x: x, y: y, width: size, height: size))
    }

    // MARK: - Label Rendering

    @MainActor
    private static func renderCornerRibbon(label: IconLabel, size: CGSize, to doc: SVGDocument) {
        // Use the same geometry constants as IconGeometry from the package
        let width = size.width * IconGeometry.diagonalWidthRatio

        var pathData = ""
        var centroid: CGPoint
        let rotation: Double

        // Position text slightly closer to the corner than the mathematical
        // centroid (width/3) to better match Icon Composer's rendering.
        let offset = width / 3.3
        switch label.position {
        case .topRight:
            pathData = "M\(fmt(size.width)),0L\(fmt(size.width - width)),0L\(fmt(size.width)),\(fmt(width))Z"
            centroid = CGPoint(x: size.width - offset, y: offset)
            rotation = 45
        case .topLeft:
            pathData = "M0,0L\(fmt(width)),0L0,\(fmt(width))Z"
            centroid = CGPoint(x: offset, y: offset)
            rotation = -45
        case .bottomRight:
            pathData = "M\(fmt(size.width)),\(fmt(size.height))L\(fmt(size.width - width)),\(fmt(size.height))L\(fmt(size.width)),\(fmt(size.height - width))Z"
            centroid = CGPoint(x: size.width - offset, y: size.height - offset)
            rotation = -45
        case .bottomLeft:
            pathData = "M0,\(fmt(size.height))L\(fmt(width)),\(fmt(size.height))L0,\(fmt(size.height - width))Z"
            centroid = CGPoint(x: offset, y: size.height - offset)
            rotation = 45
        default:
            return
        }


        let bgFill = label.backgroundColor.svgFill()
        doc.addElement(XMLElement.path(d: pathData, fill: bgFill))

        let fontSize = IconGeometry.labelFontSize(for: size)
        let foreground = label.resolvedForegroundColor.svgString()
        addLabelContent(label.content, at: centroid, fontSize: fontSize, foreground: foreground, rotation: rotation, to: doc)
    }

    @MainActor
    private static func renderEdgeRibbon(label: IconLabel, size: CGSize, to doc: SVGDocument) {
        let rect = IconGeometry.edgeRibbonRect(for: label.position, in: size)
        guard rect != .zero else { return }

        let bgFill = label.backgroundColor.svgFill()
        doc.addElement(XMLElement.rect(x: rect.minX, y: rect.minY, width: rect.width, height: rect.height, fill: bgFill))

        let center = CGPoint(x: rect.midX, y: rect.midY)
        let fontSize = IconGeometry.labelFontSize(for: size)
        let foreground = label.resolvedForegroundColor.svgString()
        addLabelContent(label.content, at: center, fontSize: fontSize, foreground: foreground, rotation: 0, to: doc)
    }

    @MainActor
    private static func renderPill(label: IconLabel, size: CGSize, to doc: SVGDocument) {
        let fontSize = IconGeometry.labelFontSize(for: size)

        let contentWidth = estimateLabelContentWidth(label.content, fontSize: fontSize)
        let contentSize = CGSize(width: contentWidth, height: fontSize)
        let pillRect = IconGeometry.pillRect(for: label.position, in: size, contentSize: contentSize, cornerRadiusRatio: 0.22)
        let pillHeight = pillRect.height

        let bgFill = label.backgroundColor.svgFill()
        doc.addElement(XMLElement.rect(
            x: pillRect.minX,
            y: pillRect.minY,
            width: pillRect.width,
            height: pillRect.height,
            rx: pillHeight / 2,
            fill: bgFill
        ))

        let center = CGPoint(x: pillRect.midX, y: pillRect.midY)
        let foreground = label.resolvedForegroundColor.svgString()
        addLabelContent(label.content, at: center, fontSize: fontSize, foreground: foreground, rotation: 0, to: doc)
    }

    @MainActor
    private static func addLabelContent(
        _ content: LabelContent,
        at point: CGPoint,
        fontSize: CGFloat,
        foreground: String,
        rotation: Double,
        to doc: SVGDocument
    ) {
        switch content {
        case .text(let text):
            addTextElement(to: doc, text: text, at: point, fontSize: fontSize, foreground: foreground, rotation: rotation)
        case .sfSymbol(let name):
            addSFSymbolElement(to: doc, name: name, at: point, fontSize: fontSize, foreground: foreground)
        case .image(let url):
            addImageElement(to: doc, url: url, at: point, size: fontSize)
        }
    }

    private static func estimateLabelContentWidth(_ content: LabelContent, fontSize: CGFloat) -> CGFloat {
        switch content {
        case .text(let text):
            return CGFloat(text.count) * fontSize * 0.6
        case .sfSymbol, .image:
            return fontSize
        }
    }

    // MARK: - Utilities

    private static func cgPathToSVGPath(_ path: CGPath) -> String {
        var svgPath = ""
        path.applyWithBlock { elementPointer in
            let element = elementPointer.pointee
            let points = element.points
            switch element.type {
            case .moveToPoint:
                svgPath += "M\(fmt(points[0].x)),\(fmt(points[0].y))"
            case .addLineToPoint:
                svgPath += "L\(fmt(points[0].x)),\(fmt(points[0].y))"
            case .addQuadCurveToPoint:
                svgPath += "Q\(fmt(points[0].x)),\(fmt(points[0].y)) \(fmt(points[1].x)),\(fmt(points[1].y))"
            case .addCurveToPoint:
                svgPath += "C\(fmt(points[0].x)),\(fmt(points[0].y)) \(fmt(points[1].x)),\(fmt(points[1].y)) \(fmt(points[2].x)),\(fmt(points[2].y))"
            case .closeSubpath:
                svgPath += "Z"
            @unknown default:
                break
            }
        }
        return svgPath
    }

    private static func fmt(_ n: CGFloat) -> String {
        if n == n.rounded() {
            return String(Int(n))
        }
        return String(format: "%.2f", n)
    }
}
