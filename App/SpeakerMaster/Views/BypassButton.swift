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
                    .help("Hold to A/B: pressed = before EQ (⌘B toggles)")
            }
        }
        .accessibilityLabel(model.bypassed ? "Bypass on, hearing before" : "Bypass off")
        .accessibilityAddTraits(.isButton)
    }

    private var label: some View {
        Text(model.bypassed ? "Bypassed" : "Bypass")
            .font(.system(.subheadline, design: .default).weight(.semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .frame(minHeight: SMTheme.minTouch)
            .foregroundStyle(model.bypassed ? Color.white : SMTheme.ink)
            .background(
                model.bypassed ? SMTheme.bypass : Color(nsColor: .controlBackgroundColor),
                in: RoundedRectangle(cornerRadius: SMTheme.radiusControl, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: SMTheme.radiusControl, style: .continuous)
                    .strokeBorder(SMTheme.bypass.opacity(model.bypassed ? 0 : 0.45), lineWidth: 0.5)
            )
            .contentShape(RoundedRectangle(cornerRadius: SMTheme.radiusControl, style: .continuous))
    }
}
