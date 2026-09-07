import SwiftUI

/// The popover shown when clicking the menu bar icon: status plus the few controls
/// that need to be one click away.
struct MenuBarView: View {
    @Environment(MikuController.self) private var miku
    @Environment(\.openWindow) private var openWindow
    @State private var draft = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: miku.state.status.symbol)
                Text(miku.state.status.label).font(.headline)
            }

            if !miku.state.lastReply.isEmpty {
                Text(miku.state.lastReply)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Divider()

            Toggle("Escuchar", isOn: Binding(
                get: { miku.state.listeningEnabled },
                set: { miku.setListening($0) }
            ))
            .toggleStyle(.switch)

            Button(miku.talking ? "Terminar de hablar" : "Hablar con Miku") {
                miku.toggleTalking()
            }
            .disabled(miku.state.status == .disconnected)

            HStack(spacing: 6) {
                TextField("Escríbele algo…", text: $draft)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(sendDraft)
                Button("Enviar", action: sendDraft)
                    .disabled(draft.isEmpty)
            }

            Divider()

            Button("Ajustes…") { openWindow(id: "settings") }
                .keyboardShortcut(",", modifiers: .command)
            Button("Salir de Miku") { NSApplication.shared.terminate(nil) }
                .keyboardShortcut("q", modifiers: .command)
        }
        .padding(14)
        .frame(width: 280)
    }

    private func sendDraft() {
        miku.send(text: draft)
        draft = ""
    }
}
