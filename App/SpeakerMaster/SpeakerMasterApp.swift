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
                    // Crash-regression smoke: start in-app audition on the realtime
                    // audio thread, hold briefly, stop. Exit 0 if still alive.
                    if CommandLine.arguments.contains("--smoke-audition") {
                        Task { @MainActor in
                            model.toggleAudition()
                            try? await Task.sleep(nanoseconds: 2_500_000_000)
                            if model.player.isPlaying {
                                model.toggleAudition()
                            }
                            try? await Task.sleep(nanoseconds: 300_000_000)
                            NSApplication.shared.terminate(nil)
                        }
                    }
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
}
