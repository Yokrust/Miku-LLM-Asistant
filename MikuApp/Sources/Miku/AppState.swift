import Foundation
import Observation

/// What Miku is doing right now. Drives the menu bar icon and the status line.
enum MikuStatus: Equatable {
    case disconnected
    case idle
    case listening
    case thinking
    case speaking
    case dictating
    case muted

    var label: String {
        switch self {
        case .disconnected: return "Sin conexión con el motor"
        case .idle: return "Lista, di «Miku»"
        case .listening: return "Escuchando…"
        case .thinking: return "Pensando…"
        case .speaking: return "Hablando…"
        case .dictating: return "Anotando lo que dices…"
        case .muted: return "Silenciada"
        }
    }

    /// SF Symbol for the menu bar. Template-rendered, so it must read in monochrome.
    var symbol: String {
        switch self {
        case .disconnected: return "exclamationmark.triangle"
        case .idle: return "circle"
        case .listening: return "circle.circle.fill"
        case .thinking: return "ellipsis.circle"
        case .speaking: return "waveform.circle.fill"
        case .dictating: return "text.badge.plus"
        case .muted: return "circle.slash"
        }
    }
}

/// Shared, observable application state.
@MainActor
@Observable
final class AppState {
    var status: MikuStatus = .disconnected
    /// User-facing switch for the wake word / mic. M3 has no wake word yet, so this
    /// simply gates whether we stream microphone audio at all.
    var listeningEnabled: Bool = false
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

    /// Rolling log of the most recent backend events, for the Advanced section.
    private(set) var eventLog: [String] = []

    func log(_ line: String) {
        eventLog.append(line)
        if eventLog.count > 200 { eventLog.removeFirst(eventLog.count - 200) }
    }
}
