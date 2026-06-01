import SwiftUI

enum RotaButtonStyle {
    case primary, secondary, ghost, destructive
}

/// Premium button with loading state, haptics and spring press animation.
struct RotaButton: View {
    let title: String
    var icon: String? = nil
    var style: RotaButtonStyle = .primary
    var isLoading: Bool = false
    var isEnabled: Bool = true
    var fullWidth: Bool = true
    let action: () -> Void

    @State private var pressed = false

    var body: some View {
        Button {
            guard isEnabled && !isLoading else { return }
            Haptics.tap()
            action()
        } label: {
            HStack(spacing: Theme.Spacing.xs) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(foreground)
                } else {
                    if let icon { Image(systemName: icon).font(.system(size: 15, weight: .semibold)) }
                    Text(title).font(.Rota.headline)
                }
            }
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .frame(height: 52)
            .padding(.horizontal, fullWidth ? 0 : Theme.Spacing.lg)
            .foregroundColor(foreground)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                    .stroke(borderColor, lineWidth: style == .secondary ? 1 : 0)
            )
            .opacity(isEnabled ? 1 : 0.5)
            .scaleEffect(pressed ? 0.97 : 1)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled || isLoading)
        .animation(Theme.Motion.snappy, value: pressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in pressed = true }
                .onEnded { _ in pressed = false }
        )
    }

    private var foreground: Color {
        switch style {
        case .primary, .destructive: return .white
        case .secondary: return Theme.Colors.textPrimary
        case .ghost: return Theme.Colors.accent
        }
    }

    private var background: some View {
        Group {
            switch style {
            case .primary:
                LinearGradient(
                    colors: [Theme.Colors.accent, Theme.Colors.accentStrong],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            case .destructive:
                Theme.Colors.danger
            case .secondary:
                Theme.Colors.surface
            case .ghost:
                Color.clear
            }
        }
    }

    private var borderColor: Color {
        style == .secondary ? Theme.Colors.border : .clear
    }
}
