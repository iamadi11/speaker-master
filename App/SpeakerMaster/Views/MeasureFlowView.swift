import AppKit
import AVFoundation
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

                    if !model.mic.isAuthorizedForCapture {
                        permissionBanner
                    }

                    micPickerSection

                    HStack {
                        Button("Refresh list") {
                            Task {
                                _ = await model.mic.requestPermission()
                                model.mic.refreshDevices()
                            }
                        }
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
                    .disabled(
                        running
                            || model.mic.devices.isEmpty
                            || model.mic.selectedDeviceID == nil
                            || !model.mic.isAuthorizedForCapture
                    )
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

    private var permissionBanner: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Microphone access is off")
                .font(SMTheme.captionFont.weight(.semibold))
                .foregroundStyle(SMTheme.danger)
            Text("HAL can list inputs, but Measure cannot record until Speaker Master is allowed under Privacy & Security → Microphone.")
                .font(SMTheme.captionFont)
                .foregroundStyle(SMTheme.muted)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 10) {
                Button("Open Microphone settings") {
                    openMicrophoneSettings()
                }
                .buttonStyle(.borderedProminent)
                .tint(SMTheme.accent)
                Button("Ask again") {
                    Task { _ = await model.mic.requestPermission() }
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SMTheme.danger.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Microphone access is off. Open Microphone settings.")
    }

    @ViewBuilder
    private var micPickerSection: some View {
        let devices = model.mic.devices
        let permission = model.mic.permission

        if devices.isEmpty {
            emptyMicState(permission: permission)
        } else {
            // Explicit radio list — macOS Menu Picker with a mismatched tag rendered blank
            // (looked like “no mics” even when HAL had devices + TCC was granted).
            VStack(alignment: .leading, spacing: 6) {
                ForEach(devices) { device in
                    Button {
                        model.mic.selectedDeviceID = device.id
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: device.id == model.mic.selectedDeviceID
                                  ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(
                                    device.id == model.mic.selectedDeviceID
                                    ? SMTheme.accent : SMTheme.muted
                                )
                                .accessibilityHidden(true)
                            Text(device.name)
                                .font(SMTheme.bodyFont)
                                .foregroundStyle(SMTheme.ink)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.vertical, 6)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .frame(minHeight: 44)
                    .accessibilityLabel(device.name)
                    .accessibilityAddTraits(device.id == model.mic.selectedDeviceID ? .isSelected : [])
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Microphone input")
        }
    }

    @ViewBuilder
    private func emptyMicState(permission: AVAuthorizationStatus) -> some View {
        switch permission {
        case .denied, .restricted:
            VStack(alignment: .leading, spacing: 8) {
                Text("Grant Microphone in System Settings")
                    .foregroundStyle(SMTheme.danger)
                    .accessibilityLabel("Grant Microphone in System Settings")
                Text("Speaker Master is listed under Privacy & Security → Microphone. Turn it on, then Refresh.")
                    .font(SMTheme.captionFont)
                    .foregroundStyle(SMTheme.muted)
                Button("Open Microphone settings") {
                    openMicrophoneSettings()
                }
                .buttonStyle(.bordered)
            }
        case .notDetermined:
            Text("Allow Microphone when prompted, then this list fills with Built-in and other inputs.")
                .foregroundStyle(SMTheme.muted)
        default:
            Text("No input devices found. Plug in a mic or enable Built-in, then Refresh — or use Narrow.")
                .foregroundStyle(SMTheme.danger)
                .accessibilityLabel("No microphones found")
        }
    }

    private func openMicrophoneSettings() {
        let candidates = [
            "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone",
            "x-apple.systempreferences:com.apple.Settings.PrivacySecurity.extension?Privacy_Microphone",
        ]
        for raw in candidates {
            if let url = URL(string: raw), NSWorkspace.shared.open(url) {
                return
            }
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
