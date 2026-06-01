import SwiftUI

/// Lets the user pick a template to apply to the selected day.
struct TemplatePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let templates: [ShiftTemplate]
    let onPick: (ShiftTemplate) -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.sm) {
                    if templates.isEmpty {
                        EmptyStateView(icon: "square.on.square", title: "No templates",
                                       message: "Create templates from the More tab to speed up scheduling.")
                    } else {
                        ForEach(templates) { template in
                            Button {
                                Haptics.success(); onPick(template); dismiss()
                            } label: {
                                TemplateRow(template: template)
                            }
                            .buttonStyle(PressableCardStyle())
                        }
                    }
                }
                .padding(Theme.Spacing.lg)
            }
            .background(Theme.Colors.background)
            .navigationTitle("Apply template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
        }
        .presentationDetents([.medium, .large])
    }
}

struct TemplateRow: View {
    let template: ShiftTemplate

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            RoundedRectangle(cornerRadius: 4)
                .fill(template.colorHex.map { Color(hex: $0) } ?? Theme.Colors.accent)
                .frame(width: 5, height: 42)
            VStack(alignment: .leading, spacing: 2) {
                Text(template.name).font(.Rota.headline).foregroundColor(Theme.Colors.textPrimary)
                Text("\(template.role) · \(template.startTime)–\(template.endTime)")
                    .font(.Rota.footnote).foregroundColor(Theme.Colors.textSecondary)
            }
            Spacer()
            Image(systemName: "plus.circle.fill").foregroundColor(Theme.Colors.accent)
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
    }
}
