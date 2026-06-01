import SwiftUI

/// Week range header with prev/next controls.
struct WeekNavigator: View {
    @Binding var weekStart: Date
    var onChange: (() -> Void)? = nil

    var body: some View {
        HStack {
            navButton(systemName: "chevron.left") {
                weekStart = weekStart.adding(weeks: -1); onChange?()
            }
            Spacer()
            VStack(spacing: 2) {
                Text(rangeLabel)
                    .font(.Rota.headline)
                    .foregroundColor(Theme.Colors.textPrimary)
                if isCurrentWeek {
                    Text("This week").font(.Rota.caption).foregroundColor(Theme.Colors.accent)
                }
            }
            Spacer()
            navButton(systemName: "chevron.right") {
                weekStart = weekStart.adding(weeks: 1); onChange?()
            }
        }
        .padding(.horizontal, Theme.Spacing.xs)
    }

    private var isCurrentWeek: Bool { weekStart.isSameDay(as: Date().startOfWeek) }

    private var rangeLabel: String {
        let end = weekStart.adding(days: 6)
        return "\(weekStart.formatted("d MMM")) – \(end.formatted("d MMM"))"
    }

    private func navButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.selection()
            withAnimation(Theme.Motion.spring) { action() }
        } label: {
            Image(systemName: systemName)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Theme.Colors.textPrimary)
                .frame(width: 38, height: 38)
                .background(Theme.Colors.surface)
                .clipShape(Circle())
                .themeShadow(.soft)
        }
    }
}

/// Horizontal day selector strip (Mon..Sun).
struct DayStrip: View {
    let weekStart: Date
    @Binding var selectedDay: Date

    var body: some View {
        HStack(spacing: 6) {
            ForEach(weekStart.weekDays, id: \.self) { day in
                let isSelected = day.isSameDay(as: selectedDay)
                VStack(spacing: 6) {
                    Text(day.weekdayShort.uppercased())
                        .font(.Rota.caption2)
                        .foregroundColor(isSelected ? .white.opacity(0.9) : Theme.Colors.textTertiary)
                    Text(day.dayNumber)
                        .font(.Rota.headline)
                        .foregroundColor(isSelected ? .white : Theme.Colors.textPrimary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                        .fill(isSelected ? Theme.Colors.accent : Theme.Colors.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                        .stroke(day.isToday && !isSelected ? Theme.Colors.accent : Color.clear, lineWidth: 1.5)
                )
                .onTapGesture {
                    Haptics.selection()
                    withAnimation(Theme.Motion.snappy) { selectedDay = day }
                }
            }
        }
    }
}
