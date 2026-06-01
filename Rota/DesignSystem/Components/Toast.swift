import SwiftUI

struct ToastMessage: Equatable, Identifiable {
    let id = UUID()
    let text: String
    var tone: BadgeTone = .success
    var icon: String = "checkmark.circle.fill"
}

/// Observable toast presenter injected into the environment.
@Observable
final class ToastCenter {
    var current: ToastMessage?

    func show(_ message: String, tone: BadgeTone = .success, icon: String = "checkmark.circle.fill") {
        let toast = ToastMessage(text: message, tone: tone, icon: icon)
        withAnimation(Theme.Motion.spring) { current = toast }
        Task {
            try? await Task.sleep(for: .seconds(2.4))
            if current == toast {
                withAnimation(Theme.Motion.spring) { current = nil }
            }
        }
    }

    func error(_ message: String) {
        show(message, tone: .danger, icon: "exclamationmark.triangle.fill")
        Haptics.error()
    }
}

private struct ToastOverlay: ViewModifier {
    @Environment(ToastCenter.self) private var toasts

    func body(content: Content) -> some View {
        content.overlay(alignment: .top) {
            if let toast = toasts.current {
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: toast.icon).foregroundColor(toast.tone.fg)
                    Text(toast.text)
                        .font(.Rota.subheadline)
                        .foregroundColor(Theme.Colors.textPrimary)
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.sm)
                .background(Theme.Colors.surfaceElevated)
                .clipShape(Capsule())
                .themeShadow(.floating)
                .padding(.top, Theme.Spacing.xs)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }
}

extension View {
    func toastHost() -> some View { modifier(ToastOverlay()) }
}
