import SwiftUI

struct DayMetric: Identifiable {
    let id = UUID()
    let day: Date
    var label: String { day.weekdayShort }
    let scheduledHours: Double
    let workedHours: Double
    let shiftCount: Int
}

struct RoleSlice: Identifiable {
    let id = UUID()
    let role: String
    let hours: Double
}

struct EmployeeHours: Identifiable {
    let id: UUID
    let name: String
    let hours: Double
}

@MainActor
@Observable
final class AnalyticsViewModel {
    var state: LoadState = .idle
    var dayMetrics: [DayMetric] = []
    var roleSlices: [RoleSlice] = []
    var topEmployees: [EmployeeHours] = []
    var totalScheduled = 0.0
    var totalWorked = 0.0
    var attendanceRate = 0.0
    var overtimeHours = 0.0

    func load(repository: RotaRepository, organizationId: UUID, overtimeThreshold: Double) async {
        if state == .idle { state = .loading }
        let weekStart = Date().startOfWeek
        let weekEnd = weekStart.adding(days: 6).adding(days: 1)
        do {
            async let shiftsTask = repository.fetchShifts(organizationId: organizationId, from: weekStart, to: weekEnd)
            async let entriesTask = repository.fetchTimeEntries(organizationId: organizationId, from: weekStart, to: weekEnd)
            async let teamTask = repository.fetchTeam(organizationId: organizationId)
            let (shifts, entries, team) = try await (shiftsTask, entriesTask, teamTask)
            compute(shifts: shifts, entries: entries, team: team, weekStart: weekStart, overtimeThreshold: overtimeThreshold)
            state = .loaded
        } catch {
            state = .failed(AppError.from(error).errorDescription ?? "Failed to load analytics")
        }
    }

    private func compute(shifts: [Shift], entries: [TimeEntry], team: [UserProfile], weekStart: Date, overtimeThreshold: Double) {
        let names = Dictionary(uniqueKeysWithValues: team.map { ($0.id, $0.fullName) })

        dayMetrics = weekStart.weekDays.map { day in
            let dayShifts = shifts.filter { $0.startAt.isSameDay(as: day) }
            let dayEntries = entries.filter { $0.clockInAt.isSameDay(as: day) }
            return DayMetric(
                day: day,
                scheduledHours: dayShifts.reduce(0) { $0 + $1.paidDuration.decimalHours },
                workedHours: dayEntries.reduce(0) { $0 + $1.duration.decimalHours },
                shiftCount: dayShifts.count
            )
        }

        var byRole: [String: Double] = [:]
        for shift in shifts { byRole[shift.role, default: 0] += shift.paidDuration.decimalHours }
        roleSlices = byRole.map { RoleSlice(role: $0.key, hours: $0.value) }.sorted { $0.hours > $1.hours }

        let workedByUser = entries.reduce(into: [UUID: Double]()) { $0[$1.userId, default: 0] += $1.duration.decimalHours }
        topEmployees = workedByUser.map { EmployeeHours(id: $0.key, name: names[$0.key] ?? "Teammate", hours: $0.value) }
            .sorted { $0.hours > $1.hours }.prefix(5).map { $0 }

        totalScheduled = dayMetrics.reduce(0) { $0 + $1.scheduledHours }
        totalWorked = dayMetrics.reduce(0) { $0 + $1.workedHours }

        let completed = shifts.filter { $0.status == .completed }
        let attended = completed.filter { shift in entries.contains { $0.shiftId == shift.id } }
        attendanceRate = completed.isEmpty ? 1 : Double(attended.count) / Double(completed.count)

        let weekly = SchedulingEngine.weeklyHours(for: shifts)
        overtimeHours = weekly.values.reduce(0) { $0 + max(0, $1 - overtimeThreshold) }
    }
}
