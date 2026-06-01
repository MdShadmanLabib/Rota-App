import SwiftUI

struct EmployeeMoreView: View {
    @Environment(SessionStore.self) private var session

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                profileHeader

                VStack(spacing: Theme.Spacing.sm) {
                    NavigationLink { WorkedHoursView() } label: {
                        MoreRow(icon: "clock.fill", title: "My hours", tint: Theme.Colors.accent)
                    }
                    NavigationLink { AvailabilityView() } label: {
                        MoreRow(icon: "calendar.badge.clock", title: "Availability", tint: Theme.Colors.success)
                    }
                    NavigationLink { AnnouncementsView() } label: {
                        MoreRow(icon: "megaphone.fill", title: "Announcements", tint: Theme.Colors.violet)
                    }
                }

                VStack(spacing: Theme.Spacing.sm) {
                    NavigationLink { ProfileView() } label: {
                        MoreRow(icon: "person.crop.circle.fill", title: "My profile", tint: Theme.Colors.textSecondary)
                    }
                    NavigationLink { AppSettingsView() } label: {
                        MoreRow(icon: "gearshape.fill", title: "Settings", tint: Theme.Colors.textSecondary)
                    }
                }
            }
            .padding(Theme.Spacing.lg)
        }
        .background(Theme.Colors.background)
        .navigationTitle("Profile")
    }

    private var profileHeader: some View {
        RotaCard {
            HStack(spacing: Theme.Spacing.md) {
                Avatar(name: session.currentUser?.fullName ?? "U", size: 56, imageURL: session.currentUser?.avatarURL)
                VStack(alignment: .leading, spacing: 3) {
                    Text(session.currentUser?.fullName ?? "User").font(.Rota.title3).foregroundColor(Theme.Colors.textPrimary)
                    Text(session.currentUser?.jobTitle ?? session.organization?.name ?? "")
                        .font(.Rota.footnote).foregroundColor(Theme.Colors.textSecondary)
                    if let role = session.currentUser?.role { Badge(text: role.title, tone: role.badgeTone) }
                }
                Spacer()
            }
        }
    }
}
