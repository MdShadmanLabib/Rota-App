import SwiftUI

/// Reusable shift row used in lists across employer and employee views.
struct ShiftCard: View {
    let shift: Shift
    var assigneeName: String?
    var showDate: Bool = false
    var onTap: (() -> Void)? = nil

    var body: some View {
        Button {
            Haptics.tap()
            onTap?()
        } label: {
            HStack(spacing: Theme.Spacing.md) {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(shift.accentColor)
                    .frame(width: 5)
                    .frame(maxHeight: .infinity)

                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: Theme.Spacing.xs) {
                        Text(shift.title)
                            .font(.Rota.headline)
                            .foregroundColor(Theme.Colors.textPrimary)
                        if shift.isOpen {
                            Badge(text: "Open", tone: .warning)
                        }
                    }
                    HStack(spacing: 6) {
                        Image(systemName: "clock")
                        Text(showDate ? "\(shift.startAt.dayMonthLabel) · \(shift.timeRangeLabel)" : shift.timeRangeLabel)
                        if let location = shift.location {
                            Text("· \(location)")
                        }
                    }
                    .font(.Rota.footnote)
                    .foregroundColor(Theme.Colors.textSecondary)

                    if let assigneeName, !shift.isOpen {
                        HStack(spacing: 6) {
                            Avatar(name: assigneeName, size: 20)
                            Text(assigneeName)
                                .font(.Rota.caption)
                                .foregroundColor(Theme.Colors.textSecondary)
                        }
                        .padding(.top, 2)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
                    Badge(text: shift.status.label, tone: shift.status.tone)
                    Text(shift.paidDuration.hoursMinutes)
                        .font(.Rota.caption)
                        .foregroundColor(Theme.Colors.textTertiary)
                }
            }
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous)
                    .stroke(Theme.Colors.border.opacity(0.6), lineWidth: 0.5)
            )
            .themeShadow(.soft)
        }
        .buttonStyle(PressableCardStyle())
    }
}
