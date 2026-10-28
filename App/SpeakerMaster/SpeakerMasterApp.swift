import AppKit
import SpeakerMaster
import SwiftUI

@main
struct SpeakerMasterApp: App {
    @StateObject private var model = AppModel()

    var body: some Scene {
        WindowGroup("Speaker Master") {
            RootView()
                .environmentObject(model)
                .frame(minWidth: 720, minHeight: 520)
                .onAppear {
                    // Demo / screenshot helper — not a product preference.
                    if CommandLine.arguments.contains("--open-measure") {
                        model.autoScreen = .measure
                    }
                    if CommandLine.arguments.contains("--dump-mics") {
                        dumpMicsAndExit()
                        return
                    }
                    if CommandLine.arguments.contains("--qa-nonmic") {
                        runNonMicQAAndExit()
                        return
                    }
                    runSmokeIfRequested()
                }
        }
        .defaultSize(width: 840, height: 600)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }

        MenuBarExtra("Speaker Master", systemImage: "slider.horizontal.3") {
            MenuBarView()
                .environmentObject(model)
        }
    }

    /// Print HAL input catalog + selection, then quit (QA / empty-picker regression).
    @MainActor
    private func dumpMicsAndExit() {
        Task { @MainActor in
            _ = await model.mic.requestPermission()
            model.mic.refreshDevices()
            let status = model.mic.permission.rawValue
            print("mic_permission_raw=\(status)")
            print("mic_count=\(model.mic.devices.count)")
            for device in model.mic.devices {
                let mark = device.id == model.mic.selectedDeviceID ? "*" : " "
                print("mic\(mark) \(device.name) uid=\(device.id)")
            }
            if let selected = model.mic.selectedDeviceID {
                print("mic_selected=\(selected)")
            } else {
                print("mic_selected=")
            }
            let ok = !model.mic.devices.isEmpty && model.mic.selectedDeviceID != nil
            exit(ok ? 0 : 1)
        }
    }

    /// Narrow / Custom / Bypass / profile persistence — no Microphone TCC required.
    @MainActor
    private func runNonMicQAAndExit() {
        Task { @MainActor in
            var failed = false
            func check(_ name: String, _ ok: Bool, _ detail: String = "") {
                print("qa_\(name)=\(ok ? "pass" : "fail")\(detail.isEmpty ? "" : " \(detail)")")
                if !ok { failed = true }
            }

            model.output.refresh()
            let outName = model.outputIdentity.displayName
            check("launch", true, "output=\(outName)")

            // Narrow: apply suggested preset, persist, restore
            let suggestedID = NarrowCatalog.suggestedPresetID(deviceName: outName)
            guard let preset = NarrowCatalog.preset(id: suggestedID) else {
                check("narrow_apply", false, "no_preset")
                exit(1)
            }
            model.applyNarrow(preset: preset)
            check(
                "narrow_apply",
                model.lastSource == .narrow && model.lastNarrowPresetID == preset.id,
                "preset=\(preset.id)"
            )
            check("narrow_home", model.autoScreen == .home)
            let stored = model.profiles.profile(forOutputUID: model.outputIdentity.outputUID)
            check("narrow_persist", stored?.source == .narrow && stored?.narrowPresetID == preset.id)

            // Retry clears persistence and returns to path picker
            model.retry()
            check("narrow_retry", model.autoScreen == .pathPicker && model.lastSource == nil)
            check(
                "narrow_retry_cleared",
                model.profiles.profile(forOutputUID: model.outputIdentity.outputUID) == nil
            )

            // Re-apply so Custom / audition run against a live curve
            model.applyNarrow(preset: preset)

            // Custom: named intent → undo → band edit → reset flat → reset to Auto
            let warmer = CustomIntentCatalog.intent(id: "warmer")!
            model.applyCustomIntent(warmer)
            check(
                "custom_intent",
                model.matchedCustomIntentID == "warmer" && model.customCanUndo,
                "id=warmer"
            )
            model.undoCustom()
            check(
                "custom_undo",
                model.lastNarrowPresetID == preset.id && model.activeCurve == preset.curve.sanitized()
            )
            var custom = EQCurve.flat
            if var band = custom.bands.first {
                band.gainDb = 3
                custom.bands[0] = band
            }
            model.updateCustom(custom)
            check("custom_edit", model.lastSource == .custom && model.activeCurve.bands[0].gainDb == 3)
            model.resetCustom()
            check("custom_reset", abs(model.activeCurve.bands[0].gainDb) < 0.01)
            model.updateCustom(custom)
            model.resetCustomToAuto()
            check(
                "custom_reset_auto",
                model.activeCurve == preset.curve.sanitized() && !model.customCanUndo
            )

            // Bypass A/B + audition noise
            model.setBypass(true)
            check("bypass_on", model.bypassed)
            model.toggleAudition()
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            check("audition_play", model.player.isPlaying)
            model.setBypass(false)
            check("bypass_off", !model.bypassed)
            model.toggleAudition()
            check("audition_stop", !model.player.isPlaying)

            // Output label present
            check("output_label", !model.outputIdentity.displayName.isEmpty)

            // System host status is one of the known honest states
            switch model.systemHost.status {
            case .inactive, .starting, .readyPendingPermission, .activeInAppOnly, .activeSystemWide, .failed:
                check("system_host_status", true, "\(model.systemHost.status)")
            }

            exit(failed ? 1 : 0)
        }
    }

    /// Crash-regression smokes. Exit 0 only if process survives the full sequence
    /// **and** Measure sees a non-empty mic list when `--smoke-measure` / `--smoke-full`.
    /// - `--smoke-audition` — Play audition ~3s
    /// - `--smoke-measure` — Measure record→analyze path (needs mic TCC / HAL inputs)
    /// - `--smoke-full` — audition + measure + idle hold (≥30s wall)
    @MainActor
    private func runSmokeIfRequested() {
        let args = CommandLine.arguments
        let wantAudition = args.contains("--smoke-audition") || args.contains("--smoke-full")
        let wantMeasure = args.contains("--smoke-measure") || args.contains("--smoke-full")
        let wantFull = args.contains("--smoke-full")
        guard wantAudition || wantMeasure else { return }

        Task { @MainActor in
            var failed = false
            let started = Date()
            if wantAudition {
                model.toggleAudition()
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                if model.player.isPlaying {
                    model.toggleAudition()
                }
                try? await Task.sleep(nanoseconds: 500_000_000)
            }
            if wantMeasure {
                _ = await model.mic.requestPermission()
                model.mic.refreshDevices()
                print("smoke_mic_count=\(model.mic.devices.count)")
                if model.mic.devices.isEmpty || model.mic.selectedDeviceID == nil {
                    print("smoke_fail=empty_mic_list")
                    failed = true
                } else {
                    model.autoScreen = .measure
                    await model.runMeasure()
                    print("smoke_measure_status=\(model.statusMessage)")
                    if let note = model.measureNote {
                        print("smoke_measure_note=\(note)")
                    }
                    // Hard fail on empty mic / TCC / engine failure. Bad acoustic takes still
                    // exit 0 (room-dependent) but permission and binding must work.
                    if model.statusMessage == "No mic selected"
                        || model.statusMessage.hasPrefix("Measure failed")
                        || model.statusMessage.hasPrefix("Mic permission needed")
                    {
                        print("smoke_fail=measure_path")
                        failed = true
                    }
                }
                try? await Task.sleep(nanoseconds: 500_000_000)
            }
            if wantFull {
                // Keep process alive so late audio-thread traps still surface.
                let elapsed = Date().timeIntervalSince(started)
                let remain = max(0, 32 - elapsed)
                if remain > 0 {
                    try? await Task.sleep(nanoseconds: UInt64(remain * 1_000_000_000))
                }
            }
            if failed {
                exit(1)
            }
            NSApplication.shared.terminate(nil)
        }
    }
}
