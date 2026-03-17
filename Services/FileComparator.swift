// Services/FileComparator.swift
import Foundation
import CryptoKit

struct FileComparator {

    var normalizeRules: [NormalizeRule] = []   // ← iniettate dal ViewModel

    func compare(left: [FileNode], right: [FileNode]) -> [FileNode] {
        let leftMap  = Dictionary(uniqueKeysWithValues: left.map  { ($0.name, $0) })
        let rightMap = Dictionary(uniqueKeysWithValues: right.map { ($0.name, $0) })
        let allNames = Set(leftMap.keys).union(Set(rightMap.keys)).sorted()

        return allNames.compactMap { name in
            switch (leftMap[name], rightMap[name]) {
            case (let l?, let r?): return compareNode(left: l, right: r)
            case (let l?, nil):    return withStatus(l, status: .onlyInLeft)
            case (nil, let r?):    return withStatus(r, status: .onlyInRight)
            default: return nil
            }
        }
    }

    private func compareNode(left: FileNode, right: FileNode) -> FileNode {
        if left.isDirectory && right.isDirectory {
            let leftChildren  = left.children  ?? []
            let rightChildren = right.children ?? []
            if leftChildren.isEmpty && rightChildren.isEmpty {
                var node = left; node.status = .identical; return node
            }
            let mergedChildren = compare(left: leftChildren, right: rightChildren)
            let hasChanges = mergedChildren.contains { $0.status != .identical }
            var node = left
            node.children = mergedChildren
            node.status = hasChanges ? .modified : .identical
            return node
        } else if !left.isDirectory && !right.isDirectory {
            let status: CompareStatus = filesAreEqual(left: left, right: right)
                ? .identical : .modified
            return withStatus(left, status: status)
        } else {
            return withStatus(left, status: .modified)
        }
    }

    private func filesAreEqual(left: FileNode, right: FileNode) -> Bool {
        // Se non ci sono regole di normalizzazione usiamo il confronto veloce per size
        if normalizeRules.isEmpty {
            guard left.size == right.size else { return false }
        }

        guard let hashLeft  = contentHash(url: left.path),
              let hashRight = contentHash(url: right.path) else { return false }
        return hashLeft == hashRight
    }

    /// Hash del contenuto dopo normalizzazione
    private func contentHash(url: URL) -> String? {
        guard let rawData = try? Data(contentsOf: url) else { return nil }

        // Se non ci sono regole, hash diretto sui bytes — più veloce
        if normalizeRules.isEmpty {
            return sha256(data: rawData)
        }

        // Prova a decodificare come testo (UTF-8 o Latin-1 come fallback)
        guard let text = String(data: rawData, encoding: .utf8)
                      ?? String(data: rawData, encoding: .isoLatin1) else {
            // File binario — hash diretto senza normalizzazione
            return sha256(data: rawData)
        }

        // Applica le regole in sequenza — come una pipeline
        let normalized = normalizeRules.reduce(text) { current, rule in
            rule.apply(to: current)
        }

        let normalizedData = normalized.data(using: .utf8) ?? rawData
        return sha256(data: normalizedData)
    }

    private func sha256(data: Data) -> String {
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    private func withStatus(_ node: FileNode, status: CompareStatus) -> FileNode {
        var copy = node
        if copy.isDirectory, let children = copy.children {
            copy.children = children.map { withStatus($0, status: status) }
        }
        copy.status = status
        return copy
    }
}
