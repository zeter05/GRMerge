import SwiftUI

struct ResultsFooterView: View {
    @ObservedObject var vm: CompareViewModel

    var body: some View {
        VStack(spacing: 0) {
            Divider()

            VStack(alignment: .leading, spacing: 8) {

                // Riga 1 — statistiche principali
                HStack(spacing: 16) {
                    // Tempo totale
                    footerStat(
                        icon: "clock",
                        label: formattedDuration(vm.totalDuration)
                    )

                    Divider().frame(height: 12)

                    // File totali (somma A + B unici)
                    if let a = vm.summaryA, let b = vm.summaryB {
                        footerStat(
                            icon: "doc",
                            label: "\(a.totalFiles + b.totalFiles) file scansionati"
                        )
                        footerStat(
                            icon: "folder",
                            label: "\(a.totalDirectories + b.totalDirectories) cartelle"
                        )
                        footerStat(
                            icon: "internaldrive",
                            label: "\(a.formattedSize) + \(b.formattedSize)"
                        )
                    }

                    Spacer()

                    // Risultati confronto
                    HStack(spacing: 8) {
                        resultBadge(count: vm.countByStatus(.modified),    color: .orange, symbol: "~")
                        resultBadge(count: vm.countByStatus(.onlyInLeft),  color: .blue,   symbol: "←")
                        resultBadge(count: vm.countByStatus(.onlyInRight), color: .red,    symbol: "→")
                        resultBadge(count: vm.countByStatus(.identical),   color: .secondary, symbol: "=")
                    }
                }

                // Riga 2 — estensioni (solo se ci sono risultati)
                if let summary = vm.summaryA, !summary.extensionCounts.isEmpty {
                    extensionBar(summary: summary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.bar)
        }
    }

    // MARK: - Estensioni

    private func extensionBar(summary: ScanSummary) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                Image(systemName: "tag")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)

                ForEach(summary.topExtensions(), id: \.ext) { item in
                    HStack(spacing: 3) {
                        Text(".\(item.ext)")
                            .font(.caption2.monospaced())
                            .foregroundStyle(.secondary)
                        Text("\(item.count)")
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 4))
                }
            }
        }
    }

    // MARK: - Componenti

    private func footerStat(icon: String, label: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(.tertiary)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func resultBadge(count: Int, color: Color, symbol: String) -> some View {
        HStack(spacing: 3) {
            Text(symbol)
                .font(.caption2.monospaced())
                .foregroundStyle(color)
            Text("\(count)")
                .font(.caption2.monospacedDigit())
                .foregroundStyle(count > 0 ? color : Color.secondary)
        }
        .padding(.horizontal, 5)
        .padding(.vertical, 2)
        .background(
            count > 0 ? color.opacity(0.1) : Color.clear,
            in: RoundedRectangle(cornerRadius: 4)
        )
    }

    private func formattedDuration(_ t: TimeInterval) -> String {
        if t < 1   { return String(format: "%.0f ms", t * 1000) }
        if t < 60  { return String(format: "%.1f s", t) }
        return "\(Int(t/60))m \(Int(t)%60)s"
    }
}
