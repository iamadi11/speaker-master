import AppKit
import AVFoundation
import SpeakerMaster
import SwiftUI

struct MeasureFlowView: View {
    @EnvironmentObject private var model: AppModel
    @State private var running = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var micReady: Bool {
        model.mic.isAuthorizedForCapture
            && model.mic.selectedDeviceID != nil
            && !model.mic.devices.isEmpty
    }

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
                        .smBorderedButton()
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
                        .strokeBorder(micReady ? SMTheme.accent.opacity(0.45) : SMTheme.border, lineWidth: 1)
                )

                Label(
                    "2 · Place mic toward the speaker, quiet room, comfortable volume — we never force max.",
                    systemImage: "arrow.up.forward.circle"
                )
                .font(SMTheme.bodyFont)
                .foregroundStyle(SMTheme.ink)
                .fixedSize(horizontal: false, vertical: true)

                if model.measurePhase == .refused || model.measurePhase == .applied,
                   let note = model.measureNote
                {
                    resultCard(note: note)
                } else if let note = model.measureNote {
                    Text(note)
                        .font(SMTheme.captionFont)
                        .foregroundStyle(SMTheme.muted)
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
                            if running || model.measurePhase == .recording || model.measurePhase == .analyzing {
                                ProgressView()
                                    .controlSize(.small)
                                Text(phaseButtonLabel)
                            } else {
                                Image(systemName: "waveform")
                                Text("Play & measure")
                            }
                        }
                        .frame(minWidth: 160)
                    }
                    .smProminentButton()
                    .disabled(
                        running
                            || model.mic.devices.isEmpty
                            || model.mic.selectedDeviceID == nil
                            || !model.mic.isAuthorizedForCapture
                    )
                    .frame(minHeight: 44)
                    .accessibilityHint("Plays a short sweep, records the selected mic, then applies safe Auto EQ")
                    .accessibilityValue(phaseButtonLabel)

                    Button("Use Narrow instead") {
                        model.autoScreen = .narrow
                    }
                    .smBorderedButton()
                    .frame(minHeight: 44)
                }

                Text("Captures stay in memory and are discarded after analysis. System EQ is bypassed during the sweep so the mic hears the speaker, not a prior curve. Analyzer is a first pass — not a lab calibration.")
                    .font(SMTheme.captionFont)
                    .foregroundStyle(SMTheme.muted)

                SystemHostStatusView()
            }
            .padding(28)
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: model.measurePhase)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: running)
        .task {
            _ = await model.mic.requestPermission()
            model.mic.refreshDevices()
        }
    }

    private var phaseButtonLabel: String {
        switch model.measurePhase {
        case .recording: return "Listening…"
        case .analyzing: return "Analyzing…"
        default:
            if model.mic.isRecording { return "Listening…" }
            return running ? "Working…" : "Play & measure"
        }
    }

    private func resultCard(note: String) -> some View {
        let refused = model.measurePhase == .refused
        return VStack(alignment: .leading, spacing: SMTheme.spaceXS) {
            HStack(spacing: SMTheme.spaceSM) {
                Text(refused ? "Nothing applied" : qualityTitle)
                    .font(SMTheme.captionFont.weight(.semibold))
                    .foregroundStyle(refused ? SMTheme.danger : SMTheme.accent)
                Spacer(minLength: 0)
                if !refused, let quality = model.lastMeasureQuality {
                    Text(quality == .good ? "Good take" : "Cautious")
                        .font(SMTheme.captionFont.weight(.semibold))
                        .foregroundStyle(SMTheme.ink)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(SMTheme.accentSoft)
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                }
            }
            Text(note)
                .font(SMTheme.captionFont)
                .foregroundStyle(SMTheme.muted)
                .fixedSize(horizontal: false, vertical: true)
            if refused {
                Text("Prior good profile kept if one existed. Retry after fixing level / noise, or use Narrow.")
                    .font(SMTheme.captionFont)
                    .foregroundStyle(SMTheme.muted)
            }
        }
        .padding(SMTheme.spaceSM)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(refused ? SMTheme.danger.opacity(0.06) : SMTheme.accentSoft)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(refused ? SMTheme.danger.opacity(0.35) : SMTheme.accent.opacity(0.35), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(refused ? "Measure refused: \(note)" : "Measure result: \(note)")
    }

    private var qualityTitle: String {
        switch model.lastMeasureQuality {
        case .good: return "Correction applied"
        case .inconclusive: return "Cautious correction applied"
        case .badTake, .none: return "Result"
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
                .smProminentButton()
                Button("Ask again") {
                    Task { _ = await model.mic.requestPermission() }
                }
                .smBorderedButton()
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
            VStack(alignment: .leading, spacing: SMTheme.spaceSM) {
                Label("Microphone permission needed", systemImage: "mic.slash.fill")
                    .font(SMTheme.captionFont.weight(.semibold))
                    .foregroundStyle(SMTheme.danger)
                    .accessibilityLabel("Grant Microphone in System Settings")
                Text("Measure cannot list a usable input until Speaker Master is allowed under Privacy & Security → Microphone. Turn it on, return here, then Refresh — or use Narrow without a mic.")
                    .font(SMTheme.captionFont)
                    .foregroundStyle(SMTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: SMTheme.spaceSM) {
                    Button("Open Microphone settings") {
                        openMicrophoneSettings()
                    }
                    .smProminentButton()
                    .frame(minHeight: 36)
                    Button("Use Narrow instead") {
                        model.autoScreen = .narrow
                    }
                    .smBorderedButton()
                    .frame(minHeight: 36)
                }
            }
            .padding(SMTheme.spaceSM)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(SMTheme.danger.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        case .notDetermined:
            VStack(alignment: .leading, spacing: SMTheme.spaceXS) {
                Text("Waiting for Microphone access")
                    .font(SMTheme.captionFont.weight(.semibold))
                    .foregroundStyle(SMTheme.ink)
                Text("Allow Microphone when prompted. The list then fills with Built-in and other inputs.")
                    .font(SMTheme.captionFont)
                    .foregroundStyle(SMTheme.muted)
            }
        default:
            VStack(alignment: .leading, spacing: SMTheme.spaceSM) {
                Label("No microphones found", systemImage: "mic.slash")
                    .font(SMTheme.captionFont.weight(.semibold))
                    .foregroundStyle(SMTheme.danger)
                Text("Plug in a mic or enable Built-in, then Refresh. Prefer Narrow if you only need a fast preset.")
                    .font(SMTheme.captionFont)
                    .foregroundStyle(SMTheme.muted)
                Button("Use Narrow instead") {
                    model.autoScreen = .narrow
                }
                .smBorderedButton()
                .frame(minHeight: 36)
            }
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
        let micActive = micReady || model.measurePhase != .idle
        let placeActive = micReady
        let applyActive = model.measurePhase == .recording
            || model.measurePhase == .analyzing
            || model.measurePhase == .applied
        let applyTitle: String = {
            switch model.measurePhase {
            case .recording: return "Listening"
            case .analyzing: return "Analyze"
            case .applied: return "Applied"
            case .refused: return "Retry"
            case .idle: return "Apply"
            }
        }()

        return HStack(spacing: 8) {
            stepChip("1 Mic", done: micReady, active: micActive)
            chevron
            stepChip("2 Place", done: placeActive && applyActive, active: placeActive)
            chevron
            stepChip("3 \(applyTitle)", done: model.measurePhase == .applied, active: applyActive || model.measurePhase == .refused)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "Measure steps: microphone\(micReady ? " ready" : ""), place, then \(applyTitle.lowercased())"
        )
    }

    private var chevron: some View {
        Image(systemName: "chevron.right")
            .font(.caption2)
            .foregroundStyle(SMTheme.muted)
            .accessibilityHidden(true)
    }

    private func stepChip(_ title: String, done: Bool, active: Bool) -> some View {
        HStack(spacing: 4) {
            if done {
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption2)
                    .foregroundStyle(SMTheme.accent)
                    .accessibilityHidden(true)
            }
            Text(title)
                .font(SMTheme.captionFont.weight(.semibold))
                .foregroundStyle(active || done ? SMTheme.accent : SMTheme.muted)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(active || done ? SMTheme.accentSoft : SMTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(active || done ? SMTheme.accent.opacity(0.4) : SMTheme.border, lineWidth: 1)
        )
    }
}
