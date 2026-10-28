import SwiftUI

struct RootView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    SMTheme.background,
                    Color(red: 0.93, green: 0.95, blue: 0.97),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                chrome
                Divider().overlay(SMTheme.border)
                Group {
                    switch model.tab {
                    case .auto:
                        AutoContainerView()
                    case .custom:
                        CustomEQView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .tint(SMTheme.accent)
        .onChange(of: model.output.identity.outputUID) { _, _ in
            model.onOutputChanged()
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: model.tab)
    }

    private var chrome: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Speaker Master")
                    .font(SMTheme.headlineFont)
                    .foregroundStyle(SMTheme.ink)
                Text(model.statusMessage)
                    .font(SMTheme.captionFont)
                    .foregroundStyle(SMTheme.muted)
                    .lineLimit(2)
                    .accessibilityAddTraits(.updatesFrequently)
                    .accessibilityLabel("Status")
                    .accessibilityValue(model.statusMessage)
            }
            Spacer()
            outputChip
            BypassButton()
            Picker("Mode", selection: $model.tab) {
                ForEach(AppModel.Tab.allCases) { tab in
                    Text(tab.title).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 180)
            .accessibilityLabel("Mode")
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(SMTheme.surface.opacity(0.92))
        .onChange(of: model.statusMessage) { _, newValue in
            // Contextual live status (ui-ux-pro-max): announce meaningful phrases, not bare chips.
            AccessibilityNotification.Announcement(newValue).post()
        }
    }

    private var outputChip: some View {
        HStack(spacing: 6) {
            Image(systemName: "hifispeaker.fill")
                .foregroundStyle(SMTheme.accent)
            Text(model.outputIdentity.displayName)
                .font(SMTheme.captionFont.weight(.medium))
                .foregroundStyle(SMTheme.ink)
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(SMTheme.accentSoft)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Output \(model.outputIdentity.displayName)")
        .help("Current system output. Change it in System Settings → Sound if needed.")
    }
}
