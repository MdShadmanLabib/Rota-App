import SwiftUI

/// Shared screen background that applies the themed primary background.
struct ScreenBackground: View {
    var body: some View {
        Theme.Colors.background.ignoresSafeArea()
    }
}

extension View {
    /// Applies the standard screen background behind a view.
    func screenBackground() -> some View {
        ZStack {
            ScreenBackground()
            self
        }
    }
}

/// A pressable scale style used for tappable cards.
struct PressableCardStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(Theme.Motion.snappy, value: configuration.isPressed)
    }
}
