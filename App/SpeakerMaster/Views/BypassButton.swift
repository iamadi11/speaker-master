import SwiftUI

struct BypassButton: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        Button {
            model.setBypass(!model.bypassed)
        } label: {
            Text(model.bypassed ? "Bypassed" : "Bypass")
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .frame(minHeight: 36)
        }
        .buttonStyle(.plain)
        .foregroundStyle(model.bypassed ? Color.white : SMTheme.ink)
        .background(model.bypassed ? SMTheme.bypass : SMTheme.border.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(SMTheme.bypass.opacity(model.bypassed ? 0 : 0.5), lineWidth: 1)
        )
        .accessibilityLabel(model.bypassed ? "Bypass on, hearing before" : "Bypass off")
        .accessibilityHint("Toggle to compare processed and original sound")
        .help("Hold mental A/B: on = before EQ")
    }
}
