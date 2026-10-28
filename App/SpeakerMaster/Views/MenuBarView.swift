import AppKit
import SwiftUI

/// Menu bar extra — macos-patterns: keep compact, actionable, no web chrome.
struct MenuBarView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: SMTheme.spaceSM) {
            Text(model.outputIdentity.displayName)
                .font(SMTheme.headlineFont)
                .foregroundStyle(SMTheme.ink)
                .lineLimit(1)
            Text(model.statusMessage)
                .font(SMTheme.captionFont)
                .foregroundStyle(SMTheme.muted)
                .lineLimit(2)
            Text(menuSystemLine)
                .font(.system(.caption2))
                .foregroundStyle(SMTheme.tertiary)

            Divider()

            Button(model.bypassed ? "Disable Bypass" : "Bypass (hear before)") {
                model.setBypass(!model.bypassed)
            }
            .keyboardShortcut("b")

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

            Button("Show Speaker Master") {
                NSApp.activate(ignoringOtherApps: true)
                for window in NSApp.windows where window.canBecomeMain {
                    window.makeKeyAndOrderFront(nil)
                    break
                }
            }

            Button("Quit Speaker Master") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        .padding(SMTheme.spaceSM)
        .frame(minWidth: 240)
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
