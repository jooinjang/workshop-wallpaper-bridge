import SwiftUI

@main
struct WorkshopWallpaperBridgeApplication: App {
    @StateObject private var model = AppViewModel()

    var body: some Scene {
        WindowGroup("Workshop Wallpaper Bridge") {
            ContentView(model: model)
                .frame(minWidth: 980, minHeight: 640)
        }
        .commands {
            CommandMenu("Wallpaper") {
                Button("Stop Playback") {
                    model.stopPlayback()
                }
                .keyboardShortcut(".", modifiers: [.command, .shift])
            }
        }
    }
}
