import Foundation
import Observation

/// What Miku is doing right now. Drives the menu bar icon and the status line.
enum MikuStatus: Equatable {
    case disconnected
    case idle
    case listening
    case awake
    case thinking
    case speaking
    case dictating
    case muted

    var label: String {
        switch self {
        case .disconnected: return "Sin conexión con el motor"
        case .idle: return "Lista, di «Miku»"
        case .listening: return "Escuchando…"
        case .awake: return "Te escucho — sigue sin repetir el nombre"
        case .thinking: return "Pensando…"
        case .speaking: return "Hablando…"
        case .dictating: return "Anotando lo que se hable…"
        case .muted: return "Silenciada"
        }
    }

    /// SF Symbol for the menu bar. Template-rendered, so it must read in monochrome.
    var symbol: String {
        switch self {
        case .disconnected: return "exclamationmark.triangle"
        case .idle: return "circle"
        case .listening: return "circle.circle.fill"
        case .awake: return "circle.hexagongrid.circle.fill"
        case .thinking: return "ellipsis.circle"
        case .speaking: return "waveform.circle.fill"
        case .dictating: return "text.badge.plus"
        case .muted: return "circle.slash"
        }
    }
}

/// Why a turn did or did not go through. Comes straight from the backend's
/// `voice-gate` event, which is sent on every utterance the open mic decides on.
struct GateFeedback: Equatable {
    var outcome: String
    var allowed: Bool
    var toolsAllowed: Bool
    var heard: String
    var command: String
    var score: Double?
    var threshold: Double?
    var detail: String

    /// What to show the user. A blocked turn is never spoken aloud, so this line
    /// is the only place the difference shows up.
    var message: String {
        if allowed {
            return toolsAllowed ? heard : "\(heard) — sin herramientas: no reconocí tu voz"
        }
        switch outcome {
        case "no eres tú":
            let s = score.map { String(format: " (%.2f)", $0) } ?? ""
            return "Oí «\(heard)» pero esa no es tu voz\(s)"
        case "no te oí bien":
            return "Oí «\(heard)» pero no me bastó para reconocerte\(detail.isEmpty ? "" : " — \(detail)")"
        default:
            return ""   // no me hablaban: silencio también en la interfaz
        }
    }
}


/// One side of one exchange.
struct Turno: Identifiable, Equatable {
    let id = UUID()
    let deMiku: Bool
    var texto: String
    /// Names of the MCP tools this turn actually invoked.
    var herramientas: [String] = []

    var etiqueta: String { deMiku ? "Miku" : "Tú" }
}

/// An action Miku wants to take that needs a yes or a no first.
struct ConfirmacionPendiente: Identifiable, Equatable {
    let id: String
    /// What kind of action it is, e.g. "Quiere ejecutar un comando".
    let titulo: String
    /// The exact thing that will run. Always shown in full, monospaced.
    let comando: String
}

/// Shared, observable application state.
@MainActor
@Observable
final class AppState {
    var status: MikuStatus = .disconnected
    /// The open-mic switch. On, the microphone streams continuously and the
    /// backend answers only when it hears the name from the right voice.
    var listeningEnabled: Bool = false
    /// What the backend reported when the open mic came up.
    var wakeWordActive: Bool = false
    /// False until a voice has been enrolled with scripts/enroll_voice.py.
    var voiceIdActive: Bool = false
    /// Verdict on the last utterance the open mic decided on.
    var lastGate: GateFeedback?
    /// Last thing the user said, as transcribed by the backend.
    var lastTranscript: String = ""
    /// Last thing Miku said.
    var lastReply: String = ""

    // MARK: Dictation
    //
    // Dictation is deliberately not part of the conversation: what is said here
    // is transcribed and stored, and Miku does not answer it.

    /// Id of the open session, or the last one that closed.
    var dictationSessionId: String?
    /// Transcribed pieces as they arrive, oldest first.
    private(set) var dictationSegments: [String] = []
    /// True while transcription is running behind the speaker.
    var dictationLagging: Bool = false

    var dictationText: String {
        dictationSegments.joined(separator: " ")
    }

    func beginDictation(sessionId: String) {
        dictationSessionId = sessionId
        dictationSegments.removeAll()
        dictationLagging = false
    }

    func addDictationSegment(_ text: String) {
        dictationSegments.append(text)
        dictationLagging = false
    }


    // MARK: Console
    //
    // What the Console needs beyond the menu bar: the live meter, the turns with the
    // tools Miku actually called, and whatever is waiting for a yes or a no.

    /// 0…1 microphone input level. Feeds the graduated ring, which the design treats
    /// as a real meter rather than an ornament.
    var nivelEntrada: Double = 0
    /// How much of the open session window has elapsed, 0…1.
    var progresoSesion: Double = 0
    /// Seconds the session has been open, for the capsule subtitle.
    var segundosSesion: Int = 0

    /// The exchange, newest last. Tool chips are the transparency mechanism: they show
    /// what Miku really called, not what she says she called.
    private(set) var turnos: [Turno] = []
    /// An action waiting for approval, shown on the cover and as a dialog.
    var confirmacion: ConfirmacionPendiente?
    /// Notes that hang under `Notas` in the sidebar.
    var notasRecientes: [NotaEnlace] = []
    /// Drives the single badge the sidebar is allowed to show.
    var avisosActividad: Int = 0
    /// Which brain answered last. Local is the happy path — the cloud is the
    /// exception, so the label states it plainly rather than selling it.
    var usaNube: Bool = false

    func addTurno(_ turno: Turno) {
        turnos.append(turno)
        if turnos.count > 200 { turnos.removeFirst(turnos.count - 200) }
    }

    /// Attach a tool to the turn Miku is currently building.
    func addHerramienta(_ nombre: String) {
        guard let ultimo = turnos.indices.last, turnos[ultimo].deMiku else { return }
        if !turnos[ultimo].herramientas.contains(nombre) {
            turnos[ultimo].herramientas.append(nombre)
        }
    }

    /// Rolling log of the most recent backend events, for the Advanced section.
    private(set) var eventLog: [String] = []

    func log(_ line: String) {
        eventLog.append(line)
        if eventLog.count > 200 { eventLog.removeFirst(eventLog.count - 200) }
    }
}
