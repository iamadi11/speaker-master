import AppKit
import SpeakerMaster
import SwiftUI

struct AutoContainerView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        switch model.autoScreen {
        case .pathPicker:
            AutoPathPickerView()
        case .measure:
            MeasureFlowView()
        case .narrow:
            NarrowFlowView()
        case .home:
            AutoHomeView()
        }
    }
}

/// First-launch / no-profile: two quiet paths (ux-journey-pm + macos-design sparse chrome).
struct AutoPathPickerView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SMTheme.spaceXL) {
                VStack(alignment: .leading, spacing: SMTheme.spaceSM) {
                    Text(pathPickerEyebrow)
                        .font(SMTheme.captionFont.weight(.semibold))
                        .foregroundStyle(SMTheme.tertiary)
                        .textCase(.uppercase)
                        .tracking(0.4)
                        .accessibilityAddTraits(.isHeader)
                    Text("Make this speaker sound better")
                        .font(SMTheme.titleFont)
                        .foregroundStyle(SMTheme.ink)
                    Text("Pick one path. Measure listens with a mic for this speaker here. Narrow applies a fast preset — not calibrated. Safety limits stay on.")
                        .font(SMTheme.bodyFont)
                        .foregroundStyle(SMTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if model.headphoneWarning {
                    Label(
                        "This output looks like headphones. Narrow is tuned for speakers — proceed carefully or pick another output.",
                        systemImage: "exclamationmark.triangle.fill"
                    )
                    .font(SMTheme.captionFont)
                    .foregroundStyle(SMTheme.danger)
                    .padding(SMTheme.spaceMD)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(SMTheme.danger.opacity(0.08), in: RoundedRectangle(cornerRadius: SMTheme.radiusCard, style: .continuous))
                }

                VStack(spacing: SMTheme.spaceSM) {
                    pathRow(
                        title: "Measure",
                        subtitle: "Use a mic · best for this speaker here",
                        systemImage: "mic.fill"
                    ) {
                        model.autoScreen = .measure
                    }
                    pathRow(
                        title: "Narrow",
                        subtitle: "No mic · fast preset · not calibrated",
                        systemImage: "square.grid.2x2"
                    ) {
                        model.autoScreen = .narrow
                    }
                }

                // System EQ quieter than the two paths on first launch (journey anti-pattern).
                SystemHostStatusView(compactWhenHealthy: true)

                Text("Optional: Play audition (⇧⌘A) after you apply a path — or hold Bypass to A/B.")
                    .font(SMTheme.captionFont)
                    .foregroundStyle(SMTheme.tertiary)
                    .fixedSize(horizontal: false, vertical: true)
                Button(model.player.isPlaying ? "Stop audition" : "Play audition noise") {
                    model.toggleAudition()
                }
                .smBorderedButton()
                .help("Optional: prove the curve in-app (⇧⌘A)")
            }
            .padding(SMTheme.spaceXXL)
            .frame(maxWidth: 720, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var pathPickerEyebrow: String {
        model.statusMessage.hasPrefix("New speaker")
            ? "New speaker detected"
            : "No EQ yet for this speaker"
    }

    private func pathRow(
        title: String,
        subtitle: String,
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: SMTheme.spaceMD) {
                Image(systemName: systemImage)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(SMTheme.accent)
                    .frame(width: 28)
                    .symbolRenderingMode(.hierarchical)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(SMTheme.headlineFont)
                        .foregroundStyle(SMTheme.ink)
                    Text(subtitle)
                        .font(SMTheme.captionFont)
                        .foregroundStyle(SMTheme.muted)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(SMTheme.tertiary)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, SMTheme.spaceLG)
            .padding(.vertical, SMTheme.spaceMD)
            .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: SMTheme.radiusPanel, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: SMTheme.radiusPanel, style: .continuous)
                    .strokeBorder(SMTheme.border.opacity(0.45), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }
}

struct AutoHomeView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: SMTheme.spaceLG) {
            VStack(alignment: .leading, spacing: SMTheme.spaceSM) {
                Text("On for \(model.outputIdentity.displayName)")
                    .font(SMTheme.titleFont)
                    .foregroundStyle(SMTheme.ink)
                Text(pathLabel)
                    .font(SMTheme.bodyFont)
                    .foregroundStyle(SMTheme.muted)
                Text("Stays on until Retry or a different speaker.")
                    .font(SMTheme.captionFont)
                    .foregroundStyle(SMTheme.tertiary)
                Text(bypassHint)
                    .font(SMTheme.captionFont.weight(.medium))
                    .foregroundStyle(SMTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityLabel(bypassHint)
                if let note = model.measureNote {
                    Text(note)
                        .font(SMTheme.captionFont)
                        .foregroundStyle(SMTheme.tertiary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if model.lastSource == .measure, let quality = model.lastMeasureQuality {
                    Text(quality == .good
                          ? "Take quality: good"
                          : "Take quality: cautious · retry if unsure")
                        .font(SMTheme.captionFont.weight(.medium))
                        .foregroundStyle(SMTheme.ink)
                }
            }

            // Trust action is Bypass in the toolbar (⌘B). Keep Retry / Custom equal weight;
            // Audition stays optional caption-level (ux-journey-pm anti-pattern).
            HStack(spacing: SMTheme.spaceSM) {
                Button("Retry") { model.retry() }
                    .smBorderedButton()
                    .frame(minHeight: SMTheme.minTouch)
                    .help("Clear this speaker’s Auto result and choose Measure or Narrow again")
                Button("Open Custom") { model.tab = .custom }
                    .smBorderedButton()
                    .frame(minHeight: SMTheme.minTouch)
                    .accessibilityHint("Refine this Auto result in Custom — Auto home stays sacred")
            }

            Button(model.player.isPlaying ? "Stop audition" : "Play audition (optional)") {
                model.toggleAudition()
            }
            .buttonStyle(.borderless)
            .font(SMTheme.captionFont)
            .foregroundStyle(SMTheme.tertiary)
            .help("Optional in-app proof (⇧⌘A)")
            .accessibilityHint("Optional — Bypass in the toolbar is the primary A/B")

            SystemHostStatusView(compactWhenHealthy: true)
            Spacer(minLength: 0)
        }
        .padding(SMTheme.spaceXXL)
        .frame(maxWidth: 720, maxHeight: .infinity, alignment: .topLeading)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var pathLabel: String {
        switch model.lastSource {
        case .measure: return "Path: Measure · Saved for this speaker"
        case .narrow:
            let name = model.lastNarrowPresetID.flatMap { NarrowCatalog.preset(id: $0)?.title } ?? "Narrow"
            return "Path: Narrow · \(name) · Saved for this speaker"
        case .custom: return "Path: Custom · edits on this speaker"
        case .none: return "Path: —"
        }
    }

    private var bypassHint: String {
        "Next: hold Bypass in the toolbar to hear before (A/B). Release to hear the fix again."
    }
}
