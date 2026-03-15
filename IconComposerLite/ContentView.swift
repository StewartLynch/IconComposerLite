//
//----------------------------------------------
// Original project: IconComposerLite
//
// Follow me on Mastodon: https://iosdev.space/@StewartLynch
// Follow me on Threads: https://www.threads.net/@stewartlynch
// Follow me on Bluesky: https://bsky.app/profile/stewartlynch.bsky.social
// Follow me on X: https://x.com/StewartLynch
// Follow me on LinkedIn: https://linkedin.com/in/StewartLynch
// Email: slynch@createchsol.com
// Subscribe on YouTube: https://youTube.com/@StewartLynch
// Buy me a ko-fi:  https://ko-fi.com/StewartLynch
//----------------------------------------------
// Copyright © 2026 CreaTECH Solutions (Stewart Lynch). All rights reserved.


import SwiftUI

struct ContentView: View {
    @State private var config = IconConfig()

    var body: some View {
        HSplitView {
            IconPreviewView(config: config)
                .frame(minWidth: 300)

            IconConfigPanel(config: config)
                .frame(minWidth: 280, idealWidth: 320)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    IconExporter.export(config: config)
                } label: {
                    Label("Export", systemImage: "square.and.arrow.up")
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
