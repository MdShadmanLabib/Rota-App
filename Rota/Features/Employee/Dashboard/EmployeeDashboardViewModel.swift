import SwiftUI

@MainActor
@Observable
final class EmployeeDashboardViewModel {
    var state: LoadState = .idle
    var upcomingShifts: [Shift] = []
    var weekShifts: [Shift] = []
    var activeEntry: TimeEntry?
    var latestAnnouncement: Announcement?

    var nextShift: Shift? {
        upcomingShifts.first { $0.endAt > .now }
    }

    var weeklyHours: Double { weekShifts.reduce(0) { $0 + $1.paidDuration.decimalHours } }
    var completedThisWeek: Int { weekShifts.filter { $0.status == .completed }.count }

    func load(repository: RotaRepository, userId: UUID, organizationId: UUID?) async {
        if state == .idle { state = .loading }
        let weekStart = Date().startOfWeek
        let weekEnd = weekStart.adding(days: 6).adding(days: 1)
        let horizon = Date().adding(days: 21)
        do {
            async let weekTask = repository.fetchShifts(forUser: userId, from: weekStart, to: weekEnd)
            async let upcomingTask = repository.fetchShifts(forUser: userId, from: Date().startOfDay, to: horizon)
            async let entryTask = repository.activeTimeEntry(userId: userId)
            let (week, upcoming, entry) = try await (weekTask, upcomingTask, entryTask)
            weekShifts = week
            upcomingShifts = upcoming
            activeEntry = entry
            if let orgId = organizationId {
                latestAnnouncement = try? await repository.fetchAnnouncements(organizationId: orgId).first
            }
            state = .loaded
        } catch {
            state = .failed(AppError.from(error).errorDescription ?? "Failed to load")
        }
    }
}
