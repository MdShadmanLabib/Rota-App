import SwiftUI

/// Friendly empty state with optional call to action.
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(Theme.Colors.accentSoft)
                    .frame(width: 88, height: 88)
                Image(systemName: icon)
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundColor(Theme.Colors.accent)
            }

            VStack(spacing: Theme.Spacing.xxs) {
                Text(title)
                    .font(.Rota.title3)
                    .foregroundColor(Theme.Colors.textPrimary)
                Text(message)
                    .font(.Rota.callout)
                    .foregroundColor(Theme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            if let actionTitle, let action {
                RotaButton(title: actionTitle, style: .secondary, fullWidth: false, action: action)
                    .padding(.top, Theme.Spacing.xs)
            }
        }
        .padding(Theme.Spacing.xl)
        .frame(maxWidth: .infinity)
    }
}
