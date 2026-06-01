import Foundation

/// Smart scheduling helpers: conflict detection, overtime warnings and a
/// lightweight heuristic auto-scheduler. Pure functions — easy to unit test.
enum SchedulingEngine {

    struct Conflict: Identifiable {
        let id = UUID()
        let message: String
        let shiftIds: [UUID]
    }

    /// Detect overlapping shifts for the same employee (shift clashes).
    static func clashes(in shifts: [Shift]) -> [Conflict] {
        var result: [Conflict] = []
        let assigned = shifts.filter { $0.assignedUserId != nil }
        for i in assigned.indices {
            for j in (i + 1)..<assigned.count {
                if assigned[i].clashes(with: assigned[j]) {
                    result.append(Conflict(
                        message: "\(assigned[i].title) overlaps with \(assigned[j].title)",
                        shiftIds: [assigned[i].id, assigned[j].id]
                    ))
                }
            }
        }
        return result
    }

    /// Total paid hours per user for a set of shifts.
    static func weeklyHours(for shifts: [Shift]) -> [UUID: Double] {
        var totals: [UUID: Double] = [:]
        for shift in shifts {
            guard let user = shift.assignedUserId else { continue }
            totals[user, default: 0] += shift.paidDuration.decimalHours
        }
        return totals
    }

    /// Users exceeding the overtime threshold.
    static func overtimeWarnings(shifts: [Shift], threshold: Double) -> [UUID: Double] {
        weeklyHours(for: shifts).filter { $0.value > threshold }
    }

    /// Whether assigning `shift` to `userId` would create a clash given existing shifts.
    static func wouldClash(assigning shift: Shift, to userId: UUID, existing: [Shift]) -> Bool {
        existing.contains { other in
            other.id != shift.id &&
            other.assignedUserId == userId &&
            shift.startAt < other.endAt && other.startAt < shift.endAt
        }
    }

    /// Heuristic auto-assignment for OPEN shifts. Balances load by assigning each
    /// open shift to the available, non-clashing employee with the fewest hours so far.
    /// Returns a mapping of shiftId -> userId for suggested assignments.
    static func autoAssign(
        openShifts: [Shift],
        team: [UserProfile],
        existing: [Shift],
        availability: [UUID: Set<Int>] = [:]
    ) -> [UUID: UUID] {
        var suggestions: [UUID: UUID] = [:]
        var hours = weeklyHours(for: existing)
        var working = existing

        for shift in openShifts.sorted(by: { $0.startAt < $1.startAt }) {
            let weekday = Calendar.current.component(.weekday, from: shift.startAt)
            let isoWeekday = (weekday + 5) % 7 + 1 // convert Sun=1..Sat=7 to Mon=1..Sun=7

            let candidate = team
                .filter { $0.role == .employee || $0.role == .manager }
                .filter { member in
                    if let avail = availability[member.id] { return avail.contains(isoWeekday) }
                    return true
                }
                .filter { !wouldClash(assigning: shift, to: $0.id, existing: working) }
                .min(by: { (hours[$0.id] ?? 0) < (hours[$1.id] ?? 0) })

            if let candidate {
                suggestions[shift.id] = candidate.id
                hours[candidate.id, default: 0] += shift.paidDuration.decimalHours
                var assigned = shift
                assigned.assignedUserId = candidate.id
                working.append(assigned)
            }
        }
        return suggestions
    }
}
