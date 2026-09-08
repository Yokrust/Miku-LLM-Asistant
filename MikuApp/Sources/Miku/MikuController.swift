import AVFoundation
import Foundation
import Observation

/// Wires the backend connection, the microphone and the speaker together, and
/// keeps `AppState` in sync so the UI only ever reads state.
///
/// Three ways in, and they never share the microphone at once:
///   push-to-talk  the button; the backend still checks whose voice it was
///   open mic      streams continuously, backend wakes on "Miku" from the owner
///   dictation     transcribed and filed, never answered
@MainActor
@Observable
final class MikuController {
    let state: AppState

    private let client = BackendClient()
    private let capture = AudioCapture()
    private let player = AudioPlayer()

    private var pendingSamples: [Float] = []
    private let chunkSize = 4096
    private var isTalking = false
    private var isDictating = false
    private var isListening = false

    init(state: AppState) {
        self.state = state
        wire()
    }

    private func wire() {
        client.onEvent = { [weak self] event in
            self?.handle(event)
        }
        capture.onSamples = { [weak self] samples in
            Task { @MainActor in self?.accumulate(samples) }
        }
        player.onStarted = { [weak self] in
            guard let self, self.state.status != .disconnected else { return }
            self.state.status = .speaking
        }
        player.onFinishedAll = { [weak self] in
            guard let self else { return }
            self.client.sendPlaybackComplete()
            if self.state.status == .speaking { self.state.status = self.restingStatus }
        }
    }

    private var restingStatus: MikuStatus {
        state.listeningEnabled ? .idle : .muted
    }

    func start() {
        client.connect()
    }

    // MARK: - Backend events

    private func handle(_ event: BackendEvent) {
        switch event {
        case .connected:
            state.status = restingStatus
            state.log("Conectada al motor")
        case .disconnected:
            state.status = .disconnected
            state.log("Sin conexión")
        case .startMic:
            break // The app decides when the microphone opens, not the backend.
        case .conversationStarted:
            state.status = .thinking
        case .conversationEnded:
            if state.status != .speaking { state.status = restingStatus }
        case .transcript(let text):
            state.lastTranscript = text
            state.log("Tú: \(text)")
        case .audio(let data, let text):
            if !text.isEmpty {
                state.lastReply = text
                state.log("Miku: \(text)")
            }
            player.enqueue(data)
        case .synthComplete:
            break
        case .toolStatus(let name, let status):
            state.log("Herramienta \(name) · \(status)")
        case .dictationStarted(let sessionId, let title):
            state.beginDictation(sessionId: sessionId)
            state.log("Dictado iniciado: \(title)")
        case .dictationSegment(let text, _):
            state.addDictationSegment(text)
        case .dictationStopped(let sessionId, let segments, _):
            state.dictationLagging = false
            if let sessionId {
                state.log("Dictado guardado (\(segments) fragmentos): \(sessionId)")
            }
            if state.status == .dictating { state.status = restingStatus }
        case .dictationBacklog:
            state.dictationLagging = true
        case .listeningStarted(let wakeWord, let voiceId, _):
            state.wakeWordActive = wakeWord
            state.voiceIdActive = voiceId
            state.log(voiceId
                ? "Micrófono abierto — despierta con «Miku», solo tu voz"
                : "Micrófono abierto — despierta con «Miku» (sin voz inscrita: cualquiera puede)")
        case .listeningStopped(let reason):
            state.wakeWordActive = false
            if !reason.isEmpty { state.log("Micrófono cerrado: \(reason)") }
        case .voiceGate(let feedback):
            state.lastGate = feedback
            // "No me hablaban" is the common case in a room full of people. It is
            // not worth a log line each time, and it is not worth telling the user.
            if feedback.outcome != "no me hablaban" {
                state.log(feedback.message)
            }
            if feedback.allowed {
                state.status = .thinking
            } else if isListening, state.status == .idle || state.status == .awake {
                state.status = state.listeningEnabled ? .idle : .muted
            }
        case .status(let text):
            state.log(text)
        case .error(let message):
            state.log("Error: \(message)")
        }
    }

    // MARK: - Talking

    /// Start streaming the microphone. Returns false if permission is missing.
    @discardableResult
    func beginTalking() -> Bool {
        guard !isTalking, state.status != .disconnected else { return false }
        guard AudioCapture.permissionGranted else {
            Task { _ = await AudioCapture.requestPermission() }
            return false
        }
        player.stopAll()
        pendingSamples.removeAll()
        do {
            try capture.start()
            isTalking = true
            state.status = .listening
            return true
        } catch {
            state.log("No se pudo abrir el micrófono: \(error.localizedDescription)")
            return false
        }
    }

    /// Stop streaming and let the backend transcribe what it received.
    func endTalking() {
        guard isTalking else { return }
        capture.stop()
        isTalking = false
        flushSamples()
        client.sendMicEnd()
        state.status = .thinking
    }

    func toggleTalking() {
        if isTalking { endTalking() } else { beginTalking() }
    }

    var talking: Bool { isTalking }

    // MARK: - Dictation

    var dictating: Bool { isDictating }

    /// Start writing down what is said instead of answering it.
    @discardableResult
    func startDictation(title: String = "") -> Bool {
        guard !isDictating, state.status != .disconnected else { return false }
        guard AudioCapture.permissionGranted else {
            Task { _ = await AudioCapture.requestPermission() }
            return false
        }
        if isTalking { endTalking() }
        player.stopAll()
        pendingSamples.removeAll()

        // Open the session before the microphone: audio that arrives before the
        // backend has a session to put it in is dropped.
        client.startDictation(title: title)
        do {
            try capture.start()
            isDictating = true
            state.status = .dictating
            return true
        } catch {
            client.stopDictation()
            state.log("No se pudo abrir el micrófono: \(error.localizedDescription)")
            return false
        }
    }

    /// Stop capturing and let the backend finish the queue before it closes.
    func stopDictation() {
        guard isDictating else { return }
        capture.stop()
        // Flush while the flag is still set: sendAudio() routes by it, and the tail
        // would otherwise land in the conversation buffer instead of the transcript.
        flushSamples()
        isDictating = false
        client.stopDictation()
        state.status = restingStatus
    }

    func toggleDictation() {
        if isDictating { stopDictation() } else { startDictation() }
    }

    // MARK: - Open mic

    var listening: Bool { isListening }

    /// Stream the microphone continuously and let the backend decide what was
    /// meant for Miku. Returns false if the microphone is unavailable.
    @discardableResult
    func startListening() -> Bool {
        guard !isListening, state.status != .disconnected else { return false }
        guard AudioCapture.permissionGranted else {
            Task { _ = await AudioCapture.requestPermission() }
            return false
        }
        if isTalking { endTalking() }
        if isDictating { stopDictation() }
        pendingSamples.removeAll()

        // Open the session before the microphone, as with dictation: audio that
        // arrives before the backend has somewhere to put it is dropped.
        client.startListening()
        do {
            try capture.start()
            isListening = true
            state.status = .idle
            return true
        } catch {
            client.stopListening()
            state.log("No se pudo abrir el micrófono: \(error.localizedDescription)")
            return false
        }
    }

    func stopListening() {
        guard isListening else { return }
        capture.stop()
        flushSamples()
        isListening = false
        state.wakeWordActive = false
        client.stopListening()
        if state.status == .idle || state.status == .awake { state.status = .muted }
    }

    private func accumulate(_ samples: [Float]) {
        pendingSamples.append(contentsOf: samples)
        while pendingSamples.count >= chunkSize {
            let chunk = Array(pendingSamples.prefix(chunkSize))
            pendingSamples.removeFirst(chunkSize)
            sendAudio(chunk)
        }
    }

    private func flushSamples() {
        guard !pendingSamples.isEmpty else { return }
        sendAudio(pendingSamples)
        pendingSamples.removeAll()
    }

    /// The same microphone feeds three destinations, never more than one at once.
    private func sendAudio(_ chunk: [Float]) {
        if isDictating {
            client.sendDictationChunk(chunk)
        } else if isListening {
            client.sendListeningChunk(chunk)
        } else {
            client.sendMicChunk(chunk)
        }
    }

    // MARK: - Text

    func send(text: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        player.stopAll()
        client.sendText(text)
        state.status = .thinking
    }

    /// The one switch the user actually thinks about: is the microphone open.
    /// Answer a pending action. The backend is the one that actually runs or drops it;
    /// the app only carries the verdict and clears the card.
    func responderConfirmacion(_ confirmacion: ConfirmacionPendiente, permitir: Bool) {
        client.sendConfirmacion(id: confirmacion.id, permitir: permitir)
        if state.confirmacion?.id == confirmacion.id { state.confirmacion = nil }
        state.log(permitir ? "Permitiste: \(confirmacion.comando)" : "Denegaste: \(confirmacion.comando)")
    }

    func setListening(_ enabled: Bool) {
        state.listeningEnabled = enabled
        if enabled {
            startListening()
            return
        }
        if isListening { stopListening() }
        if isTalking { endTalking() }
        if isDictating { stopDictation() }
        if state.status != .disconnected, state.status != .thinking, state.status != .speaking {
            state.status = restingStatus
        }
    }
}
