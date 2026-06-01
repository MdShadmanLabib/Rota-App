import Foundation

/// A reusable shift template to speed up rota building.
struct ShiftTemplate: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var organizationId: UUID
    var name: String
    var role: String
    var startTime: String   // "09:00"
    var endTime: String     // "17:00"
    var breakMinutes: Int
    var colorHex: String?

    /// Materialize this template into a concrete shift on a given day.
    func makeShift(on day: Date, organizationId: UUID, createdBy: UUID?) -> Shift {
        let start = Self.combine(day: day, time: startTime)
        var end = Self.combine(day: day, time: endTime)
        if end <= start { end = end.adding(days: 1) } // overnight shift
        return Shift(
            id: UUID(),
            organizationId: organizationId,
            title: name,
            role: role,
            location: nil,
            startAt: start,
            endAt: end,
            breakMinutes: breakMinutes,
            assignedUserId: nil,
            status: .scheduled,
            notes: nil,
            colorHex: colorHex,
            createdBy: createdBy,
            createdAt: .now
        )
    }

    static func combine(day: Date, time: String) -> Date {
        let parts = time.split(separator: ":").compactMap { Int($0) }
        let hour = parts.first ?? 9
        let minute = parts.count > 1 ? parts[1] : 0
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: day)
        comps.hour = hour
        comps.minute = minute
        return Calendar.current.date(from: comps) ?? day
    }
}
