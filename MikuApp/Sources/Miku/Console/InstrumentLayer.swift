import SwiftUI

/// The geometry behind Miku that keeps the empty cover from feeling empty.
///
/// **Geometry, not information** (DISENO.md §8). The moment readable blocks of data go
/// in here, this is v1 again — the dense console that was rejected for burying the
/// product under its own telemetry. Everything is 1 px and monochrome.
///
/// One exception to the monochrome rule, and it earns itself: the graduated ring *is*
/// the input meter. The lit arc is the real microphone level, so the ring stops being
/// an ornament and becomes the instrument it looks like. Drawn static, it loses that
/// justification.
struct InstrumentLayer: View {
    /// 0…1 microphone level.
    var nivel: Double = 0
    /// Fraction of the session window already elapsed, 0…1.
    var progresoSesion: Double = 0
    /// Optical recentring when the sidebar covers part of the canvas.
    var desplazamientoX: CGFloat = 0

    @Environment(\.colorScheme) private var esquema

    var body: some View {
        Canvas { contexto, tamano in
            let sutil = esquema == .dark
                ? Color.white.opacity(0.12) : Color(red: 0.04, green: 0.08, blue: 0.09).opacity(0.10)
            let fuerte = esquema == .dark
                ? Color.white.opacity(0.22) : Color(red: 0.04, green: 0.08, blue: 0.09).opacity(0.20)
            let acento = Color(red: 0.224, green: 0.773, blue: 0.733)

            retícula(contexto, tamano, color: sutil.opacity(0.35))

            // The instrument is centred on Miku, not on the window: she is recentred
            // when the sidebar covers the canvas, and so is everything drawn around her.
            let centro = CGPoint(x: tamano.width / 2 + desplazamientoX, y: tamano.height * 0.59)
            let escala = min(tamano.width, tamano.height) / 800

            anilloGraduado(contexto, centro: centro, radio: 412 * escala,
                           sutil: sutil, fuerte: fuerte, acento: acento)
            circulo(contexto, centro: centro, radio: 296 * escala, color: sutil.opacity(0.5))
            anilloPunteado(contexto, centro: centro, radio: 186 * escala, color: sutil)
            radios(contexto, centro: centro, radio: 412 * escala, color: sutil)
            escuadras(contexto, tamano, color: fuerte, escala: escala)
        }
        .allowsHitTesting(false)
    }

    private func retícula(_ c: GraphicsContext, _ t: CGSize, color: Color) {
        var trazo = Path()
        for x in stride(from: 0, through: t.width, by: 40) {
            trazo.move(to: CGPoint(x: x, y: 0)); trazo.addLine(to: CGPoint(x: x, y: t.height))
        }
        for y in stride(from: 0, through: t.height, by: 40) {
            trazo.move(to: CGPoint(x: 0, y: y)); trazo.addLine(to: CGPoint(x: t.width, y: y))
        }
        c.stroke(trazo, with: .color(color), lineWidth: 1)
    }

    /// 96 marks, every 8th one longer. The first `nivel` of them light up in accent.
    private func anilloGraduado(_ c: GraphicsContext, centro: CGPoint, radio: CGFloat,
                                sutil: Color, fuerte: Color, acento: Color) {
        let total = 96
        let encendidas = Int((Double(total) * nivel.clamped01).rounded())
        for i in 0..<total {
            let mayor = i % 8 == 0
            let largo: CGFloat = mayor ? 13 : 6
            // Start at the top and run clockwise, so the meter fills the way a dial does.
            let angulo = -Double.pi / 2 + (Double(i) / Double(total)) * 2 * .pi
            let desde = CGPoint(x: centro.x + CGFloat(cos(angulo)) * radio,
                                y: centro.y + CGFloat(sin(angulo)) * radio)
            let hasta = CGPoint(x: centro.x + CGFloat(cos(angulo)) * (radio + largo),
                                y: centro.y + CGFloat(sin(angulo)) * (radio + largo))
            var trazo = Path()
            trazo.move(to: desde); trazo.addLine(to: hasta)
            let color = i < encendidas ? acento : (mayor ? fuerte : sutil)
            c.stroke(trazo, with: .color(color), lineWidth: i < encendidas ? 1.6 : 1)
        }
    }

    private func circulo(_ c: GraphicsContext, centro: CGPoint, radio: CGFloat, color: Color) {
        let caja = CGRect(x: centro.x - radio, y: centro.y - radio, width: radio * 2, height: radio * 2)
        c.stroke(Path(ellipseIn: caja), with: .color(color), lineWidth: 1)
    }

    /// 24 alternating segments.
    private func anilloPunteado(_ c: GraphicsContext, centro: CGPoint, radio: CGFloat, color: Color) {
        let segmentos = 24
        for i in stride(from: 0, to: segmentos, by: 2) {
            let a0 = (Double(i) / Double(segmentos)) * 2 * .pi
            let a1 = (Double(i + 1) / Double(segmentos)) * 2 * .pi
            var trazo = Path()
            trazo.addArc(center: centro, radius: radio,
                         startAngle: .radians(a0), endAngle: .radians(a1), clockwise: false)
            c.stroke(trazo, with: .color(color), lineWidth: 1)
        }
    }

    /// Eight short spokes just outside the graduated ring.
    private func radios(_ c: GraphicsContext, centro: CGPoint, radio: CGFloat, color: Color) {
        for i in 0..<8 {
            let angulo = (Double(i) / 8) * 2 * .pi + .pi / 16
            var trazo = Path()
            trazo.move(to: CGPoint(x: centro.x + CGFloat(cos(angulo)) * (radio + 26),
                                   y: centro.y + CGFloat(sin(angulo)) * (radio + 26)))
            trazo.addLine(to: CGPoint(x: centro.x + CGFloat(cos(angulo)) * (radio + 54),
                                      y: centro.y + CGFloat(sin(angulo)) * (radio + 54)))
            c.stroke(trazo, with: .color(color), lineWidth: 1)
        }
    }

    /// Framing corners, aligned to the 40 pt grid.
    private func escuadras(_ c: GraphicsContext, _ t: CGSize, color: Color, escala: CGFloat) {
        let brazo: CGFloat = 26 * escala
        let esquinas: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [
            (280, 160, 1, 1), (960, 160, -1, 1), (280, 720, 1, -1), (960, 720, -1, -1),
        ]
        var trazo = Path()
        for (x, y, sx, sy) in esquinas {
            let p = CGPoint(x: x * escala * (t.width / (1240 * escala)), y: y * escala)
            trazo.move(to: CGPoint(x: p.x + brazo * sx, y: p.y))
            trazo.addLine(to: p)
            trazo.addLine(to: CGPoint(x: p.x, y: p.y + brazo * sy))
        }
        c.stroke(trazo, with: .color(color), lineWidth: 1)
    }
}
