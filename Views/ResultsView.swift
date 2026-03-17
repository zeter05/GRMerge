import SwiftUI
import UniformTypeIdentifiers

struct ResultsView: View {
    @ObservedObject var vm: CompareViewModel

    var body: some View {
        VStack(spacing: 0) {
            if !vm.isScanning {
                filterBar
            }

            Group {
                if vm.isScanning {
                    ScanProgressView(vm: vm)
                } else if vm.filteredResults.isEmpty {
                    ContentUnavailableView(
                        "Nessun risultato",
                        systemImage: "folder.badge.questionmark",
                        description: Text("Seleziona due cartelle e premi Confronta")
                    )
                } else {
                    treeView
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Footer — visibile solo dopo la scansione
            if vm.scanPhase == .done {
                ResultsFooterView(vm: vm)
            }
        }
        .navigationTitle("Risultati")
    }

    private var treeView: some View {
        List(vm.filteredResults, children: \.childrenIfAny) { node in  // ← filteredResults
            FileRowView(node: node)
        }
        .listStyle(.inset)
    }


    private var filterBar: some View {
        HStack(spacing: 6) {
            filterButton(nil,           label: "Tutti")
            filterButton(.modified,     label: "~")
            filterButton(.onlyInLeft,   label: "←")
            filterButton(.onlyInRight,  label: "→")
            filterButton(.identical,    label: "=")

            Spacer()

            Menu {
                Button("Esporta CSV")  { exportFile(content: vm.exportCSV(),  ext: "csv")  }
                Button("Esporta JSON") { exportFile(content: vm.exportJSON(), ext: "json") }
            } label: {
                Image(systemName: "square.and.arrow.up")
            }
            .menuStyle(.borderlessButton)
            .disabled(vm.results.isEmpty)
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
        .background(.bar)  // ← sfondo nativo macOS per le toolbar
    }


    private func filterButton(_ status: CompareStatus?, label: String) -> some View {
        let isActive = vm.statusFilter == status
        let color: Color = switch status {
            case .modified:    .orange
            case .onlyInLeft:  .blue
            case .onlyInRight: .red
            case .identical:   .secondary
            case nil:          .primary
        }
        let count = status.map { vm.countByStatus($0) } ?? vm.results.count

        return Button {
            vm.statusFilter = isActive ? nil : status
        } label: {
            HStack(spacing: 3) {
                Text(label).font(.caption.monospaced())
                Text("\(count)").font(.caption)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                isActive ? color.opacity(0.15) : Color.clear,
                in: RoundedRectangle(cornerRadius: 6)
            )
            .foregroundStyle(isActive ? color : .secondary)
        }
        .buttonStyle(.plain)
    }


    private func exportFile(content: String, ext: String) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = ext == "csv" ? [.commaSeparatedText] : [.json]
        panel.nameFieldStringValue = "GRMerge-results.\(ext)"
        if panel.runModal() == .OK, let url = panel.url {
            try? content.write(to: url, atomically: true, encoding: .utf8)
        }
    }
}


extension FileNode {
    var childrenIfAny: [FileNode]? {
        guard isDirectory else { return nil }
        switch status {
        case .identical:
            return nil
        case .modified:
            return children ?? []
        case .onlyInLeft, .onlyInRight:
            return children?.isEmpty == false ? children : nil
        }
    }
}
