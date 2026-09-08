import SwiftUI

/// Glass, dimming and shadow — the material rules from DISENO.md §7.
///
/// Three of them matter enough to be worth repeating here, because breaking any one
/// of them is visible immediately:
///
/// 1. **Glass is the functional layer.** Bars, navigation slabs, capsules, popovers.
///    Content cards never take it.
/// 2. **Glass over content needs a dimming layer.** `fondo/atenuacion` goes *under*
///    `fondo/vidrio`. Without it Miku's bright body shows straight through and eats
///    the text sitting on the glass.
/// 3. **Shadows are calibrated per theme.** They are literal values, not tokens, so
///    the light variant is much softer than a dimmed copy of the dark one.

private struct Vidrio: ViewModifier {
    let radio: CGFloat
    /// Pass `false` only for glass that sits on a flat window background, where the
    /// dimming layer would just muddy the surface.
    let atenuado: Bool

    func body(content: Content) -> some View {
        content.background {
            ZStack {
                if atenuado {
                    MikuColor.fondoAtenuacion
                }
                Rectangle().fill(.ultraThinMaterial)
                MikuColor.fondoVidrio
            }
            .clipShape(.rect(cornerRadius: radio))
        }
        .overlay {
            RoundedRectangle(cornerRadius: radio)
                .strokeBorder(MikuColor.lineaSutil, lineWidth: 1)
        }
    }
}

private struct SombraPanel: ViewModifier {
    @Environment(\.colorScheme) private var esquema

    func body(content: Content) -> some View {
        // dark: black @45 %, y 10, blur 30 · light: #0A1417 @12 %, y 8, blur 24
        let oscuro = esquema == .dark
        return content.shadow(
            color: oscuro ? .black.opacity(0.45) : Color(red: 0.04, green: 0.08, blue: 0.09).opacity(0.12),
            radius: oscuro ? 15 : 12,
            y: oscuro ? 10 : 8
        )
    }
}

private struct SombraFlotante: ViewModifier {
    @Environment(\.colorScheme) private var esquema

    func body(content: Content) -> some View {
        // For things that float over the desktop rather than inside a window.
        let oscuro = esquema == .dark
        return content.shadow(
            color: .black.opacity(oscuro ? 0.55 : 0.22),
            radius: 28,
            y: 24
        )
    }
}

extension View {
    /// A glass surface of the functional layer.
    func vidrio(radio: CGFloat, atenuado: Bool = true) -> some View {
        modifier(Vidrio(radio: radio, atenuado: atenuado))
    }

    func sombraPanel() -> some View { modifier(SombraPanel()) }
    func sombraFlotante() -> some View { modifier(SombraFlotante()) }
}
