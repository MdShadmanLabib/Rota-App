import SwiftUI

enum ShiftStatus: String, Codable, Sendable {
    case scheduled
    case published
    case inProgress = "in_progress"
    case completed
    case cancelled

    var label: String {
        switch self {
        case .scheduled: return "Draft"
        case .published: return "Published"
        case .inProgress: return "In progress"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        }
    }

    var tone: BadgeTone {
        switch self {
        case .scheduled: return .neutral
        case .published: return .info
        case .inProgress: return .accent
        case .completed: return .success
        case .cancelled: return .danger
        }
    }
}

/// A scheduled shift. A shift may be assigned to an employee (or open).
struct Shift: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var organizationId: UUID
    var title: String
    var role: String           // e.g. "Barista", "Floor", "Manager"
    var location: String?
    var startAt: Date
    var endAt: Date
    var breakMinutes: Int
    var assignedUserId: UUID?
    var status: ShiftStatus
    var notes: String?
    var colorHex: String?
    var createdBy: UUID?
    var createdAt: Date

    /// Paid duration excluding unpaid break.
    var paidDuration: TimeInterval {
        max(0, endAt.timeIntervalSince(startAt) - Double(breakMinutes) * 60)
    }

    var isOpen: Bool { assignedUserId == nil }

    var timeRangeLabel: String {
        "\(startAt.timeLabel) – \(endAt.timeLabel)"
    }

    var accentColor: Color {
        if let colorHex { return Color(hex: colorHex) }
        return Theme.Colors.palette[abs(role.hashValue) % Theme.Colors.palette.count]
    }
}

extension Shift {
    /// Returns true when two shifts assigned to the same user overlap in time.
    func clashes(with other: Shift) -> Bool {
        guard let a = assignedUserId, let b = other.assignedUserId, a == b, id != other.id else {
            return false
        }
        return startAt < other.endAt && other.startAt < endAt
    }
}
