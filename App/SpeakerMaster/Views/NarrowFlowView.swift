import SpeakerMaster
import SwiftUI

struct NarrowFlowView: View {
    @EnvironmentObject private var model: AppModel

    private var suggestedID: String {
        NarrowCatalog.suggestedPresetID(deviceName: model.outputIdentity.displayName)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Button {
                model.autoScreen = .pathPicker
            } label: {
                Label("Back", systemImage: "chevron.left")
            }
            .buttonStyle(.borderless)

            Text("Narrow")
                .font(SMTheme.titleFont)
                .foregroundStyle(SMTheme.ink)
            Text("Quick improve without a mic. Saved for this speaker until Retry. For a better match, use Measure.")
                .font(SMTheme.bodyFont)
                .foregroundStyle(SMTheme.muted)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 200), spacing: 12)], spacing: 12) {
                ForEach(NarrowCatalog.all) { preset in
                    Button {
                        model.applyNarrow(preset: preset)
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(preset.title)
                                    .font(.system(.headline, design: .rounded))
                                    .foregroundStyle(SMTheme.ink)
                                Spacer()
                                if preset.id == suggestedID {
                                    Text("Suggested")
                                        .font(SMTheme.captionFont.weight(.semibold))
                                        .foregroundStyle(SMTheme.accent)
                                }
                            }
                            Text(preset.summary)
                                .font(SMTheme.captionFont)
                                .foregroundStyle(SMTheme.muted)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, minHeight: 110, alignment: .topLeading)
                        .background(preset.id == suggestedID ? SMTheme.accentSoft : SMTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(
                                    preset.id == suggestedID ? SMTheme.accent : SMTheme.border,
                                    lineWidth: preset.id == suggestedID ? 2 : 1
                                )
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Apply Narrow preset")
                }
            }

            Spacer()
        }
        .padding(28)
    }
}
