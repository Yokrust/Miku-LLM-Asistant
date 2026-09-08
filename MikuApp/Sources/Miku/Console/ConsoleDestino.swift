import SwiftUI

/// The five destinations of the Console.
enum ConsoleDestino: String, CaseIterable, Identifiable, Hashable {
    case inicio = "Inicio"
    case conversacion = "Conversación"
    case transcripciones = "Transcripciones"
    case notas = "Notas"
    case actividad = "Actividad"

    var id: String { rawValue }

    /// The real SF Symbol the design names for each row (DISENO.md §17) — the symbol,
    /// not a redrawing of it.
    var simbolo: String {
        switch self {
        case .inicio: return "house"
        case .conversacion: return "bubble.left.and.bubble.right"
        case .transcripciones: return "waveform"
        case .notas: return "note.text"
        case .actividad: return "clock.arrow.circlepath"
        }
    }
}

/// A note hanging under `Notas` in the sidebar — the second level that gives the list
/// its structure. DISENO.md §3 (v5): a sidebar feels rich through hierarchy, not labels.
struct NotaEnlace: Identifiable, Hashable {
    let id: String
    let titulo: String
}
