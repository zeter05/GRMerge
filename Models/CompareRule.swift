import Foundation


/// Esclude file o cartelle dal confronto
/// Implementato come enum con associated values — come sealed class Kotlin
enum ExcludeRule: Identifiable, Codable, Hashable {
    case exactName(String)        // es. ".DS_Store", "Thumbs.db"
    case fileExtension(String)    // es. "log", "tmp", "cache"
    case directoryName(String)    // es. "node_modules", ".git", "build"
    case glob(String)             // es. "*.generated.swift"

    var id: String { description }

    var description: String {
        switch self {
        case .exactName(let n):      return "Nome: \(n)"
        case .fileExtension(let e):  return "Estensione: .\(e)"
        case .directoryName(let d):  return "Cartella: \(d)/"
        case .glob(let g):           return "Pattern: \(g)"
        }
    }

    /// Ritorna true se il nodo va escluso
    func matches(_ url: URL, isDirectory: Bool) -> Bool {
        let name = url.lastPathComponent
        switch self {
        case .exactName(let n):
            return name == n
        case .fileExtension(let e):
            return !isDirectory && url.pathExtension.lowercased() == e.lowercased()
        case .directoryName(let d):
            return isDirectory && name == d
        case .glob(let pattern):
            return fnmatch(pattern, name, 0) == 0  // fnmatch = glob POSIX nativo
        }
    }
}


/// Trasforma il contenuto di un file prima del confronto
enum NormalizeRule: Identifiable, Codable, Hashable {
    case ignoreLineEndings        // \r\n → \n
    case ignoreTrailingWhitespace // spazi a fine riga
    case ignoreAllWhitespace      // tutti gli spazi e tab
    case ignoreBlankLines         // righe vuote
    case ignoreComments           // commenti // e /* */
    case lowercased               // case insensitive

    var id: String { description }

    var description: String {
        switch self {
        case .ignoreLineEndings:        return "Ignora line endings (\\r\\n)"
        case .ignoreTrailingWhitespace: return "Ignora spazi a fine riga"
        case .ignoreAllWhitespace:      return "Ignora tutti gli spazi"
        case .ignoreBlankLines:         return "Ignora righe vuote"
        case .ignoreComments:           return "Ignora commenti (// e /* */)"
        case .lowercased:               return "Case insensitive"
        }
    }

    /// Applica la normalizzazione a una stringa
    func apply(to content: String) -> String {
        switch self {
        case .ignoreLineEndings:
            return content.replacingOccurrences(of: "\r\n", with: "\n")
                          .replacingOccurrences(of: "\r", with: "\n")

        case .ignoreTrailingWhitespace:
            return content.components(separatedBy: "\n")
                .map { $0.replacingOccurrences(of: "\\s+$",
                       with: "", options: .regularExpression) }
                .joined(separator: "\n")

        case .ignoreAllWhitespace:
            return content.components(separatedBy: .whitespacesAndNewlines)
                .filter { !$0.isEmpty }
                .joined()

        case .ignoreBlankLines:
            return content.components(separatedBy: "\n")
                .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
                .joined(separator: "\n")

        case .ignoreComments:
            // Rimuove // single line e /* */ multiline
            var result = content
            // /* ... */
            result = result.replacingOccurrences(
                of: "/\\*[\\s\\S]*?\\*/",
                with: "", options: .regularExpression)
            // // fino a fine riga
            result = result.replacingOccurrences(
                of: "//[^\n]*",
                with: "", options: .regularExpression)
            return result

        case .lowercased:
            return content.lowercased()
        }
    }
}


struct RulePreset {
    let name: String
    let excludeRules: [ExcludeRule]
    let normalizeRules: [NormalizeRule]

    static let defaults: [RulePreset] = [
        RulePreset(
            name: "Progetto Swift/Xcode",
            excludeRules: [
                .directoryName(".git"),
                .directoryName("DerivedData"),
                .directoryName(".build"),
                .exactName(".DS_Store"),
                .fileExtension("o"),
                .fileExtension("d")
            ],
            normalizeRules: [.ignoreLineEndings, .ignoreTrailingWhitespace]
        ),
        RulePreset(
            name: "Progetto Node.js",
            excludeRules: [
                .directoryName("node_modules"),
                .directoryName(".git"),
                .directoryName("dist"),
                .directoryName("build"),
                .exactName(".DS_Store"),
                .fileExtension("log")
            ],
            normalizeRules: [.ignoreLineEndings, .ignoreTrailingWhitespace]
        ),
        RulePreset(
            name: "Solo testo",
            excludeRules: [.exactName(".DS_Store")],
            normalizeRules: [
                .ignoreLineEndings,
                .ignoreTrailingWhitespace,
                .ignoreBlankLines
            ]
        )
    ]
}
