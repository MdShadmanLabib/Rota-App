import Foundation

extension Date {
    private static var cal: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.firstWeekday = 2 // Monday
        return c
    }

    var startOfDay: Date { Date.cal.startOfDay(for: self) }

    var startOfWeek: Date {
        let comps = Date.cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return Date.cal.date(from: comps) ?? self
    }

    var endOfWeek: Date {
        Date.cal.date(byAdding: .day, value: 6, to: startOfWeek) ?? self
    }

    var startOfMonth: Date {
        let comps = Date.cal.dateComponents([.year, .month], from: self)
        return Date.cal.date(from: comps) ?? self
    }

    func adding(days: Int) -> Date {
        Date.cal.date(byAdding: .day, value: days, to: self) ?? self
    }

    func adding(weeks: Int) -> Date {
        Date.cal.date(byAdding: .weekOfYear, value: weeks, to: self) ?? self
    }

    func isSameDay(as other: Date) -> Bool {
        Date.cal.isDate(self, inSameDayAs: other)
    }

    var isToday: Bool { Date.cal.isDateInToday(self) }

    var weekdayShort: String {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        return f.string(from: self)
    }

    var dayNumber: String {
        let f = DateFormatter()
        f.dateFormat = "d"
        return f.string(from: self)
    }

    func formatted(_ pattern: String) -> String {
        let f = DateFormatter()
        f.dateFormat = pattern
        return f.string(from: self)
    }

    var timeLabel: String { formatted("HH:mm") }
    var dayMonthLabel: String { formatted("EEE d MMM") }
    var monthYearLabel: String { formatted("MMMM yyyy") }

    /// "Today", "Tomorrow", "Yesterday" or a short date.
    var relativeLabel: String {
        if Date.cal.isDateInToday(self) { return "Today" }
        if Date.cal.isDateInTomorrow(self) { return "Tomorrow" }
        if Date.cal.isDateInYesterday(self) { return "Yesterday" }
        return dayMonthLabel
    }

    /// Days of the week (Mon..Sun) for the week containing this date.
    var weekDays: [Date] {
        (0..<7).map { startOfWeek.adding(days: $0) }
    }
}

extension TimeInterval {
    /// Formats a duration in seconds as "8h 30m".
    var hoursMinutes: String {
        let totalMinutes = Int(self / 60)
        let h = totalMinutes / 60
        let m = totalMinutes % 60
        if h == 0 { return "\(m)m" }
        if m == 0 { return "\(h)h" }
        return "\(h)h \(m)m"
    }

    var decimalHours: Double { self / 3600 }

    /// Formats a duration as a running clock "HH:MM:SS".
    var clockString: String {
        let total = Int(self)
        return String(format: "%02d:%02d:%02d", total / 3600, (total % 3600) / 60, total % 60)
    }
}
