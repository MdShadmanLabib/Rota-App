import Foundation

/// A request to swap/give away a shift to another teammate.
struct SwapRequest: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var organizationId: UUID
    var shiftId: UUID
    var requestedBy: UUID
    var targetUserId: UUID?    // nil = open to anyone
    var message: String?
    var status: RequestStatus
    var createdAt: Date
}
