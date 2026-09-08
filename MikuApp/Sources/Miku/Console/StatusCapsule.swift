import SwiftUI

/// The status capsule that floats over Miku's body on the cover.
///
/// It sits on glass **with** the dimming layer: it lands on the brightest part of her
/// render, and without the dim underneath the white of her body swallows the text.
struct StatusCapsule: View {
    let estado: MikuStatus
    let detalle: String
    var nivel: Double?

    var body: some View {
        HStack(spacing: 12) {
            StatusIndicator(estado: estado, tamano: 26, nivel: nivel)

            VStack(alignment: .leading, spacing: 1) {
                Text(estado.tituloCorto)
                    .mikuText(.titulo2)
                    .foregroundStyle(MikuColor.textoPrimario)
                Text(detalle)
                    .mikuText(.secundario)
                    .foregroundStyle(MikuColor.textoSecundario)
            }

            if estado.muestraOnda {
                OndaViva(nivel: nivel).frame(width: 96, height: 30)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .vidrio(radio: Radio.capsula)
        .sombraPanel()
    }
}

/// The live wave in the capsule. Driven by the real level when there is one.
struct OndaViva: View {
    var nivel: Double?
    @Environment(\.accessibilityReduceMotion) private var menosMovimiento

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 24, paused: menosMovimiento)) { contexto in
            let t = contexto.date.timeIntervalSinceReferenceDate
            Canvas { c, tamano in
                let barras = 22
                let ancho: CGFloat = 2
                let paso = tamano.width / CGFloat(barras)
                for i in 0..<barras {
                    let fase = Double(i) * 0.55
                    let base = menosMovimiento ? 0.45 : (0.35 + 0.5 * abs(sin(t * 4 + fase)))
                    let amplitud = (nivel.map { 0.25 + $0.clamped01 * 0.75 } ?? 1) * base
                    let alto = max(3, tamano.height * amplitud)
                    let x = CGFloat(i) * paso + paso / 2
                    let caja = CGRect(x: x - ancho / 2, y: (tamano.height - alto) / 2,
                                      width: ancho, height: alto)
                    c.fill(Path(roundedRect: caja, cornerRadius: 1),
                           with: .color(Color(red: 0.224, green: 0.773, blue: 0.733)))
                }
            }
        }
    }
}

extension MikuStatus {
    /// The capsule shows a short state, not the full sentence — the sentence is the
    /// subtitle's job.
    var tituloCorto: String {
        switch self {
        case .disconnected: return "Sin conexión"
        case .idle: return "En reposo"
        case .listening, .awake: return "Escuchando"
        case .thinking: return "Pensando"
        case .speaking: return "Hablando"
        case .dictating: return "Anotando"
        case .muted: return "Silenciada"
        }
    }

    var muestraOnda: Bool {
        switch self {
        case .listening, .awake, .speaking, .dictating: return true
        default: return false
        }
    }
}
