import SwiftUI

/// The transcript takes the stage and Miku shrinks to a 64 pt portrait with her status
/// ring. Turns are labelled `TÚ` / `MIKU` and every tool she really called is shown as
/// a chip: that labelling *is* the transparency mechanism — never let someone believe
/// they are talking to a person, and say where the AI acted.
struct ConversacionView: View {
    @Environment(MikuController.self) private var miku
    @State private var borrador = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            cabecera

            ScrollViewReader { lector in
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        ForEach(miku.state.turnos) { turno in
                            vista(turno).id(turno.id)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 24)
                    .padding(.bottom, 24)
                }
                .onChange(of: miku.state.turnos.count) {
                    withAnimation(.easeOut(duration: 0.25)) {
                        lector.scrollTo(miku.state.turnos.last?.id, anchor: .bottom)
                    }
                }
            }

            campoDeEntrada.padding(.bottom, 24)
        }
    }

    private var cabecera: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Conversación")
                    .mikuText(.titulo1)
                    .foregroundStyle(MikuColor.textoPrimario)
                Text(resumen)
                    .mikuText(.secundario)
                    .foregroundStyle(MikuColor.textoTerciario)
            }
            Spacer()
            retrato
        }
        .padding(.top, 34)
    }

    private var resumen: String {
        let turnos = miku.state.turnos.count
        let hora = Date().formatted(date: .omitted, time: .shortened)
        return turnos == 0 ? "Sin turnos todavía" : "Hoy · \(hora) — \(turnos) turnos"
    }

    private var retrato: some View {
        ZStack {
            Circle().fill(MikuColor.acentoVelo)
            if let imagen = NSImage(named: "MikuRender") {
                Image(nsImage: imagen).resizable().scaledToFill()
            } else {
                StatusIndicator(estado: miku.state.status, tamano: 26,
                                nivel: miku.state.nivelEntrada)
            }
        }
        .frame(width: 64, height: 64)
        .clipShape(.circle)
        .overlay {
            Circle().strokeBorder(MikuColor.acentoTinta, lineWidth: 2)
        }
    }

    private func vista(_ turno: Turno) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(turno.etiqueta)
                .mikuText(.etiquetaHUD)
                .foregroundStyle(turno.deMiku ? MikuColor.acentoTinta : MikuColor.textoTerciario)

            Text(turno.texto)
                .mikuText(.cuerpo)
                .foregroundStyle(MikuColor.textoPrimario)
                .fixedSize(horizontal: false, vertical: true)
                .textSelection(.enabled)

            if !turno.herramientas.isEmpty {
                HStack(spacing: 6) {
                    ForEach(turno.herramientas, id: \.self) { ChipHerramienta(nombre: $0) }
                }
                .padding(.top, 2)
            }
        }
        .frame(maxWidth: 720, alignment: .leading)
    }

    private var campoDeEntrada: some View {
        HStack(spacing: 10) {
            TextField("Escríbele a Miku…", text: $borrador)
                .textFieldStyle(.plain)
                .mikuText(.cuerpo)
                .foregroundStyle(MikuColor.textoPrimario)
                .onSubmit(enviar)

            Button(action: enviar) {
                Circle()
                    .fill(borrador.isEmpty ? MikuColor.textoTerciario.opacity(0.4) : MikuColor.acentoRelleno)
                    .frame(width: 16, height: 16)
            }
            .buttonStyle(.plain)
            .disabled(borrador.isEmpty)
            .help("Enviar")
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 13)
        .frame(maxWidth: 620, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: Radio.pastilla)
                .fill(MikuColor.fondoVidrioAlto)
                .overlay {
                    RoundedRectangle(cornerRadius: Radio.pastilla)
                        .strokeBorder(MikuColor.lineaSutil, lineWidth: 1)
                }
        }
    }

    private func enviar() {
        let texto = borrador.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !texto.isEmpty else { return }
        miku.send(text: texto)
        borrador = ""
    }
}

/// The name of a tool Miku actually invoked.
struct ChipHerramienta: View {
    let nombre: String

    var body: some View {
        HStack(spacing: 5) {
            Circle().fill(MikuColor.acentoRelleno).frame(width: 5, height: 5)
            Text(nombre).mikuText(.etiquetaHUD)
        }
        .foregroundStyle(MikuColor.acentoTinta)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background {
            RoundedRectangle(cornerRadius: Radio.sm)
                .fill(MikuColor.acentoVelo)
        }
    }
}
