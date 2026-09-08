import SwiftUI

/// Two floating glass slabs: a 60 pt rail of icons and a 216 pt panel of labels.
///
/// This is the piece that iterated most. It once had group headings, a description
/// under every item, counters everywhere and a card for the brain — about twenty
/// strings — and still read as a flat list. The fix was to take text out and put a
/// level in: nine strings, one badge, and `Notas` unfolding into its children.
/// See DISENO.md §3 (v5) and §9.2.
struct Sidebar: View {
    @Binding var seleccion: ConsoleDestino
    let notas: [NotaEnlace]
    let avisosActividad: Int
    var perfilAccion: () -> Void = {}

    /// Rows only render a disclosure when there is something to disclose.
    @State private var notasDesplegadas = true

    private let anchoRiel: CGFloat = 60
    private let anchoMenu: CGFloat = 216
    private let separacion: CGFloat = 8
    /// Both slabs start at y=48 so the traffic lights sit over the window, not over them.
    private let margenSuperior: CGFloat = 48

    var body: some View {
        HStack(alignment: .top, spacing: separacion) {
            riel
            menu
        }
        .padding(.leading, 16)
        .padding(.top, margenSuperior)
        .padding(.bottom, 16)
    }

    // MARK: - riel

    private var riel: some View {
        VStack(spacing: 0) {
            marca
                .padding(.top, 14)
                .padding(.bottom, 10)

            Rectangle()
                .fill(MikuColor.lineaSutil)
                .frame(width: 28, height: 1)
                .padding(.bottom, 12)

            VStack(spacing: 8) {
                ForEach(ConsoleDestino.allCases) { destino in
                    ranura(destino)
                }
            }

            Spacer(minLength: 12)

            Button(action: perfilAccion) {
                Circle()
                    .fill(MikuColor.acentoVelo)
                    .overlay {
                        Circle().strokeBorder(MikuColor.acentoTinta.opacity(0.5), lineWidth: 1)
                    }
                    .overlay {
                        Text("Y").mikuText(.cuerpoEnfasis).foregroundStyle(MikuColor.acentoTinta)
                    }
                    .frame(width: 30, height: 30)
            }
            .buttonStyle(.plain)
            .help("Perfil local")
            .padding(.bottom, 14)
        }
        .frame(width: anchoRiel)
        .frame(maxHeight: .infinity)
        .vidrio(radio: Radio.losa)
        .sombraPanel()
    }

    private var marca: some View {
        ZStack {
            Circle().strokeBorder(MikuColor.acentoTinta, lineWidth: 2)
            Circle().fill(MikuColor.acentoRelleno).frame(width: 8, height: 8)
        }
        .frame(width: 22, height: 22)
        .accessibilityLabel("Miku")
    }

    private func ranura(_ destino: ConsoleDestino) -> some View {
        let activo = seleccion == destino
        return Button {
            seleccion = destino
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: Radio.ranura)
                    .fill(activo ? MikuColor.acentoRelleno : .clear)
                Image(systemName: destino.simbolo)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(activo ? MikuColor.textoSobreAcento : MikuColor.textoSecundario)
            }
            .frame(width: 40, height: 40)
            .overlay(alignment: .topTrailing) {
                // One badge in the whole sidebar. In the rail it is a mark, not a
                // number: there is no room to read a digit at 40 pt.
                if destino == .actividad, avisosActividad > 0 {
                    Image(systemName: "triangle.fill")
                        .font(.system(size: 6))
                        .foregroundStyle(MikuColor.estadoAviso)
                        .offset(x: -4, y: 4)
                }
            }
        }
        .buttonStyle(.plain)
        .help(destino.rawValue)
    }

    // MARK: - menú

    private var menu: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                marca.frame(width: 18, height: 18)
                Text("Miku").mikuText(.titulo2).foregroundStyle(MikuColor.textoPrimario)
            }
            .padding(.horizontal, 14)
            .padding(.top, 22)
            .padding(.bottom, 16)

            Rectangle()
                .fill(MikuColor.lineaSutil)
                .frame(height: 1)
                .padding(.horizontal, 14)
                .padding(.bottom, 14)

            VStack(spacing: 6) {
                ForEach(ConsoleDestino.allCases) { destino in
                    fila(destino)
                    if destino == .notas, notasDesplegadas, !notas.isEmpty {
                        hijosDeNotas
                    }
                }
            }
            .padding(.horizontal, 8)

            Spacer(minLength: 0)
        }
        .frame(width: anchoMenu, alignment: .leading)
        .frame(maxHeight: .infinity)
        .vidrio(radio: Radio.losa)
        .sombraPanel()
    }

    private func fila(_ destino: ConsoleDestino) -> some View {
        let activo = seleccion == destino
        return Button {
            seleccion = destino
            if destino == .notas { notasDesplegadas.toggle() }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: destino.simbolo)
                    .font(.system(size: 15, weight: .regular))
                    .frame(width: 20)
                Text(destino.rawValue).mikuText(.cuerpo)
                Spacer(minLength: 4)
                if destino == .actividad, avisosActividad > 0 {
                    insignia(avisosActividad, sobreAcento: activo)
                }
            }
            .foregroundStyle(activo ? MikuColor.textoSobreAcento : MikuColor.textoPrimario)
            .padding(.horizontal, 11)
            .frame(height: 38)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                // Selected is a solid accent pill with dark text — the macOS convention
                // (Finder and Mail fill the selected row with the accent colour). It does
                // not collide with "accent means Miku is active" because her states are
                // told apart by shape, never by colour alone.
                RoundedRectangle(cornerRadius: Radio.fila)
                    .fill(activo ? MikuColor.acentoRelleno : .clear)
            }
        }
        .buttonStyle(.plain)
    }

    private func insignia(_ n: Int, sobreAcento: Bool) -> some View {
        Text("\(n)")
            .mikuText(.secundario)
            .foregroundStyle(sobreAcento ? MikuColor.textoSobreAcento : MikuColor.textoSobreAcento)
            .frame(minWidth: 18, minHeight: 18)
            .background(Circle().fill(MikuColor.estadoAviso))
    }

    private var hijosDeNotas: some View {
        // A single vertical connector runs behind the children: the line is what makes
        // this read as a level rather than as four more rows.
        HStack(spacing: 0) {
            Rectangle()
                .fill(MikuColor.lineaSutil)
                .frame(width: 1)
                .padding(.leading, 20)

            VStack(spacing: 4) {
                ForEach(notas) { nota in
                    HStack(spacing: 8) {
                        Image(systemName: "note.text")
                            .font(.system(size: 12))
                            .foregroundStyle(MikuColor.textoTerciario)
                        Text(nota.titulo)
                            .mikuText(.cuerpo)
                            .foregroundStyle(MikuColor.textoSecundario)
                            .lineLimit(1)
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 10)
                    .frame(height: 30)
                }
            }
            .padding(.leading, 6)
        }
        .padding(.leading, 11)
    }
}
