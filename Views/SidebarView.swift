import SwiftUI

struct SidebarView: View {
    @ObservedObject var vm: CompareViewModel

    var body: some View {
        VStack(spacing: 0) {

            // Header fisso
            VStack(alignment: .leading, spacing: 12) {
                Text("GRMerge")
                    .font(.title2)
                    .fontWeight(.semibold)

                FolderPickerRow(
                    label: "Cartella A",
                    url: vm.leftPath,
                    color: .blue
                ) { url in vm.leftPath = url }

                FolderPickerRow(
                    label: "Cartella B",
                    url: vm.rightPath,
                    color: .red
                ) { url in vm.rightPath = url }

                Button {
                    Task { await vm.startComparison() }
                } label: {
                    HStack {
                        if vm.isScanning {
                            ProgressView().controlSize(.small)
                        } else {
                            Image(systemName: "arrow.triangle.2.circlepath")
                        }
                        Text(vm.isScanning ? "Scansione..." : "Confronta")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!vm.canCompare || vm.isScanning)

                if !vm.currentProgressLabel.isEmpty {
                    Text(vm.currentProgressLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                if let error = vm.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .lineLimit(3)
                }
            }
            .padding()

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    SidebarSection(title: "Regole", icon: "slider.horizontal.3") {
                        RulesView(vm: vm)
                    }
                    Divider().padding(.horizontal)
                    SidebarSection(title: "Legenda", icon: "info.circle") {
                        LegendView()
                    }
                }
            }
        }
        .frame(minWidth: 260, maxWidth: 320)
    }
}


struct FolderPickerRow: View {
    let label: String
    let url: URL?
    let color: Color
    let onSelect: (URL) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {

            // Label + bottone scegli
            HStack {
                Image(systemName: "folder.fill")
                    .foregroundStyle(color)
                    .font(.caption)
                Text(label)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Scegli") {
                    let panel = NSOpenPanel()
                    panel.canChooseFiles = false
                    panel.canChooseDirectories = true
                    panel.allowsMultipleSelection = false
                    if panel.runModal() == .OK, let chosen = panel.url {
                        onSelect(chosen)
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.mini)
            }

            // Path a breadcrumb oppure placeholder
            if let url {
                PathBreadcrumb(url: url, color: color)
            } else {
                Text("Nessuna cartella selezionata")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .italic()
                    .padding(.vertical, 4)
            }
        }
        .padding(10)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
    }
}


struct PathBreadcrumb: View {
    let url: URL
    let color: Color

    /// Spezza il path in componenti, salta la root "/"
    private var components: [String] {
        url.pathComponents.filter { $0 != "/" }
    }

    var body: some View {
        // Wrap automatico dei componenti — come flex-wrap in CSS
        FlowLayout(spacing: 2) {
            ForEach(Array(components.enumerated()), id: \.offset) { index, component in
                HStack(spacing: 2) {
                    // Separatore — tranne il primo
                    if index > 0 {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 8))
                            .foregroundStyle(.tertiary)
                    }

                    // Ultimo componente = cartella selezionata → evidenziato
                    let isLast = index == components.count - 1
                    Text(component)
                        .font(.caption2.monospaced())
                        .foregroundStyle(isLast ? color : .secondary)
                        .fontWeight(isLast ? .semibold : .regular)
                        .padding(.horizontal, isLast ? 5 : 2)
                        .padding(.vertical, isLast ? 2 : 0)
                        .background(
                            isLast ? color.opacity(0.12) : Color.clear,
                            in: RoundedRectangle(cornerRadius: 3)
                        )
                }
            }
        }
    }
}


struct FlowLayout: Layout {
    var spacing: CGFloat = 4

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: ProposedViewSize(bounds.size), subviews: subviews)
        for (index, frame) in result.frames.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                proposal: ProposedViewSize(frame.size)
            )
        }
    }

    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, frames: [CGRect]) {
        let maxWidth = proposal.width ?? .infinity
        var frames: [CGRect] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var totalHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            // Vai a capo se non c'è spazio
            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            frames.append(CGRect(origin: CGPoint(x: currentX, y: currentY), size: size))
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
            totalHeight = currentY + lineHeight
        }

        return (CGSize(width: maxWidth, height: totalHeight), frames)
    }
}


struct SidebarSection<Content: View>: View {
    let title: String
    let icon: String
    @State private var expanded = true
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { expanded.toggle() }
            } label: {
                HStack {
                    Image(systemName: icon)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 14)
                    Text(title)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Image(systemName: expanded ? "chevron.down" : "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if expanded {
                content()
                    .padding(.horizontal)
                    .padding(.bottom, 12)
            }
        }
    }
}
