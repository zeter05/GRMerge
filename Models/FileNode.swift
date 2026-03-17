import Combine
import SwiftUI
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
