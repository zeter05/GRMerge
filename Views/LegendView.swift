import SwiftUI

struct LegendView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Legenda").font(.caption).foregroundStyle(.secondary)
            LegendRow(status: .identical,  label: "Identico")
            LegendRow(status: .modified,   label: "Modificato")
            LegendRow(status: .onlyInLeft, label: "Solo in A")
            LegendRow(status: .onlyInRight,label: "Solo in B")
        }
    }
}
