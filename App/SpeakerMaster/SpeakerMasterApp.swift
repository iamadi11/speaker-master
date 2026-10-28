import AppKit
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

    /// Crash-regression smokes. Exit 0 only if process survives the full sequence.
    /// - `--smoke-audition` — Play audition ~3s
    /// - `--smoke-measure` — Measure record→analyze path (needs mic TCC)
    /// - `--smoke-full` — audition + measure + idle hold (≥30s wall)
    @MainActor
    private func runSmokeIfRequested() {
        let args = CommandLine.arguments
        let wantAudition = args.contains("--smoke-audition") || args.contains("--smoke-full")
        let wantMeasure = args.contains("--smoke-measure") || args.contains("--smoke-full")
        let wantFull = args.contains("--smoke-full")
        guard wantAudition || wantMeasure else { return }

        Task { @MainActor in
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
                model.autoScreen = .measure
                await model.runMeasure()
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
            NSApplication.shared.terminate(nil)
        }
    }
}
