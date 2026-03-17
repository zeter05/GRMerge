import SwiftUI

struct ScanProgressView: View {
    @ObservedObject var vm: CompareViewModel

    var body: some View {
        VStack(spacing: 24) {

            // Icona animata
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 40))
                .foregroundStyle(.blue)
                .rotationEffect(.degrees(vm.isScanning ? 360 : 0))
                .animation(
                    vm.isScanning
                        ? .linear(duration: 1.5).repeatForever(autoreverses: false)
                        : .default,
                    value: vm.isScanning
                )

            // Barra progresso totale
            VStack(spacing: 8) {
                ProgressView(value: vm.currentProgress)
                    .progressViewStyle(.linear)
                    .frame(width: 320)
                    .animation(.easeInOut(duration: 0.3), value: vm.currentProgress)

                Text("\(Int(vm.currentProgress * 100))%")
                    .font(.title2.monospacedDigit())
                    .fontWeight(.semibold)
            }

            // Dettaglio fase corrente
            VStack(spacing: 12) {
                phaseRow(
                    phase: .scanningA,
                    label: "Scansione cartella A",
                    progress: vm.progressA
                )
                phaseRow(
                    phase: .scanningB,
                    label: "Scansione cartella B",
                    progress: vm.progressB
                )
                phaseRow(
                    phase: .comparing,
                    label: "Confronto file",
                    progress: nil
                )
            }
            .frame(width: 360)

            // File corrente
            Text(vm.currentProgressLabel)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(width: 360)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }


    private func phaseRow(
        phase: ScanPhase,
        label: String,
        progress: ScanProgress?
    ) -> some View {
        let state = phaseState(phase)

        return HStack(spacing: 10) {
            // Indicatore stato
            Group {
                switch state {
                case .waiting:
                    Image(systemName: "circle")
                        .foregroundStyle(.tertiary)
                case .active:
                    ProgressView()
                        .controlSize(.small)
                case .done:
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            }
            .frame(width: 18)

            Text(label)
                .font(.callout)
                .foregroundStyle(state == .waiting ? .tertiary : .primary)

            Spacer()

            // Contatore file
            if let p = progress {
                Text("\(p.scanned) / \(p.total)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            } else if state == .done {
                Text("✓")
                    .font(.caption)
                    .foregroundStyle(.green)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.quaternary.opacity(state == .active ? 1 : 0.5),
                    in: RoundedRectangle(cornerRadius: 8))
    }


    private enum PhaseState { case waiting, active, done }

    private func phaseState(_ phase: ScanPhase) -> PhaseState {
        let order: [ScanPhase] = [.scanningA, .scanningB, .comparing, .done]
        guard let current = order.firstIndex(where: { phasesEqual($0, vm.scanPhase) }),
              let target  = order.firstIndex(where: { phasesEqual($0, phase) })
        else { return .waiting }

        if current == target { return .active }
        if current > target  { return .done }
        return .waiting
    }

    private func phasesEqual(_ a: ScanPhase, _ b: ScanPhase) -> Bool {
        switch (a, b) {
        case (.scanningA, .scanningA), (.scanningB, .scanningB),
             (.comparing, .comparing), (.done, .done): return true
        default: return false
        }
    }
}
