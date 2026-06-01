import AppKit
import SwiftUI

struct StatusMenu: View {
    @ObservedObject var model: AppViewModel

    var body: some View {
        Button("Open Settings") {
            SettingsWindowCoordinator.shared.show(model: model)
        }
        Divider()
        Toggle("Open at Login", isOn: $model.launchAtLogin)
        Toggle("Auto-pause Behind Apps", isOn: $model.autoPauseWhenCovered)
        Button("Open Login Items Settings") {
            model.openLoginItemsSettings()
        }
        Button("Stop Playback") {
            model.stopPlayback()
        }
        Divider()
        Button("Quit") {
            NSApp.terminate(nil)
        }
    }
}
