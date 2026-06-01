import SwiftUI

/// Standard surface card with soft shadow and rounded corners.
struct RotaCard<Content: View>: View {
    var padding: CGFloat = Theme.Spacing.md
    var background: Color = Theme.Colors.surface
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous)
                    .stroke(Theme.Colors.border.opacity(0.6), lineWidth: 0.5)
            )
            .themeShadow(.soft)
    }
}

/// Section header used across feature screens.
struct SectionHeader: View {
    let title: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        HStack {
            Text(title)
                .font(.Rota.title3)
                .foregroundColor(Theme.Colors.textPrimary)
            Spacer()
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(.Rota.subheadline)
                    .foregroundColor(Theme.Colors.accent)
            }
        }
    }
}
