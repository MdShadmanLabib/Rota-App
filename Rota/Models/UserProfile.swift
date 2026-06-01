import Foundation

/// A user's profile, mirrored from the `profiles` table.
struct UserProfile: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var fullName: String
    var email: String
    var phone: String?
    var avatarURL: URL?
    var jobTitle: String?
    var role: Role
    var organizationId: UUID?
    var hourlyRate: Double?
    var createdAt: Date

    var firstName: String { fullName.split(separator: " ").first.map(String.init) ?? fullName }
}

extension UserProfile {
    static func placeholder(role: Role = .employee) -> UserProfile {
        UserProfile(
            id: UUID(),
            fullName: "New User",
            email: "",
            phone: nil,
            avatarURL: nil,
            jobTitle: nil,
            role: role,
            organizationId: nil,
            hourlyRate: nil,
            createdAt: .now
        )
    }
}
