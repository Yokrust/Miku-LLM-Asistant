import SwiftUI

/// The Console — 1240 × 800, five destinations.
///
/// The content runs full bleed **underneath** the sidebar rather than starting where
/// the sidebar ends: navigation floats over the content, it does not share its plane
/// (DISENO.md §7.3). That is why this is a ZStack and not an HSplitView.
struct ConsoleWindow: View {
    /// Set `MIKU_OPEN_CONSOLE=1` to have the window come up with the app, so the
    /// Console can be rendered and compared against the design without driving the
    /// menu bar by hand.
    static var abrirAlArrancar: Bool { ProcessInfo.processInfo.environment["MIKU_OPEN_CONSOLE"] == "1" }

    @Environment(MikuController.self) private var miku
    @State private var destino: ConsoleDestino = .inicio

    /// How far Miku and her instrument shift right so they read as centred in the
    /// canvas the sidebar leaves free. The grid does not move — it belongs to the window.
    private let recentrado: CGFloat = 158

    var body: some View {
        ZStack(alignment: .topLeading) {
            MikuColor.fondoLienzo.ignoresSafeArea()

            if destino == .inicio {
                InstrumentLayer(
                    nivel: miku.state.nivelEntrada,
                    progresoSesion: miku.state.progresoSesion,
                    desplazamientoX: recentrado
                )
                .ignoresSafeArea()
            }

            contenido
                .padding(.leading, 332)
                .padding(.trailing, 40)

            Sidebar(
                seleccion: $destino,
                notas: miku.state.notasRecientes,
                avisosActividad: miku.state.avisosActividad
            )
        }
        .frame(minWidth: 1000, minHeight: 680)
        .background(MikuColor.fondoLienzo)
    }

    @ViewBuilder
    private var contenido: some View {
        switch destino {
        case .inicio: InicioView()
        case .conversacion: ConversacionView()
        default:
            VStack {
                Text(destino.rawValue).mikuText(.titulo1).foregroundStyle(MikuColor.textoPrimario)
                Text("Sin diseñar todavía").mikuText(.secundario).foregroundStyle(MikuColor.textoTerciario)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
