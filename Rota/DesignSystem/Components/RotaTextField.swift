import SwiftUI

/// Styled text field with label, icon and optional secure entry.
struct RotaTextField: View {
    let title: String
    var icon: String? = nil
    var placeholder: String = ""
    var isSecure: Bool = false
    var keyboard: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .never
    @Binding var text: String

    @State private var revealed = false
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text(title)
                .font(.Rota.subheadline)
                .foregroundColor(Theme.Colors.textSecondary)

            HStack(spacing: Theme.Spacing.sm) {
                if let icon {
                    Image(systemName: icon)
                        .foregroundColor(focused ? Theme.Colors.accent : Theme.Colors.textTertiary)
                        .frame(width: 18)
                }

                Group {
                    if isSecure && !revealed {
                        SecureField(placeholder, text: $text)
                    } else {
                        TextField(placeholder, text: $text)
                    }
                }
                .focused($focused)
                .font(.Rota.body)
                .foregroundColor(Theme.Colors.textPrimary)
                .keyboardType(keyboard)
                .textInputAutocapitalization(autocapitalization)
                .autocorrectionDisabled()

                if isSecure {
                    Button {
                        revealed.toggle()
                        Haptics.selection()
                    } label: {
                        Image(systemName: revealed ? "eye.slash" : "eye")
                            .foregroundColor(Theme.Colors.textTertiary)
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
            .frame(height: 52)
            .background(Theme.Colors.surfaceMuted)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                    .stroke(focused ? Theme.Colors.accent : Color.clear, lineWidth: 1.5)
            )
            .animation(Theme.Motion.smooth, value: focused)
        }
    }
}
