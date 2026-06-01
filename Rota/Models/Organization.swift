import Foundation

/// A workspace / company that owns shifts and members.
struct Organization: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var name: String
    var inviteCode: String
    var timezone: String
    var weeklyOvertimeThreshold: Double // hours per week before overtime
    var workplaceLatitude: Double?
    var workplaceLongitude: Double?
    var clockInRadiusMeters: Double
    var createdAt: Date
}
