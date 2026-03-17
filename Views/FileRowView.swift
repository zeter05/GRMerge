import SwiftUI

struct FileRowView: View {
    let node: FileNode

    var body: some View {
        HStack(spacing: 8) {

            // Icona status
            Image(systemName: node.status.icon)
                .foregroundStyle(node.status.color)
                .frame(width: 18)

            // Icona tipo (cartella o file)
            Image(systemName: iconName)
                .foregroundStyle(iconColor)
                .frame(width: 18)

            // Nome
            VStack(alignment: .leading, spacing: 2) {
                Text(node.name)
                    .fontWeight(node.isDirectory ? .semibold : .regular)
                    .foregroundStyle(node.status == .identical ? .secondary : .primary)

                // Sottotitolo: path relativo o dimensione
                if !node.isDirectory {
                    Text(formatSize(node.size))
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            // Badge status testuale
            statusBadge
        }
        .padding(.vertical, 2)
        .opacity(node.status == .identical ? 0.6 : 1.0)  // identici più sbiaditi
    }


    private var iconName: String {
        if node.isDirectory {
            return node.children?.isEmpty == true
                ? "folder.badge.minus"   // cartella vuota
                : "folder.fill"
        }
        return "doc.fill"
    }

    private var iconColor: Color {
        switch node.status {
        case .identical:   return .secondary
        case .modified:    return .orange
        case .onlyInLeft:  return .blue
        case .onlyInRight: return .red
        }
    }

    private var statusBadge: some View {
        let (label, color): (String, Color) = switch node.status {
        case .identical:   ("=", .secondary)
        case .modified:    ("~", .orange)
        case .onlyInLeft:  ("←", .blue)
        case .onlyInRight: ("→", .red)
        }

        return Text(label)
            .font(.caption.monospaced())
            .foregroundStyle(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 4))
    }

    private func formatSize(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }
}
