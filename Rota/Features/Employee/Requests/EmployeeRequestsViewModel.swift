import Foundation

@MainActor
@Observable
final class EmployeeRequestsViewModel {
    var state: LoadState = .idle
    var leave: [LeaveRequest] = []
    var swaps: [SwapRequest] = []
    var myShifts: [Shift] = []
    var team: [UserProfile] = []

    func name(for id: UUID?) -> String {
        guard let id else { return "Anyone" }
        return team.first { $0.id == id }?.fullName ?? "Teammate"
    }

    func shift(_ id: UUID) -> Shift? { myShifts.first { $0.id == id } }

    func load(repository: RotaRepository, userId: UUID, organizationId: UUID?) async {
        if state == .idle { state = .loading }
        do {
            async let leaveTask = repository.fetchLeaveRequests(forUser: userId)
            async let shiftsTask = repository.fetchShifts(forUser: userId, from: Date().startOfDay, to: Date().adding(days: 30))
            leave = try await leaveTask.sorted { $0.createdAt > $1.createdAt }
            myShifts = try await shiftsTask
            if let orgId = organizationId {
                let allSwaps = try await repository.fetchSwapRequests(organizationId: orgId)
                swaps = allSwaps.filter { $0.requestedBy == userId }.sorted { $0.createdAt > $1.createdAt }
                team = try await repository.fetchTeam(organizationId: orgId)
            }
            state = .loaded
        } catch { state = .failed(AppError.from(error).errorDescription ?? "Failed to load requests") }
    }

    func submitLeave(repository: RotaRepository, userId: UUID, organizationId: UUID,
                     type: LeaveType, start: Date, end: Date, reason: String) async -> String? {
        guard end >= start else { return "End date must be after the start date." }
        let request = LeaveRequest(
            id: UUID(), organizationId: organizationId, userId: userId, type: type,
            startDate: start, endDate: end, reason: reason.isEmpty ? nil : reason,
            status: .pending, reviewedBy: nil, createdAt: .now
        )
        do {
            let created = try await repository.createLeaveRequest(request)
            leave.insert(created, at: 0)
            return nil
        } catch { return AppError.from(error).errorDescription }
    }

    func submitSwap(repository: RotaRepository, userId: UUID, organizationId: UUID,
                    shiftId: UUID, targetUserId: UUID?, message: String) async -> String? {
        let request = SwapRequest(
            id: UUID(), organizationId: organizationId, shiftId: shiftId,
            requestedBy: userId, targetUserId: targetUserId,
            message: message.isEmpty ? nil : message, status: .pending, createdAt: .now
        )
        do {
            let created = try await repository.createSwapRequest(request)
            swaps.insert(created, at: 0)
            return nil
        } catch { return AppError.from(error).errorDescription }
    }

    func cancelLeave(_ request: LeaveRequest, repository: RotaRepository) async {
        guard let updated = try? await repository.updateLeaveStatus(id: request.id, status: .cancelled, reviewerId: nil) else { return }
        if let idx = leave.firstIndex(where: { $0.id == request.id }) { leave[idx] = updated }
    }
}
