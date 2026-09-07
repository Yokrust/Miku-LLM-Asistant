import AVFoundation
import Foundation

/// Plays the WAV chunks the backend streams back, one after another, and reports
/// when the queue has drained so we can acknowledge playback to the backend.
final class AudioPlayer: NSObject, @unchecked Sendable {
    private var queue: [Data] = []
    private var player: AVAudioPlayer?
    private let lock = NSLock()

    /// Called on the main actor when the last queued clip finishes.
    var onFinishedAll: (@MainActor () -> Void)?
    /// Called on the main actor when playback of any clip starts.
    var onStarted: (@MainActor () -> Void)?

    var isPlaying: Bool {
        lock.lock(); defer { lock.unlock() }
        return player?.isPlaying ?? false
    }

    func enqueue(_ wav: Data) {
        lock.lock()
        queue.append(wav)
        let idle = player == nil
        lock.unlock()
        if idle { playNext() }
    }

    /// Drop everything pending and stop immediately (used when the user interrupts).
    func stopAll() {
        lock.lock()
        queue.removeAll()
        player?.stop()
        player = nil
        lock.unlock()
    }

    private func playNext() {
        lock.lock()
        guard !queue.isEmpty else {
            player = nil
            lock.unlock()
            Task { @MainActor [onFinishedAll] in onFinishedAll?() }
            return
        }
        let data = queue.removeFirst()
        lock.unlock()

        do {
            let next = try AVAudioPlayer(data: data)
            next.delegate = self
            lock.lock(); player = next; lock.unlock()
            next.play()
            Task { @MainActor [onStarted] in onStarted?() }
        } catch {
            playNext()
        }
    }
}

extension AudioPlayer: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        playNext()
    }
}
