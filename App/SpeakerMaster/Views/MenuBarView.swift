import AppKit
import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(model.outputIdentity.displayName)
                .font(.headline)
            Text(model.statusMessage)
                .font(.caption)
                .foregroundStyle(.secondary)
            Divider()
            Button(model.bypassed ? "Disable Bypass" : "Bypass (hear before)") {
                model.setBypass(!model.bypassed)
            }
            Button(model.player.isPlaying ? "Stop Audition" : "Play Audition") {
                model.toggleAudition()
            }
            Divider()
            Button("Quit Speaker Master") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(4)
    }
}
