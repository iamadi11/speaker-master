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
            Text(menuSystemLine)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Divider()
            Button(model.bypassed ? "Disable Bypass" : "Bypass (hear before)") {
                model.setBypass(!model.bypassed)
            }
            Button(model.player.isPlaying ? "Stop Audition" : "Play Audition") {
                model.toggleAudition()
            }
            if model.systemHost.status == .readyPendingPermission {
                Button("Open Privacy Settings") {
                    model.systemHost.openPrivacySettings()
                }
                Button("Retry system EQ") {
                    model.systemHost.retrySystemWide()
                }
            }
            Divider()
            Button("Quit Speaker Master") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(4)
    }

    private var menuSystemLine: String {
        switch model.systemHost.status {
        case .activeSystemWide: return "System-wide EQ on"
        case .starting: return "Starting system EQ…"
        case .readyPendingPermission: return "Need Screen & System Audio permission"
        case .activeInAppOnly: return "In-app audition only"
        case .failed: return "System EQ failed"
        case .inactive: return "System EQ off"
        }
    }
}
