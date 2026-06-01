import SwiftUI

/// Bottom sheet to assign (or unassign) a shift, with clash warnings.
struct AssignSheet: View {
    @Environment(\.dismiss) private var dismiss
    let shift: Shift
    let team: [UserProfile]
    let onAssign: (UUID?) -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.sm) {
                    Button {
                        onAssign(nil); dismiss()
                    } label: {
                        row(title: "Open shift", subtitle: "Unassign", systemImage: "person.crop.circle.badge.xmark", tint: Theme.Colors.warning)
                    }
                    .buttonStyle(PressableCardStyle())

                    ForEach(team) { member in
                        Button {
                            Haptics.success(); onAssign(member.id); dismiss()
                        } label: {
                            HStack(spacing: Theme.Spacing.sm) {
                                Avatar(name: member.fullName, size: 40)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(member.fullName).font(.Rota.headline).foregroundColor(Theme.Colors.textPrimary)
                                    Text(member.jobTitle ?? member.role.title).font(.Rota.footnote).foregroundColor(Theme.Colors.textSecondary)
                                }
                                Spacer()
                                if shift.assignedUserId == member.id {
                                    Image(systemName: "checkmark.circle.fill").foregroundColor(Theme.Colors.accent)
                                }
                            }
                            .padding(Theme.Spacing.md)
                            .background(Theme.Colors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
                        }
                        .buttonStyle(PressableCardStyle())
                    }
                }
                .padding(Theme.Spacing.lg)
            }
            .background(Theme.Colors.background)
            .navigationTitle("Assign \(shift.title)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } } }
        }
        .presentationDetents([.medium, .large])
    }

    private func row(title: String, subtitle: String, systemImage: String, tint: Color) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            ZStack { Circle().fill(tint.opacity(0.16)).frame(width: 40, height: 40)
                Image(systemName: systemImage).foregroundColor(tint) }
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.Rota.headline).foregroundColor(Theme.Colors.textPrimary)
                Text(subtitle).font(.Rota.footnote).foregroundColor(Theme.Colors.textSecondary)
            }
            Spacer()
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
    }
}
