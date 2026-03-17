import SwiftUI
import Combine

@MainActor
class CompareViewModel: ObservableObject {

    @Published var leftPath: URL?
    @Published var rightPath: URL?
    @Published var results: [FileNode] = []
    @Published var isScanning: Bool = false
    @Published var errorMessage: String?
    @Published var statusFilter: CompareStatus? = nil

    // Progresso dettagliato — nuovo
    @Published var scanPhase: ScanPhase = .idle
    @Published var progressA: ScanProgress?
    @Published var progressB: ScanProgress?
    @Published var compareProgress: Double = 0.0   // 0.0 → 1.0
    
    @Published var summaryA: ScanSummary?
    @Published var summaryB: ScanSummary?
    @Published var totalDuration: TimeInterval = 0

    var excludeRules: [ExcludeRule] = [
        .exactName(".DS_Store"),
        .directoryName(".git")
    ]
    var normalizeRules: [NormalizeRule] = [
        .ignoreLineEndings
    ]

    var canCompare: Bool { leftPath != nil && rightPath != nil }

    // Progresso corrente da mostrare nella UI
    var currentProgress: Double {
        switch scanPhase {
        case .idle:       return 0
        case .scanningA:  return (progressA?.fraction ?? 0) * 0.4      // 0% → 40%
        case .scanningB:  return 0.4 + (progressB?.fraction ?? 0) * 0.4 // 40% → 80%
        case .comparing:  return 0.8 + compareProgress * 0.2            // 80% → 100%
        case .done:       return 1.0
        }
    }

    var currentProgressLabel: String {
        switch scanPhase {
        case .idle:      return ""
        case .scanningA: return "Scansione A: \(progressA?.percentage ?? 0)% — \(progressA?.description ?? "")"
        case .scanningB: return "Scansione B: \(progressB?.percentage ?? 0)% — \(progressB?.description ?? "")"
        case .comparing: return "Confronto in corso..."
        case .done:      return "Completato"
        }
    }

    var filteredResults: [FileNode] {
        guard let filter = statusFilter else { return results }
        return results.compactMap { filterNode($0, status: filter) }
    }


    func startComparison() async {
        guard let left = leftPath, let right = rightPath else { return }

        isScanning = true
        errorMessage = nil
        results = []
        progressA = nil
        progressB = nil
        summaryA = nil
        summaryB = nil
        compareProgress = 0

        let startTime = Date()

        do {
            var scanner = FileScanner()
            scanner.excludeRules = excludeRules

            scanPhase = .scanningA
            let resultA = try await scanner.scan(directory: left) { [weak self] progress in
                Task { @MainActor [weak self] in self?.progressA = progress }
            }
            summaryA = resultA.summary

            scanPhase = .scanningB
            let resultB = try await scanner.scan(directory: right) { [weak self] progress in
                Task { @MainActor [weak self] in self?.progressB = progress }
            }
            summaryB = resultB.summary

            scanPhase = .comparing
            compareProgress = 0.5
            var comparator = FileComparator()
            comparator.normalizeRules = normalizeRules
            results = comparator.compare(left: resultA.nodes, right: resultB.nodes)

            totalDuration = Date().timeIntervalSince(startTime)
            scanPhase = .done

        } catch {
            errorMessage = "Errore: \(error.localizedDescription)"
            scanPhase = .idle
        }

        isScanning = false
    }

    // MARK: - Stats

    func countByStatus(_ status: CompareStatus) -> Int {
        countInNodes(results, status: status)
    }

    private func countInNodes(_ nodes: [FileNode], status: CompareStatus) -> Int {
        nodes.reduce(0) { total, node in
            let selfCount  = (!node.isDirectory && node.status == status) ? 1 : 0
            let childCount = countInNodes(node.children ?? [], status: status)
            return total + selfCount + childCount
        }
    }


    private func filterNode(_ node: FileNode, status: CompareStatus) -> FileNode? {
        if node.isDirectory {
            let filteredChildren = (node.children ?? []).compactMap {
                filterNode($0, status: status)
            }
            guard !filteredChildren.isEmpty else { return nil }
            var copy = node
            copy.children = filteredChildren
            return copy
        } else {
            return node.status == status ? node : nil
        }
    }


    func exportCSV() -> String {
        var lines = ["Path,Status,Size,IsDirectory"]
        appendCSV(nodes: results, lines: &lines)
        return lines.joined(separator: "\n")
    }

    private func appendCSV(nodes: [FileNode], lines: inout [String]) {
        for node in nodes {
            let line = "\"\(node.path.path)\",\(node.status),\(node.size),\(node.isDirectory)"
            lines.append(line)
            if let children = node.children {
                appendCSV(nodes: children, lines: &lines)
            }
        }
    }

    func exportJSON() -> String {
        let flat = flattenNodes(results)
        let dicts = flat.map { node in
            [
                "path":        node.path.path,
                "name":        node.name,
                "status":      "\(node.status)",
                "size":        "\(node.size)",
                "isDirectory": "\(node.isDirectory)"
            ]
        }
        guard let data = try? JSONSerialization.data(
            withJSONObject: dicts, options: .prettyPrinted),
              let json = String(data: data, encoding: .utf8) else { return "[]" }
        return json
    }

    private func flattenNodes(_ nodes: [FileNode]) -> [FileNode] {
        nodes.flatMap { node -> [FileNode] in
            [node] + flattenNodes(node.children ?? [])
        }
    }
}


enum ScanPhase {
    case idle
    case scanningA
    case scanningB
    case comparing
    case done
}
