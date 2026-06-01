import Foundation

enum LeaveType: String, Codable, CaseIterable, Identifiable, Sendable {
    case holiday
    case sick
    case unpaid
    case parental
    case other

    var id: String { rawValue }
    var label: String {
        switch self {
        case .holiday: return "Holiday"
        case .sick: return "Sick"
        case .unpaid: return "Unpaid"
        case .parental: return "Parental"
        case .other: return "Other"
        }
    }
    var icon: String {
        switch self {
        case .holiday: return "sun.max.fill"
        case .sick: return "cross.case.fill"
        case .unpaid: return "creditcard.fill"
        case .parental: return "figure.and.child.holdinghands"
        case .other: return "ellipsis.circle.fill"
        }
    }
}

enum RequestStatus: String, Codable, Sendable {
    case pending
    case approved
    case rejected
    case cancelled

    var label: String { rawValue.capitalized }
    var tone: BadgeTone {
        switch self {
        case .pending: return .warning
        case .approved: return .success
        case .rejected: return .danger
        case .cancelled: return .neutral
        }
    }
}

struct LeaveRequest: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var organizationId: UUID
    var userId: UUID
    var type: LeaveType
    var startDate: Date
    var endDate: Date
    var reason: String?
    var status: RequestStatus
    var reviewedBy: UUID?
    var createdAt: Date

    var dayCount: Int {
        let days = Calendar.current.dateComponents([.day], from: startDate.startOfDay, to: endDate.startOfDay).day ?? 0
        return max(1, days + 1)
    }

    var rangeLabel: String {
        if startDate.isSameDay(as: endDate) { return startDate.formatted("EEE d MMM") }
        return "\(startDate.formatted("d MMM")) – \(endDate.formatted("d MMM"))"
    }
}
