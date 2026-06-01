import SwiftUI

struct AnnouncementsView: View {
    @Environment(SessionStore.self) private var session
    @Environment(ToastCenter.self) private var toasts
    @State private var vm = AnnouncementsViewModel()
    @State private var showComposer = false

    var canCompose: Bool { session.isManager }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.md) {
                if vm.state.isLoading && vm.announcements.isEmpty {
                    ForEach(0..<3, id: \.self) { _ in SkeletonCard() }
                } else if vm.announcements.isEmpty {
                    EmptyStateView(icon: "megaphone.fill", title: "No announcements",
                                   message: canCompose ? "Share updates with your team." : "Updates from your manager appear here.",
                                   actionTitle: canCompose ? "Post update" : nil) { showComposer = true }
                        .padding(.top, Theme.Spacing.xl)
                } else {
                    ForEach(vm.announcements) { item in
                        AnnouncementCard(announcement: item, canDelete: canCompose) {
                            Task { await vm.delete(item, repository: session.repository) }
                        }
                    }
                }
            }
            .padding(Theme.Spacing.lg)
        }
        .background(Theme.Colors.background)
        .navigationTitle("Announcements")
        .toolbar {
            if canCompose {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showComposer = true } label: { Image(systemName: "square.and.pencil") }
                }
            }
        }
        .sheet(isPresented: $showComposer) {
            AnnouncementComposer { title, body, pinned in
                guard let user = session.currentUser, let orgId = session.organization?.id else { return }
                Task {
                    await vm.post(title: title, body: body, pinned: pinned, author: user, organizationId: orgId, repository: session.repository)
                    toasts.show("Announcement posted")
                }
            }
        }
        .refreshable { await reload() }
        .task { await reload() }
    }

    private func reload() async {
        guard let orgId = session.organization?.id else { return }
        await vm.load(repository: session.repository, organizationId: orgId)
    }
}

struct AnnouncementCard: View {
    let announcement: Announcement
    var canDelete: Bool = false
    var onDelete: (() -> Void)? = nil

    var body: some View {
        RotaCard {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                HStack {
                    if announcement.isPinned { Badge(text: "Pinned", tone: .accent, icon: "pin.fill") }
                    Spacer()
                    Text(announcement.createdAt.formatted("d MMM")).font(.Rota.caption).foregroundColor(Theme.Colors.textTertiary)
                }
                Text(announcement.title).font(.Rota.title3).foregroundColor(Theme.Colors.textPrimary)
                Text(announcement.body).font(.Rota.callout).foregroundColor(Theme.Colors.textSecondary)
                HStack(spacing: 6) {
                    Avatar(name: announcement.authorName, size: 22)
                    Text(announcement.authorName).font(.Rota.caption).foregroundColor(Theme.Colors.textTertiary)
                }
                .padding(.top, 2)
            }
        }
        .contextMenu {
            if canDelete, let onDelete {
                Button(role: .destructive, action: onDelete) { Label("Delete", systemImage: "trash") }
            }
        }
    }
}

struct AnnouncementComposer: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var body = ""
    @State private var pinned = false
    let onPost: (String, String, Bool) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Announcement") {
                    TextField("Title", text: $title)
                    TextField("Write your message…", text: $body, axis: .vertical).lineLimit(4...10)
                }
                Section { Toggle("Pin to top", isOn: $pinned) }
            }
            .navigationTitle("New announcement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Post") { onPost(title, body, pinned); dismiss() }
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty || body.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
