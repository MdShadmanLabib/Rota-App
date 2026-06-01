import SwiftUI

@MainActor
@Observable
final class EmployerDashboardViewModel {
    var state: LoadState = .idle
    var shifts: [Shift] = []
    var team: [UserProfile] = []
    var leave: [LeaveRequest] = []
    var swaps: [SwapRequest] = []
    var timeEntries: [TimeEntry] = []

    private var nameMap: [UUID: String] = [:]

    func name(for id: UUID?) -> String {
        guard let id else { return "Open shift" }
        return nameMap[id] ?? "Teammate"
    }

    // Derived metrics
    var weeklyHours: Double {
        shifts.reduce(0) { $0 + $1.paidDuration.decimalHours }
    }
    var openShiftCount: Int { shifts.filter(\.isOpen).count }
    var pendingRequests: Int {
        leave.filter { $0.status == .pending }.count + swaps.filter { $0.status == .pending }.count
    }
    var onTheClock: Int { timeEntries.filter(\.isActive).count }

    var todayShifts: [Shift] {
        shifts.filter { $0.startAt.isToday }.sorted { $0.startAt < $1.startAt }
    }

    var overtimeNames: [String] {
        let threshold = 40.0
        return SchedulingEngine.overtimeWarnings(shifts: shifts, threshold: threshold)
            .keys.compactMap { nameMap[$0] }
    }

    /// Coverage per day this week (number of assigned shifts).
    func coverage(weekStart: Date) -> [(day: Date, count: Int)] {
        weekStart.weekDays.map { day in
            (day, shifts.filter { $0.startAt.isSameDay(as: day) && !$0.isOpen }.count)
        }
    }

    func load(repository: RotaRepository, organizationId: UUID) async {
        if state == .idle { state = .loading }
        let weekStart = Date().startOfWeek
        let weekEnd = weekStart.adding(days: 6).adding(days: 1)
        do {
            async let shiftsTask = repository.fetchShifts(organizationId: organizationId, from: weekStart, to: weekEnd)
            async let teamTask = repository.fetchTeam(organizationId: organizationId)
            async let leaveTask = repository.fetchLeaveRequests(organizationId: organizationId)
            async let swapsTask = repository.fetchSwapRequests(organizationId: organizationId)
            async let entriesTask = repository.fetchTimeEntries(organizationId: organizationId, from: weekStart, to: weekEnd)

            let (s, t, l, sw, e) = try await (shiftsTask, teamTask, leaveTask, swapsTask, entriesTask)
            shifts = s
            team = t
            leave = l
            swaps = sw
            timeEntries = e
            nameMap = Dictionary(uniqueKeysWithValues: t.map { ($0.id, $0.fullName) })
            state = .loaded
        } catch {
            state = .failed(AppError.from(error).errorDescription ?? "Something went wrong")
        }
    }
}
