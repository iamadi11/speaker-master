import SpeakerMaster
import SwiftUI

struct NarrowFlowView: View {
    @EnvironmentObject private var model: AppModel

    private var suggestedID: String {
        NarrowCatalog.suggestedPresetID(deviceName: model.outputIdentity.displayName)
    }

    var body: some View {
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

            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 200), spacing: SMTheme.spaceSM)],
                spacing: SMTheme.spaceSM
            ) {
                ForEach(NarrowCatalog.all) { preset in
                    Button {
                        model.applyNarrow(preset: preset)
                    } label: {
                        VStack(alignment: .leading, spacing: SMTheme.spaceXS) {
                            HStack {
                                Text(preset.title)
                                    .font(SMTheme.headlineFont)
                                    .foregroundStyle(SMTheme.ink)
                                Spacer(minLength: 0)
                                if preset.id == suggestedID {
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
                        .background(preset.id == suggestedID ? SMTheme.accentSoft : SMTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .strokeBorder(
                                    preset.id == suggestedID ? SMTheme.accent : SMTheme.border,
                                    lineWidth: preset.id == suggestedID ? 1.5 : 1
                                )
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(preset.title)
                    .accessibilityHint(preset.summary)
                    .accessibilityAddTraits(preset.id == suggestedID ? .isSelected : [])
                }
            }

            Spacer(minLength: 0)
        }
        .padding(SMTheme.spaceLG)
    }
}
