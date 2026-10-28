import SpeakerMaster
import SwiftUI

struct MeasureFlowView: View {
    @EnvironmentObject private var model: AppModel
    @State private var running = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Button {
                model.autoScreen = .pathPicker
            } label: {
                Label("Back", systemImage: "chevron.left")
            }
            .buttonStyle(.borderless)

            Text("Measure")
                .font(SMTheme.titleFont)
                .foregroundStyle(SMTheme.ink)
            Text("Select a mic, keep the room quiet, then play a short sweep. We record → analyze → apply the best safe Auto EQ.")
                .font(SMTheme.bodyFont)
                .foregroundStyle(SMTheme.muted)

            Form {
                Section("Microphone") {
                    if model.mic.devices.isEmpty {
                        Text("No mics found. Grant Microphone access or use Narrow.")
                            .foregroundStyle(SMTheme.danger)
                    } else {
                        Picker("Input", selection: Binding(
                            get: { model.mic.selectedDeviceID ?? "" },
                            set: { model.mic.selectedDeviceID = $0 }
                        )) {
                            ForEach(model.mic.devices) { device in
                                Text(device.name).tag(device.id)
                            }
                        }
                    }
                    Button("Refresh list") { model.mic.refreshDevices() }
                }
            }
            .formStyle(.grouped)
            .frame(maxHeight: 180)

            if let note = model.measureNote {
                Text(note)
                    .font(SMTheme.captionFont)
                    .foregroundStyle(SMTheme.muted)
            }

            HStack(spacing: 12) {
                Button {
                    Task {
                        running = true
                        await model.runMeasure()
                        running = false
                    }
                } label: {
                    if running || model.mic.isRecording {
                        ProgressView()
                            .controlSize(.small)
                            .padding(.trailing, 6)
                        Text("Listening…")
                    } else {
                        Text("Play & measure")
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(SMTheme.accent)
                .disabled(running || model.mic.devices.isEmpty)
                .frame(minHeight: 44)

                Button("Use Narrow instead") {
                    model.autoScreen = .narrow
                }
                .buttonStyle(.bordered)
            }

            Text("Captures are temporary and deleted after analysis. Comfortable volume only — we never force max.")
                .font(SMTheme.captionFont)
                .foregroundStyle(SMTheme.muted)

            Spacer()
        }
        .padding(28)
        .task {
            _ = await model.mic.requestPermission()
            model.mic.refreshDevices()
        }
    }
}
