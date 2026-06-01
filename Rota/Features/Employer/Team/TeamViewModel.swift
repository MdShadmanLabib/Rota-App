import SwiftUI

@MainActor
@Observable
final class TeamViewModel {
    var state: LoadState = .idle
    var team: [UserProfile] = []
    var hoursByUser: [UUID: Double] = [:]
    var activeUserIds: Set<UUID> = []
    var searchText = ""

    var filteredTeam: [UserProfile] {
        guard !searchText.isEmpty else { return team }
        return team.filter { $0.fullName.localizedCaseInsensitiveContains(searchText)
            || ($0.jobTitle ?? "").localizedCaseInsensitiveContains(searchText) }
    }

    func load(repository: RotaRepository, organizationId: UUID) async {
        if state == .idle { state = .loading }
        let weekStart = Date().startOfWeek
        let weekEnd = weekStart.adding(days: 6).adding(days: 1)
        do {
            async let teamTask = repository.fetchTeam(organizationId: organizationId)
            async let shiftsTask = repository.fetchShifts(organizationId: organizationId, from: weekStart, to: weekEnd)
            async let entriesTask = repository.fetchTimeEntries(organizationId: organizationId, from: weekStart, to: weekEnd)
            let (t, s, e) = try await (teamTask, shiftsTask, entriesTask)
            team = t
            hoursByUser = SchedulingEngine.weeklyHours(for: s)
            activeUserIds = Set(e.filter(\.isActive).map(\.userId))
            state = .loaded
        } catch {
            state = .failed(AppError.from(error).errorDescription ?? "Failed to load team")
        }
    }
}
