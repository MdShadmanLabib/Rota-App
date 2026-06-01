import SwiftUI

@MainActor
@Observable
final class RequestsViewModel {
    var state: LoadState = .idle
    var leave: [LeaveRequest] = []
    var swaps: [SwapRequest] = []
    private var nameMap: [UUID: String] = [:]
    private var shiftMap: [UUID: Shift] = [:]

    func name(for id: UUID?) -> String {
        guard let id else { return "Someone" }
        return nameMap[id] ?? "Teammate"
    }
    func shift(for id: UUID) -> Shift? { shiftMap[id] }

    var pendingLeave: [LeaveRequest] { leave.filter { $0.status == .pending } }
    var pendingSwaps: [SwapRequest] { swaps.filter { $0.status == .pending } }

    func load(repository: RotaRepository, organizationId: UUID) async {
        if state == .idle { state = .loading }
        let weekStart = Date().startOfWeek.adding(weeks: -2)
        let weekEnd = weekStart.adding(weeks: 8)
        do {
            async let leaveTask = repository.fetchLeaveRequests(organizationId: organizationId)
            async let swapsTask = repository.fetchSwapRequests(organizationId: organizationId)
            async let teamTask = repository.fetchTeam(organizationId: organizationId)
            async let shiftsTask = repository.fetchShifts(organizationId: organizationId, from: weekStart, to: weekEnd)
            let (l, sw, t, s) = try await (leaveTask, swapsTask, teamTask, shiftsTask)
            leave = l
            swaps = sw
            nameMap = Dictionary(uniqueKeysWithValues: t.map { ($0.id, $0.fullName) })
            shiftMap = Dictionary(uniqueKeysWithValues: s.map { ($0.id, $0) })
            state = .loaded
        } catch {
            state = .failed(AppError.from(error).errorDescription ?? "Failed to load requests")
        }
    }

    func decide(_ request: LeaveRequest, approve: Bool, repository: RotaRepository, reviewerId: UUID?) async {
        do {
            let updated = try await repository.updateLeaveStatus(
                id: request.id, status: approve ? .approved : .rejected, reviewerId: reviewerId)
            if let idx = leave.firstIndex(where: { $0.id == updated.id }) { leave[idx] = updated }
            Haptics.success()
        } catch {
            Haptics.error()
        }
    }

    func decideSwap(_ request: SwapRequest, approve: Bool, repository: RotaRepository) async {
        do {
            let updated = try await repository.updateSwapStatus(id: request.id, status: approve ? .approved : .rejected)
            if let idx = swaps.firstIndex(where: { $0.id == updated.id }) { swaps[idx] = updated }
            Haptics.success()
        } catch {
            Haptics.error()
        }
    }
}
