import SwiftUI

/// Miku's state, drawn as a shape.
///
/// Each state has its **own silhouette** (DISENO.md §10). That is not decoration: two
/// states that differ only by colour are the same icon to anyone who can't separate
/// those hues, and the same icon again anywhere the system renders it monochrome. The
/// colour reinforces, it never carries the meaning alone.
///
/// Two of the six move — the arc turns, the wave rises — and both stop dead when the
/// system asks for reduced motion.
struct StatusIndicator: View {
    let estado: MikuStatus
    var tamano: CGFloat = 24
    /// 0…1 live input level. When nil, the speaking wave falls back to a gentle idle
    /// animation instead of pretending to measure something.
    var nivel: Double?

    @Environment(\.accessibilityReduceMotion) private var menosMovimiento

    var body: some View {
        Group {
            switch estado {
            case .idle:
                anillo(color: MikuColor.textoTerciario)

            case .listening, .awake:
                ZStack {
                    anillo(color: MikuColor.acentoTinta)
                    Circle()
                        .fill(MikuColor.acentoRelleno)
                        .frame(width: tamano * 0.34, height: tamano * 0.34)
                }

            case .thinking:
                arcoGiratorio

            case .speaking:
                onda

            case .dictating:
                Image(systemName: "text.badge.plus")
                    .font(.system(size: tamano * 0.82, weight: .medium))
                    .foregroundStyle(MikuColor.acentoTinta)

            case .muted:
                ZStack {
                    anillo(color: MikuColor.textoTerciario)
                    Capsule()
                        .fill(MikuColor.textoTerciario)
                        .frame(width: tamano * 0.86, height: max(1.5, tamano * 0.075))
                        .rotationEffect(.degrees(-45))
                }

            case .disconnected:
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: tamano * 0.82, weight: .medium))
                    .foregroundStyle(MikuColor.estadoAviso)
            }
        }
        .frame(width: tamano, height: tamano)
        .accessibilityLabel(estado.label)
    }

    // MARK: - piezas

    private var grosor: CGFloat { max(1.5, tamano * 0.083) }

    private func anillo(color: Color) -> some View {
        Circle()
            .strokeBorder(color, lineWidth: grosor)
            .frame(width: tamano, height: tamano)
    }

    /// A 270° arc. It turns once per second; frozen at its resting angle when the
    /// system asks for less motion — the shape alone still says "thinking".
    private var arcoGiratorio: some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: menosMovimiento)) { contexto in
            let vuelta = menosMovimiento
                ? 0
                : contexto.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 1) * 360
            Circle()
                .trim(from: 0, to: 0.75)
                .stroke(MikuColor.acentoTinta, style: StrokeStyle(lineWidth: grosor, lineCap: .round))
                .rotationEffect(.degrees(vuelta))
                .frame(width: tamano - grosor, height: tamano - grosor)
        }
    }

    /// Five bars. With a real level they follow the input; without one they breathe,
    /// so the shape still reads as sound rather than sitting frozen.
    private var onda: some View {
        TimelineView(.animation(minimumInterval: 1 / 24, paused: menosMovimiento)) { contexto in
            let t = contexto.date.timeIntervalSinceReferenceDate
            HStack(spacing: max(1, tamano * 0.075)) {
                ForEach(0..<5, id: \.self) { i in
                    Capsule()
                        .fill(MikuColor.acentoRelleno)
                        .frame(width: max(1.5, tamano * 0.11), height: altura(barra: i, t: t))
                }
            }
        }
    }

    private func altura(barra i: Int, t: TimeInterval) -> CGFloat {
        let base: Double
        if menosMovimiento {
            base = [0.5, 0.85, 1.0, 0.7, 0.45][i]
        } else if let nivel {
            // Centre bars react hardest, so the shape peaks in the middle like a voice.
            let peso = [0.55, 0.85, 1.0, 0.8, 0.6][i]
            let vaiven = 0.82 + 0.18 * sin(t * 7 + Double(i))
            base = 0.24 + nivel.clamped01 * peso * vaiven
        } else {
            base = 0.35 + 0.45 * abs(sin(t * 3.1 + Double(i) * 0.7))
        }
        return max(tamano * 0.18, tamano * 0.92 * base)
    }
}

extension Double {
    var clamped01: Double { Swift.min(1, Swift.max(0, self)) }
}
