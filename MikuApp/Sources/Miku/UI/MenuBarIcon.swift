import AppKit

/// The artwork for the status item.
///
/// The bar shows one thing: Miku. macOS draws status items as *template* images —
/// only the alpha channel survives, and the system repaints it black on a light bar,
/// white on a dark one, inverting it again while the menu is open — so the state
/// cannot ride on colour, and a second glyph beside the mark reads as a second app.
/// It rides on the mark itself instead (DISENO.md §9.7):
///
/// - **Reposo** — the mark.
/// - **Trabajando** — a core in the open lower half of the face. One treatment for
///   listening, thinking, speaking and taking notes: those turn over in seconds, and
///   an icon that changes shape three times per exchange is noise, not information.
/// - **Silenciada** — a slash across her, the direction SF Symbols slashes run.
/// - **Sin conexión** — the resting mark at reduced ink.
@MainActor
enum MenuBarIcon {
    /// Ink of the mark with no engine to talk to. Enough to see she is installed,
    /// not enough to read as running.
    private static let offlineInk: CGFloat = 0.35

    static func image(for status: MikuStatus) -> NSImage {
        if let cached = cache[status] { return cached }
        let made = make(status)
        cache[status] = made
        return made
    }

    private static var cache: [MikuStatus: NSImage] = [:]

    /// Generated from `Logos/SVGS` by `Scripts/make-icons.py`.
    private static func mark(named name: String) -> NSImage? {
        guard let image = NSImage(named: name) else { return nil }
        image.isTemplate = true
        return image
    }

    private static func make(_ status: MikuStatus) -> NSImage {
        guard let mark = mark(named: assetName(for: status)) else {
            return fallback(status)
        }
        // A copy per state, never the asset itself: `NSImage(named:)` hands back a
        // shared instance, and four states share the working mark — writing the
        // description straight onto it would leave VoiceOver reading whichever state
        // was built last.
        let ink: CGFloat = status == .disconnected ? offlineInk : 1
        let image = NSImage(size: mark.size, flipped: false) { rect in
            mark.draw(in: rect, from: .zero, operation: .sourceOver, fraction: ink)
            return true
        }
        image.isTemplate = true
        image.accessibilityDescription = "Miku — \(status.label)"
        return image
    }

    private static func assetName(for status: MikuStatus) -> String {
        switch status {
        case .muted:
            return "MenuBarIconMuted"
        case .listening, .awake, .thinking, .speaking, .dictating:
            // `.awake` shares the active mark on purpose: the open session is a
            // state the user should see, and there is no fourth icon for it yet.
            return "MenuBarIconActive"
        case .idle, .disconnected:
            return "MenuBarIcon"
        }
    }

    /// Without the .app bundle around it — `swift run`, say — there are no resources.
    /// Fall back to the state's SF Symbol so the item is still readable.
    private static func fallback(_ status: MikuStatus) -> NSImage {
        let glyph = NSImage(systemSymbolName: status.symbol, accessibilityDescription: status.label)
        glyph?.isTemplate = true
        return glyph ?? NSImage()
    }
}
