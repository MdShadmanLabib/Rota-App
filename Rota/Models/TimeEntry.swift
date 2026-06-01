import Foundation

/// A clock in/out record. `clockOutAt == nil` means currently on the clock.
struct TimeEntry: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var organizationId: UUID
    var userId: UUID
    var shiftId: UUID?
    var clockInAt: Date
    var clockOutAt: Date?
    var clockInLat: Double?
    var clockInLng: Double?
    var method: String   // "manual", "geo", "qr"
    var createdAt: Date

    var isActive: Bool { clockOutAt == nil }

    var duration: TimeInterval {
        (clockOutAt ?? .now).timeIntervalSince(clockInAt)
    }
}
