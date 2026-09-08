import SwiftUI

@main
struct MikuApp: App {
    @State private var controller: MikuController

    init() {
        let state = AppState()
        let controller = MikuController(state: state)
        _controller = State(initialValue: controller)
        MikuFonts.register()
        controller.start()
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarView().environment(controller)
        } label: {
            MenuBarLabel().environment(controller)
        }
        .menuBarExtraStyle(.window)

        Window("Miku", id: "console") {
            ConsoleWindow().environment(controller)
        }
        .defaultSize(width: 1240, height: 800)
        .windowToolbarStyle(.unifiedCompact(showsTitle: false))

        Window("Ajustes de Miku", id: "settings") {
            SettingsView().environment(controller)
        }
        .defaultSize(width: 720, height: 520)
        .windowResizability(.contentMinSize)
    }
}


/// The status item's artwork.
///
/// Also the one view guaranteed to appear the moment the app launches, which is why the
/// `MIKU_OPEN_CONSOLE` development hook hangs here: the Console is a `Window` scene, and
/// opening one needs a live view context.
private struct MenuBarLabel: View {
    @Environment(MikuController.self) private var miku
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Image(nsImage: MenuBarIcon.image(for: miku.state.status))
            .onAppear {
                guard ConsoleWindow.abrirAlArrancar else { return }
                openWindow(id: "console")
                NSApp.activate(ignoringOtherApps: true)
            }
    }
}
