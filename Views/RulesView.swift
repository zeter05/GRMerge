// Views/RulesView.swift
import SwiftUI

struct RulesView: View {
    @ObservedObject var vm: CompareViewModel
    @State private var showingAddExclude = false
    @State private var showingAddNormalize = false
    @State private var newRuleText = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            // MARK: Preset
            Menu("Carica preset...") {
                ForEach(RulePreset.defaults, id: \.name) { preset in
                    Button(preset.name) {
                        vm.excludeRules   = preset.excludeRules
                        vm.normalizeRules = preset.normalizeRules
                    }
                }
            }
            .menuStyle(.borderlessButton)
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            // MARK: Regole esclusione
            RuleSectionHeader(
                title: "Escludi",
                systemImage: "xmark.circle",
                color: .red
            ) { showingAddExclude = true }

            ForEach(vm.excludeRules) { rule in
                RuleChip(label: rule.description, color: .red) {
                    vm.excludeRules.removeAll { $0.id == rule.id }
                }
            }

            if showingAddExclude {
                RuleInputRow(
                    placeholder: "es. .DS_Store o *.log o build/",
                    text: $newRuleText
                ) {
                    addExcludeRule(from: newRuleText)
                    newRuleText = ""
                    showingAddExclude = false
                }
            }

            Divider()

            // MARK: Regole normalizzazione
            RuleSectionHeader(
                title: "Normalizza",
                systemImage: "wand.and.stars",
                color: .orange
            ) { showingAddNormalize = true }

            // Toggle per ogni regola disponibile
            ForEach([
                NormalizeRule.ignoreLineEndings,
                .ignoreTrailingWhitespace,
                .ignoreAllWhitespace,
                .ignoreBlankLines,
                .ignoreComments,
                .lowercased
            ], id: \.id) { rule in
                Toggle(rule.description, isOn: Binding(
                    get: { vm.normalizeRules.contains(rule) },
                    set: { enabled in
                        if enabled {
                            if !vm.normalizeRules.contains(rule) {
                                vm.normalizeRules.append(rule)
                            }
                        } else {
                            vm.normalizeRules.removeAll { $0 == rule }
                        }
                    }
                ))
                .toggleStyle(.checkbox)
                .font(.caption)
            }
        }
    }

    private func addExcludeRule(from text: String) {
        let t = text.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return }

        let rule: ExcludeRule
        if t.hasSuffix("/") {
            rule = .directoryName(String(t.dropLast()))
        } else if t.contains("*") {
            rule = .glob(t)
        } else if t.contains(".") && !t.hasPrefix(".") {
            rule = .fileExtension(t.components(separatedBy: ".").last ?? t)
        } else {
            rule = .exactName(t)
        }

        if !vm.excludeRules.contains(rule) {
            vm.excludeRules.append(rule)
        }
    }
}

// MARK: - Componenti UI

struct RuleSectionHeader: View {
    let title: String
    let systemImage: String
    let color: Color
    let onAdd: () -> Void

    var body: some View {
        HStack {
            Image(systemName: systemImage).foregroundStyle(color).frame(width: 14)
            Text(title).font(.caption).fontWeight(.semibold).foregroundStyle(.secondary)
            Spacer()
            Button { onAdd() } label: {
                Image(systemName: "plus").font(.caption)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
    }
}

struct RuleChip: View {
    let label: String
    let color: Color
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Text(label).font(.caption).lineLimit(1)
            Spacer()
            Button { onRemove() } label: {
                Image(systemName: "xmark").font(.system(size: 9))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.08), in: RoundedRectangle(cornerRadius: 6))
    }
}

struct RuleInputRow: View {
    let placeholder: String
    @Binding var text: String
    let onConfirm: () -> Void

    var body: some View {
        HStack {
            TextField(placeholder, text: $text)
                .font(.caption)
                .textFieldStyle(.roundedBorder)
                .onSubmit { onConfirm() }
            Button("OK") { onConfirm() }
                .buttonStyle(.bordered)
                .controlSize(.mini)
                .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)
        }
    }
}
