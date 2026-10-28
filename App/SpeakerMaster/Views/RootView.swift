import SwiftUI

/// Sparse chrome: system toolbar for Mode / Bypass / output; thin status strip (ux-journey-pm).
struct RootView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 0) {
            statusStrip
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
        .background(SMTheme.background)
        .tint(SMTheme.accent)
        .toolbar {
            ToolbarItem(placement: .navigation) {
                outputChip
            }
            ToolbarItem(placement: .principal) {
                Picker("Mode", selection: $model.tab) {
                    ForEach(AppModel.Tab.allCases) { tab in
                        Text(tab.title).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 168)
                .accessibilityLabel("Mode")
                .help("Auto or Custom (⌘1 / ⌘2)")
            }
            ToolbarItem(placement: .primaryAction) {
                BypassButton()
            }
        }
        .toolbarBackground(.ultraThinMaterial, for: .windowToolbar)
        .toolbarBackground(.visible, for: .windowToolbar)
        .navigationTitle("")
        .onChange(of: model.output.identity.outputUID) { _, _ in
            model.onOutputChanged()
        }
        .onChange(of: model.statusMessage) { _, newValue in
            AccessibilityNotification.Announcement(newValue).post()
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.18), value: model.tab)
    }

    private var statusStrip: some View {
        Text(model.statusMessage)
            .font(SMTheme.captionFont)
            .foregroundStyle(SMTheme.muted)
            .lineLimit(2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, SMTheme.spaceXL)
            .padding(.vertical, 7)
            .background(.bar)
            .overlay(alignment: .bottom) { Divider().opacity(0.5) }
            .accessibilityAddTraits(.updatesFrequently)
            .accessibilityLabel("Status")
            .accessibilityValue(model.statusMessage)
    }

    private var outputChip: some View {
        HStack(spacing: 5) {
            Image(systemName: "hifispeaker.fill")
                .foregroundStyle(SMTheme.accent)
                .imageScale(.small)
            Text(model.outputIdentity.displayName)
                .font(SMTheme.captionFont.weight(.medium))
                .foregroundStyle(SMTheme.ink)
                .lineLimit(1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Output \(model.outputIdentity.displayName)")
        .help("Current system output — change in System Settings → Sound if needed")
    }
}
