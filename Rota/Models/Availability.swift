import Foundation

/// Weekly availability preference for an employee.
/// `weekday` uses 1 = Monday ... 7 = Sunday.
struct Availability: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var organizationId: UUID
    var userId: UUID
    var weekday: Int
    var isAvailable: Bool
    var startTime: String?  // "09:00"
    var endTime: String?    // "17:00"

    static let weekdayNames = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    var weekdayName: String {
        guard weekday >= 1 && weekday <= 7 else { return "?" }
        return Self.weekdayNames[weekday - 1]
    }
}
