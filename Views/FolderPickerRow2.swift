import SwiftUI

struct FolderPickerRow2: View {
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
