import SwiftUI
import Combine

// MARK: - Modello dati

/// Rappresenta un singolo file o cartella nell'albero
/// Equivalente a un DTO/record Java o a un'interface TypeScript
struct FileNode: Identifiable {
    let id = UUID()
    let name: String
    let path: URL
    let isDirectory: Bool
    let size: Int64
    var children: [FileNode]?
    var status: CompareStatus = .identical
}

/// Risultato del confronto per ogni nodo
/// Come un enum Java con valori
enum CompareStatus {
    case identical    // uguale in entrambe le cartelle
    case modified     // esiste in entrambe, ma diverso
    case onlyInLeft   // solo nella cartella A
    case onlyInRight  // solo nella cartella B

    var color: Color {
        switch self {
        case .identical:  return .primary
        case .modified:   return .orange
        case .onlyInLeft: return .blue
        case .onlyInRight: return .red
        }
    }

    var icon: String {
        switch self {
        case .identical:  return "equal"
        case .modified:   return "pencil.circle"
        case .onlyInLeft: return "arrow.left.circle"
        case .onlyInRight: return "arrow.right.circle"
        }
    }
}

// MARK: - ViewModel

/// Gestisce la logica dell'app e lo stato UI
/// Equivalente a un @Service Angular o un @Component Spring con stato
@MainActor
class CompareViewModel: ObservableObject {

    // @Published = come un BehaviorSubject RxJS o un Signal Angular
    // Ogni modifica causa il re-render automatico della UI
    @Published var leftPath: URL?
    @Published var rightPath: URL?
    @Published var results: [FileNode] = []
    @Published var isScanning: Bool = false
    @Published var errorMessage: String?

    var canCompare: Bool {
        leftPath != nil && rightPath != nil
    }

    /// Avvia il confronto tra le due cartelle
    /// async/await come in TypeScript, throws come checked exceptions Java
    func startComparison() async {
        guard let left = leftPath, let right = rightPath else { return }

        isScanning = true
        errorMessage = nil

        do {
            // TODO Fase 4: implementazione reale qui
            let mockResults = try await mockScan(left: left, right: right)
            results = mockResults
        } catch {
            errorMessage = "Errore durante la scansione: \(error.localizedDescription)"
        }

        isScanning = false
    }

    /// Dati finti per ora — sostituiti nella Fase 4
    private func mockScan(left: URL, right: URL) async throws -> [FileNode] {
        // Simula un ritardo di rete/disco (come un await Promise in TS)
        try await Task.sleep(nanoseconds: 1_000_000_000)
        return [
            FileNode(name: "docume2nto.pdf", path: left, isDirectory: false,
                     size: 1024, status: .identical),
            FileNode(name: "foto.jpg",      path: left, isDirectory: false,
                     size: 2048, status: .modified),
            FileNode(name: "solo_sinistra.txt", path: left, isDirectory: false,
                     size: 512,  status: .onlyInLeft),
        ]
    }
}

// MARK: - Viste SwiftUI

/// Vista principale dell'app
struct ContentView: View {

    // @StateObject = istanza il ViewModel UNA VOLTA e la mantiene viva
    // come un singleton per la durata della vista
    @StateObject private var vm = CompareViewModel()

    var body: some View {
        NavigationSplitView {
            // Pannello sinistro: selezione cartelle
            SidebarView(vm: vm)
                .frame(minWidth: 260)
        } detail: {
            // Pannello destro: risultati
            ResultsView(vm: vm)
        }
        .frame(minWidth: 800, minHeight: 500)
    }
}

// MARK: - Sidebar: selezione cartelle

struct SidebarView: View {
    @ObservedObject var vm: CompareViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {

            Text("FolderCompare")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.top, 20)

            // Selettore cartella A
            FolderPickerRow(
                label: "Cartella A",
                url: vm.leftPath,
                color: .blue
            ) { url in
                vm.leftPath = url
            }

            // Selettore cartella B
            FolderPickerRow(
                label: "Cartella B",
                url: vm.rightPath,
                color: .red
            ) { url in
                vm.rightPath = url
            }

            Divider()

            // Bottone confronta
            Button {
                // Task { } = come fire-and-forget async in TS
                Task { await vm.startComparison() }
            } label: {
                HStack {
                    if vm.isScanning {
                        ProgressView().controlSize(.small)
                    } else {
                        Image(systemName: "arrow.triangle.2.circlepath")
                    }
                    Text(vm.isScanning ? "Scansione..." : "Confronta")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!vm.canCompare || vm.isScanning)

            // Errori
            if let error = vm.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            Spacer()

            // Legenda
            LegendView()
        }
        .padding()
    }
}

// MARK: - Riga selettore cartella

struct FolderPickerRow: View {
    let label: String
    let url: URL?
    let color: Color
    let onSelect: (URL) -> Void   // closure = lambda Java / arrow function TS

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack {
                Image(systemName: "folder.fill")
                    .foregroundStyle(color)

                Text(url?.lastPathComponent ?? "Nessuna cartella")
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .foregroundStyle(url == nil ? .secondary : .primary)

                Spacer()

                Button("Scegli") {
                    // NSOpenPanel = il file picker nativo macOS
                    let panel = NSOpenPanel()
                    panel.canChooseFiles = false
                    panel.canChooseDirectories = true
                    panel.allowsMultipleSelection = false

                    if panel.runModal() == .OK, let chosen = panel.url {
                        onSelect(chosen)
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding(8)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
        }
    }
}

// MARK: - Legenda

struct LegendView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Legenda").font(.caption).foregroundStyle(.secondary)
            LegendRow(status: .identical,  label: "Identico")
            LegendRow(status: .modified,   label: "Modificato")
            LegendRow(status: .onlyInLeft, label: "Solo in A")
            LegendRow(status: .onlyInRight,label: "Solo in B")
        }
    }
}

struct LegendRow: View {
    let status: CompareStatus
    let label: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: status.icon)
                .foregroundStyle(status.color)
                .frame(width: 16)
            Text(label).font(.caption)
        }
    }
}

// MARK: - Pannello risultati

struct ResultsView: View {
    @ObservedObject var vm: CompareViewModel

    var body: some View {
        Group {
            if vm.results.isEmpty && !vm.isScanning {
                // Empty state — come un placeholder Angular
                ContentUnavailableView(
                    "Nessun risultato",
                    systemImage: "folder.badge.questionmark",
                    description: Text("Seleziona due cartelle e premi Confronta")
                )
            } else {
                // Lista risultati
                List(vm.results) { node in
                    FileRowView(node: node)
                }
                .listStyle(.inset)
            }
        }
        .navigationTitle("Risultati")
        .toolbar {
            // TODO Fase 6: filtri e ordinamento
            ToolbarItem(placement: .primaryAction) {
                Text("\(vm.results.count) elementi")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }
        }
    }
}

// MARK: - Riga singolo file

struct FileRowView: View {
    let node: FileNode

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: node.status.icon)
                .foregroundStyle(node.status.color)
                .frame(width: 20)

            Image(systemName: node.isDirectory ? "folder.fill" : "doc.fill")
                .foregroundStyle(.secondary)

            VStack(alignment: .leading) {
                Text(node.name)
                    .fontWeight(.medium)
                Text(node.path.path)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            if !node.isDirectory {
                Text(formatSize(node.size))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }

    private func formatSize(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }
}
