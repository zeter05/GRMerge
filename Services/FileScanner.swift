import Foundation

struct FileScanner {

    private let fileManager = FileManager.default
    var excludeRules: [ExcludeRule] = []

    /// Ritorna sia l'albero che il summary finale
    func scan(
        directory: URL,
        onProgress: @escaping @Sendable (ScanProgress) -> Void
    ) async throws -> (nodes: [FileNode], summary: ScanSummary) {
        return try await Task.detached(priority: .userInitiated) {
            let startTime = Date()
            let total = self.countItems(in: directory)
            var scanned = 0
            var fileCount = 0
            var dirCount = 0
            var totalSize: Int64 = 0
            var extensionCounts: [String: Int] = [:]

            let nodes = try self.scanDirectory(
                directory,
                total: total,
                scanned: &scanned,
                fileCount: &fileCount,
                dirCount: &dirCount,
                totalSize: &totalSize,
                extensionCounts: &extensionCounts,
                onProgress: onProgress
            )

            let summary = ScanSummary(
                totalFiles: fileCount,
                totalDirectories: dirCount,
                totalSize: totalSize,
                duration: Date().timeIntervalSince(startTime),
                extensionCounts: extensionCounts
            )

            return (nodes, summary)
        }.value
    }

    private func countItems(in url: URL) -> Int {
        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) else { return 0 }
        var count = 0
        for _ in enumerator { count += 1 }
        return count
    }

    private func scanDirectory(
        _ url: URL,
        total: Int,
        scanned: inout Int,
        fileCount: inout Int,
        dirCount: inout Int,
        totalSize: inout Int64,
        extensionCounts: inout [String: Int],
        onProgress: @escaping @Sendable (ScanProgress) -> Void
    ) throws -> [FileNode] {
        var nodes: [FileNode] = []

        let resourceKeys: [URLResourceKey] = [.isDirectoryKey, .fileSizeKey]
        let contents = try fileManager.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: resourceKeys,
            options: [.skipsHiddenFiles]
        )

        let sorted = contents.sorted { a, b in
            let aIsDir = (try? a.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
            let bIsDir = (try? b.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
            if aIsDir != bIsDir { return aIsDir }
            return a.lastPathComponent < b.lastPathComponent
        }

        for itemURL in sorted {
            let resourceValues = try itemURL.resourceValues(forKeys: Set(resourceKeys))
            let isDirectory = resourceValues.isDirectory ?? false

            let excluded = excludeRules.contains { $0.matches(itemURL, isDirectory: isDirectory) }
            if excluded { continue }

            scanned += 1

            if scanned % 50 == 0 || scanned == total {
                let progress = ScanProgress(
                    scanned: scanned,
                    total: total,
                    currentFile: itemURL.lastPathComponent,
                    currentDirectory: url.lastPathComponent
                )
                onProgress(progress)
            }

            let size = Int64(resourceValues.fileSize ?? 0)

            if isDirectory {
                dirCount += 1
                let children = try scanDirectory(
                    itemURL,
                    total: total,
                    scanned: &scanned,
                    fileCount: &fileCount,
                    dirCount: &dirCount,
                    totalSize: &totalSize,
                    extensionCounts: &extensionCounts,
                    onProgress: onProgress
                )
                let node = FileNode(
                    name: itemURL.lastPathComponent,
                    path: itemURL,
                    isDirectory: true,
                    size: children.reduce(0) { $0 + $1.size },
                    children: children
                )
                nodes.append(node)
            } else {
                fileCount += 1
                totalSize += size
                // Conta estensioni
                let ext = itemURL.pathExtension.lowercased()
                extensionCounts[ext, default: 0] += 1

                nodes.append(FileNode(
                    name: itemURL.lastPathComponent,
                    path: itemURL,
                    isDirectory: false,
                    size: size
                ))
            }
        }

        return nodes
    }
}
