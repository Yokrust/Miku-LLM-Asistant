import AppKit
import SwiftUI

/// The colour tokens from `design/tokens.json`, one to one.
///
/// The names are kept in the language of the design file (`fondo/vidrio`,
/// `acento/tinta`…) on purpose: DISENO.md asks that design and code use the same
/// vocabulary, so a token can be traced from Figma to a pixel without translation.
///
/// Every token resolves per appearance through `NSColor(name:dynamicProvider:)`, so
/// light and dark come from one declaration instead of two parallel palettes.
enum MikuColor {
    // MARK: fondo
    static let fondoLienzo = dynamic(oscuro: 0x0A0C0F, claro: 0xEEF1F3)
    static let fondoLienzo2 = dynamic(oscuro: 0x12161A, claro: 0xFFFFFF)
    static let fondoVidrio = dynamic(oscuro: 0xFFFFFF, oscuroAlfa: 0.06, claro: 0xFFFFFF, claroAlfa: 0.72)
    static let fondoVidrioAlto = dynamic(oscuro: 0xFFFFFF, oscuroAlfa: 0.10, claro: 0xFFFFFF, claroAlfa: 0.92)
    static let fondoElevado = dynamic(oscuro: 0x1A1F24, claro: 0xFFFFFF)
    /// Sits *under* the glass and over the content. Without it Miku's white body
    /// eats the text of anything floating on top of her — it happened for real.
    static let fondoAtenuacion = dynamic(oscuro: 0x000000, oscuroAlfa: 0.34, claro: 0xFFFFFF, claroAlfa: 0.58)

    // MARK: linea
    static let lineaSutil = dynamic(oscuro: 0xFFFFFF, oscuroAlfa: 0.12, claro: 0x0B1416, claroAlfa: 0.10)
    static let lineaFuerte = dynamic(oscuro: 0xFFFFFF, oscuroAlfa: 0.22, claro: 0x0B1416, claroAlfa: 0.20)

    // MARK: texto
    static let textoPrimario = dynamic(oscuro: 0xF4F7F8, claro: 0x0E1417)
    static let textoSecundario = dynamic(oscuro: 0xA7B2B8, claro: 0x55636A)
    /// The tightest token in the system at ~4.7:1 in both modes. Do not darken it.
    static let textoTerciario = dynamic(oscuro: 0x757F85, claro: 0x5F6D74)
    static let textoSobreAcento = dynamic(oscuro: 0x04211F, claro: 0x04211F)

    // MARK: acento
    /// Text, icons and borders. Splits from `acentoRelleno` in light mode because
    /// #39C5BB on white measures 2.15:1 — under the 4.5:1 floor. #0F726C gives 5.8:1.
    static let acentoTinta = dynamic(oscuro: 0x39C5BB, claro: 0x0F726C)
    /// Surfaces, fills and graphics only. Never text.
    static let acentoRelleno = dynamic(oscuro: 0x39C5BB, claro: 0x39C5BB)
    static let acentoVelo = dynamic(oscuro: 0x39C5BB, oscuroAlfa: 0.16, claro: 0x39C5BB, claroAlfa: 0.18)

    // MARK: estado
    static let estadoExito = dynamic(oscuro: 0x30D158, claro: 0x248A3D)
    static let estadoAviso = dynamic(oscuro: 0xFFD60A, claro: 0x8A6100)
    /// Reserved for error and destructive actions. The recording dot uses the accent,
    /// not this, so one colour never means two things.
    static let estadoPeligro = dynamic(oscuro: 0xFF453A, claro: 0xC4271C)

    // MARK: - plumbing

    private static func dynamic(
        oscuro: UInt32, oscuroAlfa: CGFloat = 1,
        claro: UInt32, claroAlfa: CGFloat = 1
    ) -> Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            let dark = appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
            return dark
                ? NSColor(hex: oscuro, alpha: oscuroAlfa)
                : NSColor(hex: claro, alpha: claroAlfa)
        })
    }
}

extension NSColor {
    fileprivate convenience init(hex: UInt32, alpha: CGFloat) {
        self.init(
            srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: alpha
        )
    }
}
