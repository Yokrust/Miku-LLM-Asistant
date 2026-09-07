import SwiftUI

/// The five sections of the settings window, in the order the design spec fixes.
enum SettingsSection: String, CaseIterable, Identifiable {
    case general = "General"
    case voice = "Voz"
    case ai = "IA"
    case permissions = "Permisos"
    case advanced = "Avanzado"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .general: return "gearshape"
        case .voice: return "waveform"
        case .ai: return "brain"
        case .permissions: return "lock.shield"
        case .advanced: return "wrench.and.screwdriver"
        }
    }
}

/// Structural shell for the settings window. The visual design lands in M6 from
/// the Figma file; this establishes the navigation and the real controls.
struct SettingsView: View {
    @Environment(MikuController.self) private var miku
    @State private var selection: SettingsSection? = .general

    var body: some View {
        NavigationSplitView {
            List(SettingsSection.allCases, selection: $selection) { section in
                Label(section.rawValue, systemImage: section.symbol).tag(section)
            }
            .navigationSplitViewColumnWidth(200)
        } detail: {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    switch selection ?? .general {
                    case .general: GeneralSection()
                    case .voice: VoiceSection()
                    case .ai: AISection()
                    case .permissions: PermissionsSection()
                    case .advanced: AdvancedSection(log: miku.state.eventLog)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(24)
            }
        }
        .navigationTitle("Ajustes de Miku")
        .frame(minWidth: 720, minHeight: 520)
    }
}

private struct GeneralSection: View {
    @Environment(MikuController.self) private var miku
    var body: some View {
        Group {
            Text("General").font(.title2).bold()
            Toggle("Escuchar la palabra de activación", isOn: Binding(
                get: { miku.state.listeningEnabled },
                set: { miku.setListening($0) }
            ))
            LabeledContent("Palabra de activación", value: "Miku")
            Text("La detección por palabra de activación llega en M4. Por ahora se habla desde la barra de menú.")
                .font(.footnote).foregroundStyle(.secondary)
        }
    }
}

private struct VoiceSection: View {
    var body: some View {
        Group {
            Text("Voz").font(.title2).bold()
            LabeledContent("Voz de Miku", value: "Español (México)")
            Text("La selección de voz y la prueba de sonido se conectan cuando el backend exponga las voces disponibles.")
                .font(.footnote).foregroundStyle(.secondary)
        }
    }
}

private struct AISection: View {
    var body: some View {
        Group {
            Text("IA").font(.title2).bold()
            LabeledContent("Cerebro", value: "Local · qwen2.5-miku")
            Text("El cambio a Claude y el campo para la clave de API (guardada en el Llavero) se implementan con el diseño de M6.")
                .font(.footnote).foregroundStyle(.secondary)
        }
    }
}

private struct PermissionsSection: View {
    @State private var micGranted = AudioCapture.permissionGranted
    var body: some View {
        Group {
            Text("Permisos").font(.title2).bold()
            LabeledContent("Micrófono") {
                HStack(spacing: 8) {
                    Text(micGranted ? "Concedido" : "No concedido")
                        .foregroundStyle(micGranted ? .green : .orange)
                    if !micGranted {
                        Button("Conceder") {
                            Task { micGranted = await AudioCapture.requestPermission() }
                        }
                    }
                }
            }
            Text("Miku necesita el micrófono para oírte. Accesibilidad y cámara se añaden en M6 y M7.")
                .font(.footnote).foregroundStyle(.secondary)
        }
    }
}

private struct AdvancedSection: View {
    let log: [String]
    var body: some View {
        Group {
            Text("Avanzado").font(.title2).bold()
            Text("Registro reciente").font(.headline)
            if log.isEmpty {
                Text("Sin eventos todavía.").font(.footnote).foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 3) {
                    ForEach(Array(log.suffix(40).enumerated()), id: \.offset) { _, line in
                        Text(line).font(.system(.caption, design: .monospaced))
                            .textSelection(.enabled)
                    }
                }
            }
        }
    }
}
