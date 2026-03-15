import SwiftUI
import IconRendering
import SFSymbolPicker
import EmojiPicker
import UniformTypeIdentifiers

struct IconConfigPanel: View {
    @Bindable var config: IconConfig

    var body: some View {
        Form {
            BackgroundSection(config: config)
            CenterContentSection(config: config)
            LabelsSection(config: config)
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
    }
}

// MARK: - Background Section

private struct BackgroundSection: View {
    @Bindable var config: IconConfig

    var body: some View {
        Section("Background") {
            Picker("Type", selection: $config.backgroundType) {
                ForEach(BackgroundType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }

            switch config.backgroundType {
            case .solid, .automaticGradient:
                ColorPicker("Color", selection: $config.backgroundColor, supportsOpacity: false)
            case .linearGradient:
                ColorPicker("Top", selection: $config.gradientTopColor, supportsOpacity: false)
                ColorPicker("Bottom", selection: $config.gradientBottomColor, supportsOpacity: false)
            }
        }
    }
}

// MARK: - Center Content Section

private struct CenterContentSection: View {
    @Bindable var config: IconConfig
    @State private var showSymbolPicker = false
    @State private var showEmojiPicker = false
    @State private var symbolLoader = SymbolLoader()
    @State private var isImageTargeted = false

    var body: some View {
        Section("Center Content") {
            Picker("Type", selection: $config.centerContentKind) {
                ForEach(CenterContentKind.allCases, id: \.self) { kind in
                    Text(kind.rawValue).tag(kind)
                }
            }

            switch config.centerContentKind {
            case .none:
                EmptyView()

            case .text:
                TextField("Text", text: $config.centerText)
                ColorPicker("Color", selection: $config.centerColor, supportsOpacity: false)
                sizeSlider
                resetPositionButton

            case .sfSymbol:
                Button {
                    showSymbolPicker = true
                } label: {
                    HStack {
                        Text("Symbol")
                        Spacer()
                        if !config.centerText.isEmpty {
                            Image(systemName: config.centerText)
                                .font(.title2)
                            Text(config.centerText)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("Select...")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .popover(isPresented: $showSymbolPicker) {
                    SymbolView(loader: symbolLoader, selectedSymbol: $config.centerText)
                        .frame(width: 340, height: 400)
                }

                ColorPicker("Color", selection: $config.centerColor, supportsOpacity: false)
                sizeSlider
                resetPositionButton

            case .emoji:
                Button {
                    showEmojiPicker = true
                } label: {
                    HStack {
                        Text("Emoji")
                        Spacer()
                        if !config.emojiText.isEmpty {
                            Text(config.emojiText)
                                .font(.title)
                        } else {
                            Text("Select...")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .popover(isPresented: $showEmojiPicker) {
                    EmojiPickerView(selectedEmoji: $config.emojiText)
                        .frame(width: 340, height: 400)
                }

                sizeSlider
                resetPositionButton

            case .image:
                ImageDropWell(imageURL: $config.centerImageURL, isTargeted: $isImageTargeted)
                sizeSlider
                resetPositionButton
            }
        }
    }

    private var sizeSlider: some View {
        HStack {
            Text("Size")
            Slider(value: $config.centerSizeRatio, in: 0.1...2.0, step: 0.05)
            Text(String(format: "%.0f%%", config.centerSizeRatio * 100))
                .monospacedDigit()
                .frame(width: 44, alignment: .trailing)
        }
    }

    private var resetPositionButton: some View {
        Group {
            if config.centerOffsetX != 0 || config.centerOffsetY != 0 {
                Button("Reset Position") {
                    config.centerOffsetX = 0
                    config.centerOffsetY = 0
                }
                .font(.caption)
            }
        }
    }
}

// MARK: - Label Section

private struct LabelsSection: View {
    @Bindable var config: IconConfig

    var body: some View {
        Section("Label") {
            Button(config.labelEnabled ? "Remove Label" : "Add Label") {
                config.labelEnabled.toggle()
            }

            if config.labelEnabled {
                TextField("Text", text: $config.label.contentText)

                Picker("Position", selection: $config.label.position) {
                    ForEach(LabelPosition.allCases, id: \.self) { position in
                        Text(position.rawValue).tag(position)
                    }
                }

                ColorPicker("Background", selection: $config.label.backgroundColor, supportsOpacity: false)
                ColorPicker("Text Color", selection: $config.label.foregroundColor, supportsOpacity: false)
            }
        }
    }
}

// MARK: - Image Drop Well

private struct ImageDropWell: View {
    @Binding var imageURL: URL?
    @Binding var isTargeted: Bool

    var body: some View {
        VStack(spacing: 8) {
            if let url = imageURL, let nsImage = NSImage(contentsOf: url) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                Button("Remove Image", role: .destructive) {
                    imageURL = nil
                }
                .font(.caption)
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(
                            style: StrokeStyle(lineWidth: 2, dash: [6, 3])
                        )
                        .foregroundStyle(isTargeted ? Color.accentColor : .secondary)
                        .frame(height: 80)

                    VStack(spacing: 4) {
                        Image(systemName: "photo.badge.plus")
                            .font(.title2)
                        Text("Drop image here")
                            .font(.caption)
                    }
                    .foregroundStyle(isTargeted ? Color.accentColor : .secondary)
                }
            }
        }
        .dropDestination(for: URL.self) { urls, _ in
            guard let url = urls.first, isImageFile(url) else { return false }
            imageURL = url
            return true
        } isTargeted: { targeted in
            isTargeted = targeted
        }
    }

    private func isImageFile(_ url: URL) -> Bool {
        let imageExtensions: Set<String> = ["png", "jpg", "jpeg", "tiff", "gif", "bmp", "heic", "webp", "svg"]
        return imageExtensions.contains(url.pathExtension.lowercased())
    }
}


