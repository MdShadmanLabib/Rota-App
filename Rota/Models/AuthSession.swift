import Foundation

/// Lightweight session info kept after authentication.
struct AuthSession: Codable, Hashable, Sendable {
    var userId: UUID
    var email: String
}

/// Payload used when registering a new account.
struct SignUpPayload: Sendable {
    var fullName: String
    var email: String
    var password: String
    var role: Role
    /// Employer flow: name of the organization to create.
    var organizationName: String?
    /// Employee flow: invite code of an existing organization.
    var inviteCode: String?
}
