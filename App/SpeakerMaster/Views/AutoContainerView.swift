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

struct AutoPathPickerView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SMTheme.spaceLG) {
                VStack(alignment: .leading, spacing: SMTheme.spaceXS) {
                    Text("Make this speaker sound better")
                        .font(SMTheme.titleFont)
                        .foregroundStyle(SMTheme.ink)
                    Text("Safety limits always on. Measure uses a mic for this speaker here. Narrow is a fast preset — not the same as measuring.")
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
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(SMTheme.danger.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }

                HStack(spacing: SMTheme.spaceMD) {
                    pathCard(
                        title: "Measure",
                        subtitle: "Use a mic",
                        detail: "Listen with a mic, then fix this speaker in this place.",
                        systemImage: "mic.fill"
                    ) {
                        model.autoScreen = .measure
                    }
                    pathCard(
                        title: "Narrow",
                        subtitle: "No mic needed",
                        detail: "Quick improve without a mic. Not calibrated.",
                        systemImage: "square.grid.2x2.fill"
                    ) {
                        model.autoScreen = .narrow
                    }
                }

                SystemHostStatusView()
                auditionRow
            }
            .padding(28)
        }
    }

    private func pathCard(
        title: String,
        subtitle: String,
        detail: String,
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: systemImage)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(SMTheme.accent)
                    .accessibilityHidden(true)
                Text(title)
                    .font(SMTheme.headlineFont)
                    .foregroundStyle(SMTheme.ink)
                Text(subtitle)
                    .font(.system(.subheadline, design: .rounded).weight(.medium))
                    .foregroundStyle(SMTheme.accent)
                Text(detail)
                    .font(SMTheme.bodyFont)
                    .foregroundStyle(SMTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            .padding(SMTheme.spaceLG)
            .frame(maxWidth: .infinity, minHeight: 200, alignment: .topLeading)
            .background(SMTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(SMTheme.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }

    private var auditionRow: some View {
        HStack {
            Button(model.player.isPlaying ? "Stop audition" : "Play audition noise") {
                model.toggleAudition()
            }
            .smProminentButton()
            Text("In-app noise proves the curve; system-wide EQ covers Spotify/YouTube once the tap is active.")
                .font(SMTheme.captionFont)
                .foregroundStyle(SMTheme.muted)
            Spacer()
        }
    }
}

struct AutoHomeView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: SMTheme.spaceLG) {
            VStack(alignment: .leading, spacing: SMTheme.spaceXS) {
                Text("On for: \(model.outputIdentity.displayName)")
                    .font(SMTheme.titleFont)
                    .foregroundStyle(SMTheme.ink)
                Text(pathLabel)
                    .font(SMTheme.bodyFont)
                    .foregroundStyle(SMTheme.muted)
                if let note = model.measureNote {
                    Text(note)
                        .font(SMTheme.captionFont)
                        .foregroundStyle(SMTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            HStack(spacing: SMTheme.spaceSM) {
                Button(model.player.isPlaying ? "Stop audition" : "Play audition") {
                    model.toggleAudition()
                }
                .smBorderedButton()
                .frame(minHeight: 36)
                Button("Retry") { model.retry() }
                    .smBorderedButton()
                    .frame(minHeight: 36)
                Button("Open Custom") { model.tab = .custom }
                    .smProminentButton()
                    .frame(minHeight: 36)
            }

            SystemHostStatusView()

            Spacer(minLength: 0)
        }
        .padding(SMTheme.spaceLG)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var pathLabel: String {
        switch model.lastSource {
        case .measure: return "Path: Measure · Saved for this speaker"
        case .narrow:
            let name = model.lastNarrowPresetID.flatMap { NarrowCatalog.preset(id: $0)?.title } ?? "Narrow"
            return "Path: Narrow · \(name)"
        case .custom: return "Path: Custom"
        case .none: return "Path: —"
        }
    }
}
