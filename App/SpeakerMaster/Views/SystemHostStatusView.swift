import AppKit
import SpeakerMaster
import SwiftUI

/// Honest system-wide host status + permission recovery.
struct SystemHostStatusView: View {
    @EnvironmentObject private var model: AppModel
    /// When true, healthy/inactive phases render as a thin caption so path CTAs stay primary.
    var compactWhenHealthy: Bool = false

    private var isAttentionPhase: Bool {
        switch model.systemHost.phase {
        case .needsPermission, .failed, .activeInAppOnly:
            return true
        default:
            return false
        }
    }

    var body: some View {
        let empty = SystemEQEmptyStateCopy.forPhase(model.systemHost.phase)
        // Keep path CTAs primary: inactive/healthy → thin caption; permission/fail → full panel.
        if compactWhenHealthy && !isAttentionPhase {
            compactHealthyRow(title: empty?.title ?? statusTitle, detail: empty?.body ?? model.systemHost.detail)
        } else {
            fullPanel(empty: empty)
        }
    }

    private func compactHealthyRow(title: String, detail: String) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(statusColor)
                .frame(width: 7, height: 7)
                .accessibilityHidden(true)
            Text(title)
                .font(SMTheme.captionFont)
                .foregroundStyle(SMTheme.muted)
            if !detail.isEmpty {
                Text("·")
                    .foregroundStyle(SMTheme.tertiary)
                    .accessibilityHidden(true)
                Text(detail)
                    .font(SMTheme.captionFont)
                    .foregroundStyle(SMTheme.tertiary)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("System EQ status: \(title). \(detail)")
    }

    @ViewBuilder
    private func fullPanel(empty: SystemEQEmptyStateCopy?) -> some View {
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
                        .frame(minHeight: SMTheme.minTouch)
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
                        .frame(minHeight: SMTheme.minTouch)
                    }
                }
            } else if showsLegacyActions {
                HStack(spacing: SMTheme.spaceSM) {
                    if model.systemHost.status == .readyPendingPermission {
                        Button("Open Privacy Settings") {
                            model.systemHost.openPrivacySettings()
                        }
                        .smProminentButton()
                        .frame(minHeight: SMTheme.minTouch)
                    }
                    Button("Retry system EQ") {
                        model.systemHost.retrySystemWide()
                    }
                    .smBorderedButton()
                    .frame(minHeight: SMTheme.minTouch)
                }
            }
        }
        .padding(SMTheme.spaceMD)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(panelFill, in: RoundedRectangle(cornerRadius: SMTheme.radiusPanel, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: SMTheme.radiusPanel, style: .continuous)
                .strokeBorder(borderColor, lineWidth: empty != nil ? 1 : 0.5)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("System EQ status: \(empty?.title ?? statusTitle). \(empty?.body ?? model.systemHost.detail)")
    }

    private var panelFill: Color {
        switch model.systemHost.phase {
        case .needsPermission, .failed:
            return SMTheme.danger.opacity(0.08)
        case .activeInAppOnly:
            return SMTheme.warning.opacity(0.10)
        case .inactive:
            return Color(nsColor: .controlBackgroundColor)
        default:
            return Color(nsColor: .controlBackgroundColor)
        }
    }

    private var borderColor: Color {
        switch model.systemHost.phase {
        case .needsPermission, .failed: return SMTheme.danger.opacity(0.35)
        case .activeInAppOnly: return SMTheme.warning.opacity(0.4)
        default: return SMTheme.border.opacity(0.55)
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
