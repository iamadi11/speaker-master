import SpeakerMaster
import SwiftUI

/// Honest system-wide host status + permission recovery (ui-ux-pro-max: error recovery).
struct SystemHostStatusView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                    .accessibilityHidden(true)
                Text(statusTitle)
                    .font(SMTheme.captionFont.weight(.semibold))
                    .foregroundStyle(SMTheme.ink)
                Spacer(minLength: 0)
            }

            Text(model.systemHost.detail)
                .font(SMTheme.captionFont)
                .foregroundStyle(SMTheme.muted)
                .fixedSize(horizontal: false, vertical: true)

            if showsActions {
                HStack(spacing: 10) {
                    if model.systemHost.status == .readyPendingPermission {
                        Button("Open Privacy Settings") {
                            model.systemHost.openPrivacySettings()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(SMTheme.accent)
                        .accessibilityHint("Opens Screen and System Audio Recording settings")
                    }
                    Button("Retry system EQ") {
                        model.systemHost.retrySystemWide()
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SMTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(SMTheme.border, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("System EQ status: \(statusTitle). \(model.systemHost.detail)")
    }

    private var statusTitle: String {
        switch model.systemHost.status {
        case .inactive: return "System EQ off"
        case .starting: return "Starting system EQ…"
        case .readyPendingPermission: return "Permission needed"
        case .activeInAppOnly: return "In-app audition only"
        case .activeSystemWide: return "System-wide EQ active"
        case .failed: return "System EQ failed"
        }
    }

    private var statusColor: Color {
        switch model.systemHost.status {
        case .activeSystemWide: return SMTheme.accent
        case .starting: return SMTheme.muted
        case .readyPendingPermission, .failed: return SMTheme.danger
        case .activeInAppOnly: return Color.orange
        case .inactive: return SMTheme.border
        }
    }

    private var showsActions: Bool {
        switch model.systemHost.status {
        case .readyPendingPermission, .failed, .activeInAppOnly:
            return true
        default:
            return false
        }
    }
}
