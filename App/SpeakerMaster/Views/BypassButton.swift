import SwiftUI

struct BypassButton: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Group {
            if reduceMotion {
                // Paper §6: reduced-motion / a11y → toggle Before/After instead of hold.
                Button {
                    model.setBypass(!model.bypassed)
                } label: {
                    label
                }
                .buttonStyle(.plain)
                .accessibilityHint("Toggle to compare processed and original sound")
            } else {
                label
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in
                                if !model.bypassed {
                                    model.setBypass(true)
                                }
                            }
                            .onEnded { _ in
                                if model.bypassed {
                                    model.setBypass(false)
                                }
                            }
                    )
                    .accessibilityHint("Hold to hear before EQ; release to hear processed")
                    .help("Hold to A/B: pressed = before EQ")
            }
        }
        .accessibilityLabel(model.bypassed ? "Bypass on, hearing before" : "Bypass off")
        .accessibilityAddTraits(.isButton)
    }

    private var label: some View {
        Text(model.bypassed ? "Bypassed" : "Bypass")
            .font(.system(.subheadline, design: .rounded).weight(.semibold))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .frame(minHeight: 36)
            .foregroundStyle(model.bypassed ? Color.white : SMTheme.ink)
            .background(model.bypassed ? SMTheme.bypass : SMTheme.border.opacity(0.55))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(SMTheme.bypass.opacity(model.bypassed ? 0 : 0.5), lineWidth: 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}
