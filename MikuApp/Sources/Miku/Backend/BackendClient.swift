import Foundation

/// Events the backend pushes to us, reduced to the ones the app acts on.
enum BackendEvent {
    case connected
    case disconnected
    /// Backend told us to start capturing microphone audio.
    case startMic
    case conversationStarted
    case conversationEnded
    /// The user's speech, as transcribed by the backend.
    case transcript(String)
    /// A chunk of synthesized speech plus the text it corresponds to.
    case audio(Data, text: String)
    /// All audio for this turn has been generated.
    case synthComplete
    /// A tool call changed state (running / completed / error).
    case toolStatus(name: String, status: String)
    /// A dictation session opened; audio now goes to the transcript, not to Miku.
    case dictationStarted(sessionId: String, title: String)
    /// One transcribed piece of the dictation, in the order it was spoken.
    case dictationSegment(text: String, start: Double)
    /// The session closed and its queue drained. `sessionId` is nil if there was none.
    case dictationStopped(sessionId: String?, segments: Int, text: String)
    /// Transcription is falling behind the speaker. Nothing is lost, it just lags.
    case dictationBacklog(Int)
    case status(String)
    case error(String)
}

/// WebSocket client for the Python backend's `/client-ws` endpoint.
///
/// The backend drives the conversation; this client forwards microphone audio up
/// and plays synthesized speech coming down. It reconnects on its own.
final class BackendClient: NSObject, @unchecked Sendable {
    private let url: URL
    private var task: URLSessionWebSocketTask?
    private lazy var session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
    private var reconnectDelay: TimeInterval = 1
    private var isStopping = false

    /// Called on the main actor for every event worth reacting to.
    var onEvent: (@MainActor (BackendEvent) -> Void)?

    init(url: URL = URL(string: "ws://localhost:12393/client-ws")!) {
        self.url = url
        super.init()
    }

    // MARK: - Lifecycle

    func connect() {
        isStopping = false
        task?.cancel(with: .goingAway, reason: nil)
        let task = session.webSocketTask(with: url)
        self.task = task
        task.resume()
        receiveLoop()
    }

    func stop() {
        isStopping = true
        task?.cancel(with: .goingAway, reason: nil)
        task = nil
    }

    private func scheduleReconnect() {
        guard !isStopping else { return }
        let delay = reconnectDelay
        reconnectDelay = min(reconnectDelay * 2, 15)
        DispatchQueue.global().asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.connect()
        }
    }

    // MARK: - Receiving

    private func receiveLoop() {
        task?.receive { [weak self] result in
            guard let self else { return }
            switch result {
            case .failure:
                self.emit(.disconnected)
                self.scheduleReconnect()
            case .success(let message):
                switch message {
                case .string(let text): self.handle(text)
                case .data(let data): self.handle(String(decoding: data, as: UTF8.self))
                @unknown default: break
                }
                self.receiveLoop()
            }
        }
    }

    private func handle(_ raw: String) {
        guard let data = raw.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = object["type"] as? String
        else { return }

        switch type {
        case "set-model-and-conf":
            reconnectDelay = 1
            emit(.connected)

        case "control":
            switch object["text"] as? String {
            case "start-mic": emit(.startMic)
            case "conversation-chain-start": emit(.conversationStarted)
            case "conversation-chain-end": emit(.conversationEnded)
            default: break
            }

        case "user-input-transcription":
            emit(.transcript(object["text"] as? String ?? ""))

        case "audio":
            let text = (object["display_text"] as? [String: Any])?["text"] as? String ?? ""
            if let base64 = object["audio"] as? String, let audio = Data(base64Encoded: base64) {
                emit(.audio(audio, text: text))
            }

        case "backend-synth-complete":
            emit(.synthComplete)

        case "dictation-started":
            emit(.dictationStarted(
                sessionId: object["session_id"] as? String ?? "",
                title: object["title"] as? String ?? ""
            ))

        case "dictation-segment":
            emit(.dictationSegment(
                text: object["text"] as? String ?? "",
                start: object["start"] as? Double ?? 0
            ))

        case "dictation-stopped":
            emit(.dictationStopped(
                sessionId: object["session_id"] as? String,
                segments: object["segment_count"] as? Int ?? 0,
                text: object["text"] as? String ?? ""
            ))

        case "dictation-backlog":
            emit(.dictationBacklog(object["pending"] as? Int ?? 0))

        case "tool_call_status":
            emit(.toolStatus(name: object["tool_name"] as? String ?? "?",
                             status: object["status"] as? String ?? "?"))

        case "full-text":
            emit(.status(object["text"] as? String ?? ""))

        case "error":
            emit(.error(object["message"] as? String ?? "error"))

        default:
            break
        }
    }

    private func emit(_ event: BackendEvent) {
        Task { @MainActor [onEvent] in onEvent?(event) }
    }

    // MARK: - Sending

    private func send(_ payload: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: payload),
              let text = String(data: data, encoding: .utf8) else { return }
        task?.send(.string(text)) { _ in }
    }

    func sendText(_ text: String) {
        send(["type": "text-input", "text": text])
    }

    /// Stream a chunk of 16 kHz mono samples to the backend.
    func sendMicChunk(_ samples: [Float]) {
        send(["type": "mic-audio-data", "audio": samples])
    }

    /// Tell the backend the utterance is over and it should start transcribing.
    func sendMicEnd() {
        send(["type": "mic-audio-end"])
    }

    // MARK: Dictation
    //
    // A separate channel on purpose: dictation audio must never reach the
    // conversation buffer, or Miku would answer everything being dictated.

    func startDictation(title: String) {
        send(["type": "start-dictation", "text": title, "action": "mic"])
    }

    func sendDictationChunk(_ samples: [Float]) {
        send(["type": "dictation-audio-data", "audio": samples])
    }

    func stopDictation() {
        send(["type": "stop-dictation"])
    }

    func sendPlaybackComplete() {
        send(["type": "frontend-playback-complete"])
    }

    func sendInterrupt(heard: String) {
        send(["type": "interrupt-signal", "text": heard])
    }
}

extension BackendClient: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask,
                    didOpenWithProtocol protocol: String?) {
        reconnectDelay = 1
    }

    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask,
                    didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        emit(.disconnected)
        scheduleReconnect()
    }
}
