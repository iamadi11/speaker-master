import SpeakerMaster
import SwiftUI

struct NarrowFlowView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var suggestedID: String {
        NarrowCatalog.suggestedPresetID(deviceName: model.outputIdentity.displayName)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SMTheme.spaceLG) {
                Button {
                    model.autoScreen = .pathPicker
                } label: {
                    Label("Back", systemImage: "chevron.left")
                }
                .buttonStyle(.borderless)
                .frame(minHeight: 36)

                VStack(alignment: .leading, spacing: SMTheme.spaceXS) {
                    Text("Narrow")
                        .font(SMTheme.titleFont)
                        .foregroundStyle(SMTheme.ink)
                    Text("Quick improve without a mic. Saved for this speaker until Retry. For a better match, use Measure.")
                        .font(SMTheme.bodyFont)
                        .foregroundStyle(SMTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if model.headphoneWarning {
                    Label(
                        "This output looks like headphones. Narrow tiles are for speakers — prefer “Just make it safer,” or switch output.",
                        systemImage: "exclamationmark.triangle.fill"
                    )
                    .font(SMTheme.captionFont)
                    .foregroundStyle(SMTheme.warning)
                    .padding(SMTheme.spaceSM)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(SMTheme.warning.opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .accessibilityLabel("Headphones warning for Narrow")
                }

                ForEach(NarrowCatalog.categoriesInOrder) { category in
                    let presets = NarrowCatalog.presets(in: category)
                    if !presets.isEmpty {
                        VStack(alignment: .leading, spacing: SMTheme.spaceSM) {
                            Text(category.title)
                                .font(SMTheme.captionFont.weight(.semibold))
                                .foregroundStyle(SMTheme.muted)
                                .textCase(.uppercase)
                                .tracking(0.6)
                            LazyVGrid(
                                columns: [GridItem(.adaptive(minimum: 200), spacing: SMTheme.spaceSM)],
                                spacing: SMTheme.spaceSM
                            ) {
                                ForEach(presets) { preset in
                                    presetTile(preset)
                                }
                            }
                        }
                    }
                }
            }
            .padding(SMTheme.spaceLG)
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.18), value: suggestedID)
    }

    private func presetTile(_ preset: NarrowPreset) -> some View {
        let suggested = preset.id == suggestedID
        return Button {
            model.applyNarrow(preset: preset)
        } label: {
            VStack(alignment: .leading, spacing: SMTheme.spaceXS) {
                HStack {
                    Text(preset.title)
                        .font(SMTheme.headlineFont)
                        .foregroundStyle(SMTheme.ink)
                    Spacer(minLength: 0)
                    if suggested {
                        Text("Suggested")
                            .font(SMTheme.captionFont.weight(.semibold))
                            .foregroundStyle(SMTheme.accent)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(SMTheme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    }
                }
                Text(preset.summary)
                    .font(SMTheme.captionFont)
                    .foregroundStyle(SMTheme.muted)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(SMTheme.spaceMD)
            .frame(maxWidth: .infinity, minHeight: 100, alignment: .topLeading)
            .background(suggested ? SMTheme.accentSoft : SMTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(
                        suggested ? SMTheme.accent : SMTheme.border,
                        lineWidth: suggested ? 1.5 : 1
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(preset.title), \(preset.category.title)")
        .accessibilityHint(preset.summary)
        .accessibilityAddTraits(suggested ? .isSelected : [])
    }
}
