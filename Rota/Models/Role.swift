import SwiftUI

/// Organization role. Drives role-based access throughout the app.
enum Role: String, Codable, CaseIterable, Identifiable, Sendable {
    case owner
    case admin
    case manager
    case employee

    var id: String { rawValue }

    var title: String {
        switch self {
        case .owner: return "Owner"
        case .admin: return "Admin"
        case .manager: return "Manager"
        case .employee: return "Employee"
        }
    }

    /// Whether this role manages the workforce (employer side of the app).
    var isManager: Bool {
        switch self {
        case .owner, .admin, .manager: return true
        case .employee: return false
        }
    }

    /// Capability checks (role-based access).
    var canManageShifts: Bool { isManager }
    var canApproveRequests: Bool { isManager }
    var canManageTeam: Bool { self == .owner || self == .admin }
    var canManageBilling: Bool { self == .owner }

    var badgeTone: BadgeTone {
        switch self {
        case .owner: return .accent
        case .admin: return .info
        case .manager: return .warning
        case .employee: return .neutral
        }
    }
}
