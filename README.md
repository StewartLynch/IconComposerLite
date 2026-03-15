# IconComposer Lite
<a href="http://www.youtube.com/watch?feature=player_embedded&v=AuXouSw1gxw
" target="_blank"><img src="http://img.youtube.com/vi/AuXouSw1gxw/0.jpg" 
alt="Icon Composer Lite" width="480" height="360" border="1" /></a>

> Click on image above to view demo video

A free, open-source macOS app for designing and exporting iOS and macOS app icons using Apple's Icon Composer format.

![macOS](https://img.shields.io/badge/macOS-26%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange)
![License](https://img.shields.io/badge/license-MIT-green)

> **NOTE:** This was a 3 hour project, mostly Vibe Coded with Claude Code and is not intended to represent my best work.  I used two of my own packages for the [SFSymbol](https://github.com/StewartLynch/SFSymbolPicker) and [Emoji](https://github.com/StewartLynch/EmojiPicker) pickers as well as a package called [Icon Generator](https://github.com/schwa/icon-generator) that was really the inspiration for this project.

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

## Download

Grab the latest release from the [Releases page](https://github.com/StewartLynch/IconComposerLite/releases/latest), or download directly:

[![Download DMG](https://img.shields.io/badge/Download-DMG-blue)](https://github.com/StewartLynch/IconComposerLite/releases/latest/download/IconComposerLite.dmg)

[![Download DMG](https://img.shields.io/github/v/release/StewartLynch/IconComposerLite?label=Download&color=blue)](https://github.com/StewartLynch/IconComposerLite/releases/download/v1.0.0/IconComposerLite.dmg)

## Requirements

- macOS 26 or later
- Xcode 26+

## Building

Clone the repo and open `IconComposerLite.xcodeproj` in Xcode. All Swift Package dependencies will resolve automatically.

```bash
git clone https://github.com/StewartLynch/IconComposerLite.git
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
