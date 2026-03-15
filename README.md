# IconComposer Lite

A free, open-source macOS app for designing and exporting iOS and macOS app icons using Apple's Icon Composer format.

![macOS](https://img.shields.io/badge/macOS-26%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange)
![License](https://img.shields.io/badge/license-MIT-green)

## What It Does

**IconComposer Lite** gives you a visual editor to build app icons and export them as `.icon` bundles — the same format used by Apple's Icon Composer tool. Design your icon, preview it in real time, and export it ready for Xcode or for opening in IconComposer for more fine tuning.

## Features

- **Background options** — solid color, automatic gradient (auto-generated from your color), or custom linear gradient
- **Center content** — place an SF Symbol, emoji, custom text, or your own image at the center
- **Labels & badges** — add text labels in various positions: corners, edges, and pill shapes
- **Drag to position** — drag center content interactively in the preview
- **Drag-and-drop images** — drop image files directly onto the preview or image well
- **Real-time preview** — see your icon update live as you configure it
- **Export to `.icon`** — outputs a proper Icon Composer bundle with SVG layers and `icon.json`, ready for Xcode

## Requirements

- macOS 26 or later
- Xcode 26+

## Building

Clone the repo and open `IconComposerLite.xcodeproj` in Xcode. All Swift Package dependencies will resolve automatically.

```bash
git clone https://github.com/your-username/IconComposerLite.git
cd IconComposerLite
open IconComposerLite.xcodeproj
```

## How It Works

The app is built with SwiftUI and uses several packages to handle the heavy lifting:

| Package | Role |
|---|---|
| `IconRendering` | Core icon rendering primitives and squircle shapes |
| `IconComposerFormat` | Icon Composer bundle structure and serialization |
| `SVGXML` | SVG generation for icon layers |
| `SFSymbolPicker` | Browse and pick SF Symbols |
| `EmojiPicker` | Browse and pick emojis |

When you export, the app renders your center content and labels into SVG assets, packages them into an `.icon` bundle alongside an `icon.json`, and writes everything to disk. The bundle is the same format Xcode's Icon Composer tool produces, so you can open, modify, or use it anywhere that format is supported.

## Project Structure

```
IconComposerLite/
├── IconComposerLiteApp.swift   # App entry point
├── ContentView.swift           # Main split-pane layout
├── IconConfig.swift            # Observable data model
├── IconConfigPanel.swift       # Configuration UI (background, content, labels)
├── IconPreviewView.swift       # Live preview with drag support
└── IconExporter.swift          # Export logic and SVG generation
```

## Contributing

Contributions are welcome. Open an issue to discuss what you'd like to change, or submit a pull request.

## License

MIT
