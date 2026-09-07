import SwiftUI

@main
struct MikuApp: App {
    @State private var controller: MikuController

    init() {
        let state = AppState()
        let controller = MikuController(state: state)
        _controller = State(initialValue: controller)
        controller.start()
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarView().environment(controller)
        } label: {
            Image(systemName: controller.state.status.symbol)
        }
        .menuBarExtraStyle(.window)

        Window("Ajustes de Miku", id: "settings") {
            SettingsView().environment(controller)
        }
        .defaultSize(width: 720, height: 520)
        .windowResizability(.contentMinSize)
    }
}
