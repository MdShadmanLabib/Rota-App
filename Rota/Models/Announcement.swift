import Foundation

/// A team announcement / message broadcast to the organization.
struct Announcement: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var organizationId: UUID
    var authorId: UUID
    var authorName: String
    var title: String
    var body: String
    var isPinned: Bool
    var createdAt: Date
}
