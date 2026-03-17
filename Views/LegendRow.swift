import SwiftUI

struct LegendRow: View {
    let status: CompareStatus
    let label: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: status.icon)
                .foregroundStyle(status.color)
                .frame(width: 16)
            Text(label).font(.caption)
        }
    }
}
