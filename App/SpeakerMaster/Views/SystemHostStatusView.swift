import SpeakerMaster
import SwiftUI

/// Honest system-wide host status + permission recovery (ui-ux-pro-max: empty state + action).
struct SystemHostStatusView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        let empty = SystemEQEmptyStateCopy.forPhase(model.systemHost.phase)
        VStack(alignment: .leading, spacing: SMTheme.spaceSM) {
            HStack(spacing: 8) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                    .accessibilityHidden(true)
                Text(empty?.title ?? statusTitle)
                    .font(SMTheme.captionFont.weight(.semibold))
                    .foregroundStyle(SMTheme.ink)
                Spacer(minLength: 0)
            }

            Text(empty?.body ?? model.systemHost.detail)
                .font(SMTheme.captionFont)
                .foregroundStyle(SMTheme.muted)
                .fixedSize(horizontal: false, vertical: true)

            if let empty, empty.primaryActionTitle != nil || empty.secondaryActionTitle != nil {
                HStack(spacing: SMTheme.spaceSM) {
                    if let primary = empty.primaryActionTitle {
                        Button(primary) {
                            if primary == "Open Privacy Settings" {
                                model.systemHost.openPrivacySettings()
                            } else {
                                model.systemHost.retrySystemWide()
                            }
                        }
                        .smProminentButton()
                        .frame(minHeight: 36)
                        .accessibilityHint(
                            primary == "Open Privacy Settings"
                                ? "Opens Screen and System Audio Recording settings"
                                : "Retries the system-wide process tap"
                        )
                    }
                    if let secondary = empty.secondaryActionTitle {
                        Button(secondary) {
                            if secondary == "Open Privacy Settings" {
                                model.systemHost.openPrivacySettings()
                            } else {
                                model.systemHost.retrySystemWide()
                            }
                        }
                        .smBorderedButton()
                        .frame(minHeight: 36)
                    }
                }
            } else if showsLegacyActions {
                HStack(spacing: SMTheme.spaceSM) {
                    if model.systemHost.status == .readyPendingPermission {
                        Button("Open Privacy Settings") {
                            model.systemHost.openPrivacySettings()
                        }
                        .smProminentButton()
                        .frame(minHeight: 36)
                    }
                    Button("Retry system EQ") {
                        model.systemHost.retrySystemWide()
                    }
                    .smBorderedButton()
                    .frame(minHeight: 36)
                }
            }
        }
        .padding(SMTheme.spaceMD)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(panelFill)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(borderColor, lineWidth: empty != nil ? 1.5 : 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("System EQ status: \(empty?.title ?? statusTitle). \(empty?.body ?? model.systemHost.detail)")
    }

    private var panelFill: Color {
        switch model.systemHost.phase {
        case .needsPermission, .failed:
            return SMTheme.danger.opacity(0.06)
        case .activeInAppOnly:
            return SMTheme.warning.opacity(0.08)
        case .inactive:
            return SMTheme.surface
        default:
            return SMTheme.surface
        }
    }

    private var borderColor: Color {
        switch model.systemHost.phase {
        case .needsPermission, .failed: return SMTheme.danger.opacity(0.35)
        case .activeInAppOnly: return SMTheme.warning.opacity(0.4)
        default: return SMTheme.border
        }
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
        case .activeInAppOnly: return SMTheme.warning
        case .inactive: return SMTheme.border
        }
    }

    private var showsLegacyActions: Bool {
        switch model.systemHost.status {
        case .readyPendingPermission, .failed, .activeInAppOnly:
            return true
        default:
            return false
        }
    }
}
