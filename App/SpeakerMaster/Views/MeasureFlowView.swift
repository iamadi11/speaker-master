import SpeakerMaster
import SwiftUI

struct MeasureFlowView: View {
    @EnvironmentObject private var model: AppModel
    @State private var running = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Button {
                    model.autoScreen = .pathPicker
                } label: {
                    Label("Back", systemImage: "chevron.left")
                }
                .buttonStyle(.borderless)
                .accessibilityHint("Return to Measure or Narrow")

                Text("Measure")
                    .font(SMTheme.titleFont)
                    .foregroundStyle(SMTheme.ink)
                Text("Select a mic, place it toward the speaker, then play a short sweep. We record → analyze → apply the best safe Auto EQ for this output.")
                    .font(SMTheme.bodyFont)
                    .foregroundStyle(SMTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)

                stepRow

                VStack(alignment: .leading, spacing: 10) {
                    Text("1 · Microphone")
                        .font(SMTheme.captionFont.weight(.semibold))
                        .foregroundStyle(SMTheme.muted)
                    if model.mic.devices.isEmpty {
                        Text("No mics found. Grant Microphone access in System Settings, then Refresh — or use Narrow.")
                            .foregroundStyle(SMTheme.danger)
                            .accessibilityLabel("No microphones found")
                    } else {
                        Picker("Input", selection: Binding(
                            get: { model.mic.selectedDeviceID ?? "" },
                            set: { model.mic.selectedDeviceID = $0 }
                        )) {
                            ForEach(model.mic.devices) { device in
                                Text(device.name).tag(device.id)
                            }
                        }
                        .pickerStyle(.menu)
                        .accessibilityLabel("Microphone input")
                    }
                    HStack {
                        Button("Refresh list") { model.mic.refreshDevices() }
                            .buttonStyle(.bordered)
                            .accessibilityHint("Rescan available microphones")
                        Text("Built-in OK for a first pass · last choice remembered")
                            .font(SMTheme.captionFont)
                            .foregroundStyle(SMTheme.muted)
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(SMTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(SMTheme.border, lineWidth: 1)
                )

                Label(
                    "2 · Place mic toward the speaker, quiet room, comfortable volume — we never force max.",
                    systemImage: "arrow.up.forward.circle"
                )
                .font(SMTheme.bodyFont)
                .foregroundStyle(SMTheme.ink)
                .fixedSize(horizontal: false, vertical: true)

                if let note = model.measureNote {
                    Text(note)
                        .font(SMTheme.captionFont)
                        .foregroundStyle(
                            model.statusMessage.hasPrefix("Bad") || model.statusMessage.hasPrefix("Measure failed")
                                ? SMTheme.danger
                                : SMTheme.muted
                        )
                        .accessibilityLabel("Measure result: \(note)")
                }

                HStack(spacing: 12) {
                    Button {
                        Task {
                            running = true
                            await model.runMeasure()
                            running = false
                        }
                    } label: {
                        HStack(spacing: 8) {
                            if running || model.mic.isRecording {
                                ProgressView()
                                    .controlSize(.small)
                                Text(model.mic.isRecording ? "Listening…" : "Analyzing…")
                            } else {
                                Image(systemName: "waveform")
                                Text("Play & measure")
                            }
                        }
                        .frame(minWidth: 160)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(SMTheme.accent)
                    .disabled(running || model.mic.devices.isEmpty)
                    .frame(minHeight: 44)
                    .accessibilityHint("Plays a short sweep, records the selected mic, then applies safe Auto EQ")

                    Button("Use Narrow instead") {
                        model.autoScreen = .narrow
                    }
                    .buttonStyle(.bordered)
                    .frame(minHeight: 44)
                }

                Text("Captures stay in memory and are discarded after analysis. System EQ is bypassed during the sweep so the mic hears the speaker, not a prior curve.")
                    .font(SMTheme.captionFont)
                    .foregroundStyle(SMTheme.muted)

                SystemHostStatusView()
            }
            .padding(28)
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: running)
        .task {
            _ = await model.mic.requestPermission()
            model.mic.refreshDevices()
        }
    }

    private var stepRow: some View {
        HStack(spacing: 8) {
            stepChip("Mic", active: true)
            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(SMTheme.muted)
                .accessibilityHidden(true)
            stepChip("Place", active: true)
            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(SMTheme.muted)
                .accessibilityHidden(true)
            stepChip(running ? "Listening" : "Apply", active: running)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Measure steps: microphone, place, then apply")
    }

    private func stepChip(_ title: String, active: Bool) -> some View {
        Text(title)
            .font(SMTheme.captionFont.weight(.semibold))
            .foregroundStyle(active ? SMTheme.accent : SMTheme.muted)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(active ? SMTheme.accentSoft : SMTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}
