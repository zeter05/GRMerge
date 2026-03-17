// Models/ScanProgress.swift
import Foundation

struct ScanProgress: Sendable {
    let scanned: Int
    let total: Int
    let currentFile: String
    let currentDirectory: String

    /// Percentuale da 0.0 a 1.0
    var fraction: Double {
        guard total > 0 else { return 0 }
        return min(Double(scanned) / Double(total), 1.0)
    }

    /// Percentuale intera per la UI
    var percentage: Int {
        Int(fraction * 100)
    }

    var description: String {
        "\(currentDirectory)/\(currentFile)"
    }
}
