import AppKit
import SwiftUI

/// The nine text styles from `Miku · Tipografía`.
///
/// Geist carries the interface, IBM Plex Mono carries the instrument — micro-labels,
/// fingerprints, the clock, figures. Weight jumps 400 → 600 → 700 with nothing in
/// between: that gap is what gives the type its editorial character.
///
/// Two consequences of leaving SF Pro behind, both handled here:
/// * accessible text scaling is no longer free, so every style scales through
///   `relativeTo:` and its tracking scales with it;
/// * tracking is stored as a **percentage**, exactly as in Figma, and multiplied by
///   the resolved size — hard-coding points would break the moment text scales.
struct MikuTextStyle {
    let familia: String
    let tamano: CGFloat
    let interlinea: CGFloat
    /// Fraction of the font size, e.g. -0.02 for −2 %.
    let tracking: CGFloat
    let mayusculas: Bool
    /// The system style this one scales alongside.
    let relativoA: Font.TextStyle

    // Geist — interface
    static let display = MikuTextStyle(familia: "Geist-Bold", tamano: 34, interlinea: 40, tracking: -0.02, mayusculas: false, relativoA: .largeTitle)
    static let titulo1 = MikuTextStyle(familia: "Geist-Bold", tamano: 22, interlinea: 27, tracking: -0.02, mayusculas: false, relativoA: .title)
    static let titulo2 = MikuTextStyle(familia: "Geist-Bold", tamano: 16, interlinea: 21, tracking: -0.015, mayusculas: false, relativoA: .title3)
    static let cuerpo = MikuTextStyle(familia: "Geist-Regular", tamano: 13, interlinea: 18, tracking: -0.005, mayusculas: false, relativoA: .body)
    static let cuerpoEnfasis = MikuTextStyle(familia: "Geist-SemiBold", tamano: 13, interlinea: 18, tracking: -0.005, mayusculas: false, relativoA: .body)
    static let secundario = MikuTextStyle(familia: "Geist-Regular", tamano: 11, interlinea: 15, tracking: 0, mayusculas: false, relativoA: .caption)

    // IBM Plex Mono — instrument
    /// Micro-labels only. Never essential text: it is uppercase and widely tracked,
    /// which is the opposite of comfortable reading.
    static let etiquetaHUD = MikuTextStyle(familia: "IBMPlexMono-Medium", tamano: 11, interlinea: 14, tracking: 0.09, mayusculas: true, relativoA: .caption)
    static let dato = MikuTextStyle(familia: "IBMPlexMono-Medium", tamano: 15, interlinea: 19, tracking: -0.01, mayusculas: false, relativoA: .callout)
    static let datoGrande = MikuTextStyle(familia: "IBMPlexMono-SemiBold", tamano: 28, interlinea: 32, tracking: -0.02, mayusculas: false, relativoA: .title)
}

private struct MikuTextModifier: ViewModifier {
    let estilo: MikuTextStyle
    @ScaledMetric private var escala: CGFloat

    init(estilo: MikuTextStyle) {
        self.estilo = estilo
        _escala = ScaledMetric(wrappedValue: estilo.tamano, relativeTo: estilo.relativoA)
    }

    func body(content: Content) -> some View {
        // `interlinea` is a total line height; SwiftUI's lineSpacing is the gap *added*
        // between lines, so the font's own height has to come off first.
        let natural = NSFont(name: estilo.familia, size: escala)?.boundingRectForFont.height ?? escala * 1.2
        let objetivo = estilo.interlinea * (escala / estilo.tamano)
        return content
            .font(.custom(estilo.familia, size: estilo.tamano, relativeTo: estilo.relativoA))
            .tracking(escala * estilo.tracking)
            .lineSpacing(max(0, objetivo - natural))
            .textCase(estilo.mayusculas ? .uppercase : nil)
    }
}

extension View {
    /// Apply one of the nine `Miku/*` text styles.
    func mikuText(_ estilo: MikuTextStyle) -> some View {
        modifier(MikuTextModifier(estilo: estilo))
    }
}

/// Registers the bundled families. `ATSApplicationFontsPath` in Info.plist handles this
/// for a built .app; this is the belt-and-braces path so the fonts also resolve when the
/// binary runs straight out of SwiftPM, and it says so out loud when one is missing
/// rather than letting macOS quietly substitute Helvetica.
enum MikuFonts {
    static func register() {
        let esperadas = [
            "Geist-Regular", "Geist-SemiBold", "Geist-Bold",
            "IBMPlexMono-Medium", "IBMPlexMono-SemiBold",
        ]
        guard let carpeta = Bundle.main.resourceURL?.appendingPathComponent("Fonts"),
              let archivos = try? FileManager.default.contentsOfDirectory(
                  at: carpeta, includingPropertiesForKeys: nil)
        else { return }

        for archivo in archivos where ["otf", "ttf"].contains(archivo.pathExtension.lowercased()) {
            CTFontManagerRegisterFontsForURL(archivo as CFURL, .process, nil)
        }

        let faltan = esperadas.filter { NSFont(name: $0, size: 12) == nil }
        if !faltan.isEmpty {
            NSLog("[Miku] Fuentes no registradas, se sustituirán: \(faltan.joined(separator: ", "))")
        }
    }
}
