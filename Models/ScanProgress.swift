import Foundation

struct ScanProgress: Sendable {
    let scanned: Int
    let total: Int
    let currentFile: String
    let currentDirectory: String

    var fraction: Double {
        guard total > 0 else { return 0 }
        return min(Double(scanned) / Double(total), 1.0)
    }

    var percentage: Int { Int(fraction * 100) }
    var description: String { "\(currentDirectory)/\(currentFile)" }
}

/// Statistiche finali dopo la scansione completa
struct ScanSummary: Sendable {
    let totalFiles: Int
    let totalDirectories: Int
    let totalSize: Int64
    let duration: TimeInterval
    let extensionCounts: [String: Int]   // "jpg" → 42

    var formattedDuration: String {
        if duration < 1 { return String(format: "%.0f ms", duration * 1000) }
        if duration < 60 { return String(format: "%.1f s", duration) }
        let m = Int(duration / 60)
        let s = Int(duration) % 60
        return "\(m)m \(s)s"
    }

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }

    /// Top N estensioni per conteggio
    func topExtensions(limit: Int = 8) -> [(ext: String, count: Int)] {
        extensionCounts
            .sorted { $0.value > $1.value }
            .prefix(limit)
            .map { (ext: $0.key.isEmpty ? "nessuna" : $0.key, count: $0.value) }
    }
}
