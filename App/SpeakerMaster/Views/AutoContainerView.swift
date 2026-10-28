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
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
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

                HStack(spacing: 16) {
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
            .padding(22)
            .frame(maxWidth: .infinity, minHeight: 220, alignment: .topLeading)
            .background(SMTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(SMTheme.border, lineWidth: 1)
            )
            .shadow(color: SMTheme.ink.opacity(0.04), radius: 12, y: 4)
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
            .buttonStyle(.borderedProminent)
            .tint(SMTheme.accent)
            Text("Hear EQ changes in-app while system-wide tap is staged.")
                .font(SMTheme.captionFont)
                .foregroundStyle(SMTheme.muted)
            Spacer()
        }
    }
}

struct AutoHomeView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
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
            }

            HStack(spacing: 12) {
                BypassButton()
                Button(model.player.isPlaying ? "Stop audition" : "Play audition") {
                    model.toggleAudition()
                }
                .buttonStyle(.bordered)
            }

            HStack(spacing: 12) {
                Button("Retry") { model.retry() }
                    .buttonStyle(.bordered)
                Button("Open Custom") { model.tab = .custom }
                    .buttonStyle(.borderedProminent)
                    .tint(SMTheme.accent)
            }

            Text(model.systemHost.detail)
                .font(SMTheme.captionFont)
                .foregroundStyle(SMTheme.muted)
                .padding(.top, 8)

            Spacer()
        }
        .padding(28)
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
