import SwiftUI

@MainActor
@Observable
final class AnnouncementsViewModel {
    var state: LoadState = .idle
    var announcements: [Announcement] = []

    func load(repository: RotaRepository, organizationId: UUID) async {
        if state == .idle { state = .loading }
        do {
            announcements = try await repository.fetchAnnouncements(organizationId: organizationId)
            state = .loaded
        } catch {
            state = .failed(AppError.from(error).errorDescription ?? "Failed to load announcements")
        }
    }

    func post(title: String, body: String, pinned: Bool, author: UserProfile, organizationId: UUID, repository: RotaRepository) async {
        let announcement = Announcement(
            id: UUID(), organizationId: organizationId, authorId: author.id,
            authorName: author.fullName, title: title, body: body, isPinned: pinned, createdAt: .now
        )
        do {
            let created = try await repository.createAnnouncement(announcement)
            announcements.insert(created, at: 0)
            announcements.sort { ($0.isPinned ? 1 : 0, $0.createdAt) > ($1.isPinned ? 1 : 0, $1.createdAt) }
            Haptics.success()
        } catch { Haptics.error() }
    }

    func delete(_ announcement: Announcement, repository: RotaRepository) async {
        do {
            try await repository.deleteAnnouncement(id: announcement.id)
            announcements.removeAll { $0.id == announcement.id }
        } catch { Haptics.error() }
    }
}
