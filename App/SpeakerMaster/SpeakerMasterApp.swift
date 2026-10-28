import SwiftUI

@main
struct SpeakerMasterApp: App {
    @StateObject private var model = AppModel()

    var body: some Scene {
        WindowGroup("Speaker Master") {
            RootView()
                .environmentObject(model)
                .frame(minWidth: 720, minHeight: 520)
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
