import SwiftUI

/// Animated segmented control with a sliding selection pill.
struct RotaSegmentedControl<T: Hashable>: View {
    let options: [T]
    let titleFor: (T) -> String
    @Binding var selection: T
    @Namespace private var ns

    var body: some View {
        HStack(spacing: 4) {
            ForEach(options, id: \.self) { option in
                let isSelected = option == selection
                Text(titleFor(option))
                    .font(.Rota.subheadline)
                    .foregroundColor(isSelected ? Theme.Colors.textPrimary : Theme.Colors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .background(
                        ZStack {
                            if isSelected {
                                RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous)
                                    .fill(Theme.Colors.surface)
                                    .themeShadow(.soft)
                                    .matchedGeometryEffect(id: "seg", in: ns)
                            }
                        }
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        Haptics.selection()
                        withAnimation(Theme.Motion.snappy) { selection = option }
                    }
            }
        }
        .padding(4)
        .background(Theme.Colors.surfaceMuted)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
    }
}

/// Selectable filter chip.
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.selection()
            action()
        } label: {
            Text(title)
                .font(.Rota.subheadline)
                .foregroundColor(isSelected ? .white : Theme.Colors.textSecondary)
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.xs)
                .background(isSelected ? Theme.Colors.accent : Theme.Colors.surfaceMuted)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
