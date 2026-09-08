import SwiftUI

/// The cover. Only what matters *now*.
///
/// v1 put the whole product on this screen — two columns of cards flanking Miku plus a
/// telemetry strip — and it was rejected for saturation. What survives is: Miku, the
/// status capsule, the last exchange, a pending confirmation if there is one, and a few
/// mono annotations at the edges. Everything else lives in its own view.
struct InicioView: View {
    @Environment(MikuController.self) private var miku

    var body: some View {
        ZStack {
            MikuRender(estado: miku.state.status)

            VStack(spacing: 0) {
                anotacionSuperior
                Spacer(minLength: 0)
            }

            HStack(alignment: .center) {
                ultimoIntercambio
                Spacer(minLength: 24)
                if let confirmacion = miku.state.confirmacion {
                    TarjetaConfirmacion(confirmacion: confirmacion) { permitir in
                        miku.responderConfirmacion(confirmacion, permitir: permitir)
                    }
                    .frame(width: 250)
                }
            }

            VStack {
                Spacer()
                StatusCapsule(
                    estado: miku.state.status,
                    detalle: detalleEstado,
                    nivel: miku.state.nivelEntrada
                )
                .padding(.bottom, 34)
            }

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Text(miku.state.usaNube ? "Nube" : "Local")
                        .mikuText(.etiquetaHUD)
                        .foregroundStyle(MikuColor.textoTerciario)
                }
            }
        }
    }

    /// The last exchange, two lines, at the left edge. Not a card: content never takes
    /// glass, and on the cover it should read as an annotation, not as a panel.
    private var ultimoIntercambio: some View {
        VStack(alignment: .leading, spacing: 14) {
            if !miku.state.lastTranscript.isEmpty {
                linea(etiqueta: "Tú", texto: miku.state.lastTranscript,
                      color: MikuColor.textoTerciario)
            }
            if !miku.state.lastReply.isEmpty {
                linea(etiqueta: "Miku", texto: miku.state.lastReply,
                      color: MikuColor.acentoTinta)
            }
        }
        .frame(width: 260, alignment: .leading)
    }

    private func linea(etiqueta: String, texto: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(etiqueta).mikuText(.etiquetaHUD).foregroundStyle(color)
            Text(texto)
                .mikuText(.cuerpo)
                .foregroundStyle(MikuColor.textoPrimario)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var detalleEstado: String {
        switch miku.state.status {
        case .listening, .awake:
            return "La sesión sigue abierta \(miku.state.segundosSesion) s"
        case .dictating:
            return "No responde: sólo escribe lo que oye"
        case .muted:
            return "Di «Miku» no la despierta"
        case .disconnected:
            return "No encuentra el motor"
        default:
            return miku.state.listeningEnabled ? "Di «Miku» para empezar" : "Micrófono apagado"
        }
    }

    /// Session clock plus a graduated bar of the window that is open. The elapsed part
    /// is in accent — the same rule as the ring: accent means Miku is live.
    private var anotacionSuperior: some View {
        HStack {
            VStack(alignment: .leading, spacing: 7) {
                Text("Sesión \(reloj) · \(miku.state.status == .muted ? "en pausa" : "abierta")")
                    .mikuText(.etiquetaHUD)
                    .foregroundStyle(MikuColor.textoTerciario)
                BarraSesion(progreso: miku.state.progresoSesion).frame(width: 170, height: 6)
            }
            Spacer()
        }
    }

    private var reloj: String {
        String(format: "%02d:%02d", miku.state.segundosSesion / 60, miku.state.segundosSesion % 60)
    }
}

/// The graduated 0–25 s session scale.
private struct BarraSesion: View {
    let progreso: Double

    var body: some View {
        Canvas { c, tamano in
            let marcas = 26
            let paso = tamano.width / CGFloat(marcas - 1)
            let encendidas = Int((Double(marcas) * progreso.clamped01).rounded())
            for i in 0..<marcas {
                let x = CGFloat(i) * paso
                let alto: CGFloat = i % 5 == 0 ? tamano.height : tamano.height * 0.55
                let caja = CGRect(x: x, y: tamano.height - alto, width: 1, height: alto)
                c.fill(Path(caja), with: .color(
                    i < encendidas
                        ? Color(red: 0.224, green: 0.773, blue: 0.733)
                        : Color.gray.opacity(0.35)
                ))
            }
        }
    }
}

/// The pending action, on the cover. `Denegar` is the default on purpose: a stray
/// Return must not run anything.
struct TarjetaConfirmacion: View {
    let confirmacion: ConfirmacionPendiente
    let responder: (Bool) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 7) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(MikuColor.estadoAviso)
                Text(confirmacion.titulo)
                    .mikuText(.cuerpoEnfasis)
                    .foregroundStyle(MikuColor.textoPrimario)
            }

            Text(confirmacion.comando)
                .mikuText(.dato)
                .foregroundStyle(MikuColor.textoPrimario)
                .textSelection(.enabled)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background {
                    RoundedRectangle(cornerRadius: Radio.sm)
                        .fill(MikuColor.fondoVidrioAlto)
                }

            HStack(spacing: 8) {
                Button { responder(false) } label: {
                    Text("Denegar").mikuText(.cuerpoEnfasis).frame(maxWidth: .infinity)
                }
                .buttonStyle(BotonMiku(prominente: true))
                .keyboardShortcut(.defaultAction)

                Button { responder(true) } label: {
                    Text("Permitir").mikuText(.cuerpoEnfasis).frame(maxWidth: .infinity)
                }
                .buttonStyle(BotonMiku(prominente: false))
            }
        }
        .padding(14)
        .vidrio(radio: Radio.panel)
        .sombraPanel()
    }
}

/// Glass buttons. Neither one takes an accent fill: the accent means "Miku is active",
/// and spending it on a button here would make one colour mean two things.
struct BotonMiku: ButtonStyle {
    let prominente: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(MikuColor.textoPrimario)
            .padding(.vertical, 7)
            .background {
                RoundedRectangle(cornerRadius: Radio.boton)
                    .fill(prominente ? MikuColor.fondoVidrioAlto : MikuColor.fondoVidrio)
                    .overlay {
                        RoundedRectangle(cornerRadius: Radio.boton)
                            .strokeBorder(MikuColor.lineaSutil, lineWidth: 1)
                    }
            }
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

/// Miku herself.
///
/// The render is not in the repo yet: it lives only inside the Figma mockups, and
/// DISENO.md §18 blocks it anyway — the pose needs re-exporting from the 3D model with
/// her eyes closed. Until that PNG lands this draws her aura and silhouette, so the
/// composition, the recentring and the capsule can be judged for real.
struct MikuRender: View {
    /// Framing knobs. The cover crops her around mid-thigh at the window's bottom
    /// edge; these are the two numbers to turn if that crop needs moving.
    static let alto: CGFloat = 830
    static let desplazamiento: CGFloat = 235

    let estado: MikuStatus
    @Environment(\.accessibilityReduceMotion) private var menosMovimiento

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 20, paused: menosMovimiento)) { contexto in
            let t = contexto.date.timeIntervalSinceReferenceDate
            // She breathes: the aura swells about 4 % over four seconds. It is the only
            // ambient motion on the cover, and it stops when the system asks it to.
            let respiro = menosMovimiento ? 1.0 : 1 + 0.04 * sin(t * .pi / 2)

            ZStack {
                RadialGradient(
                    colors: [
                        MikuColor.acentoRelleno.opacity(estado == .muted ? 0.16 : 0.42),
                        MikuColor.acentoRelleno.opacity(estado == .muted ? 0.05 : 0.14),
                        MikuColor.acentoRelleno.opacity(0),
                    ],
                    center: .center, startRadius: 40, endRadius: 330
                )
                .frame(width: 660, height: 660)
                .scaleEffect(respiro)
                .blur(radius: 44)
                .offset(y: -120)

                if let imagen = NSImage(named: "MikuRender") {
                    Image(nsImage: imagen).resizable().scaledToFit().frame(height: Self.alto)
                } else {
                    marcador
                }
            }
            .offset(y: Self.desplazamiento)
        }
    }

    private var marcador: some View {
        VStack(spacing: 10) {
            Image(systemName: "person.crop.square.badge.camera")
                .font(.system(size: 34, weight: .ultraLight))
                .foregroundStyle(MikuColor.textoTerciario)
            Text("Falta el render de Miku")
                .mikuText(.etiquetaHUD)
                .foregroundStyle(MikuColor.textoTerciario)
        }
    }
}
