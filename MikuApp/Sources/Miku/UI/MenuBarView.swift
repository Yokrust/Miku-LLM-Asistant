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

            Toggle("Escuchar siempre", isOn: Binding(
                get: { miku.state.listeningEnabled },
                set: { miku.setListening($0) }
            ))
            .toggleStyle(.switch)
            .disabled(miku.state.status == .disconnected)

            if miku.listening {
                gatePanel
            }

            Button(miku.talking ? "Terminar de hablar" : "Hablar con Miku") {
                miku.toggleTalking()
            }
            .disabled(miku.state.status == .disconnected || miku.dictating)

            Button(miku.dictating ? "Terminar de anotar" : "Escuchar y anotar") {
                miku.toggleDictation()
            }
            .disabled(miku.state.status == .disconnected)

            if miku.dictating || !miku.state.dictationText.isEmpty {
                dictationPanel
            }

            HStack(spacing: 6) {
                TextField("Escríbele algo…", text: $draft)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(sendDraft)
                Button("Enviar", action: sendDraft)
                    .disabled(draft.isEmpty)
            }

            Divider()

            Button("Abrir la Consola") { openWindow(id: "console") }
                .keyboardShortcut("0", modifiers: .command)
            Button("Ajustes…") { openWindow(id: "settings") }
                .keyboardShortcut(",", modifiers: .command)
            Button("Salir de Miku") { NSApplication.shared.terminate(nil) }
                .keyboardShortcut("q", modifiers: .command)
        }
        .padding(14)
        .frame(width: 280)
    }

    /// What the open mic is doing: whose voice it will obey, and what it made of
    /// the last thing it heard. A blocked turn is silent by design, so without
    /// this the user would have no way to tell "she ignored me" from "she did
    /// not believe it was me".
    private var gatePanel: some View {
        VStack(alignment: .leading, spacing: 4) {
            if miku.state.voiceIdActive {
                Label("Solo obedece tu voz", systemImage: "checkmark.shield")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Label("Sin voz inscrita: obedece a cualquiera", systemImage: "exclamationmark.shield")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
            if let gate = miku.state.lastGate, !gate.message.isEmpty {
                Text(gate.message)
                    .font(.caption)
                    .foregroundStyle(gate.allowed ? Color.secondary : Color.orange)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 6))
    }

    /// Live view of the transcript. It grows a chunk behind the speaker, which is
    /// expected: a piece is only transcribed once its pause has been heard.
    private var dictationPanel: some View {
        VStack(alignment: .leading, spacing: 4) {
            if miku.state.dictationLagging {
                Label("Transcribiendo con retraso…", systemImage: "clock.arrow.circlepath")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
            ScrollView {
                Text(miku.state.dictationText.isEmpty
                     ? "Anotaré lo que se hable — la tuya o la de quien esté cerca."
                     : miku.state.dictationText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
            .frame(height: 90)
        }
        .padding(8)
        .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 6))
    }

    private func sendDraft() {
        miku.send(text: draft)
        draft = ""
    }
}
