import SwiftUI

struct MoreView: View {
    @Environment(SessionStore.self) private var session

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                profileHeader

                VStack(spacing: Theme.Spacing.sm) {
                    NavigationLink { AnalyticsView() } label: {
                        MoreRow(icon: "chart.line.uptrend.xyaxis", title: "Analytics", tint: Theme.Colors.accent)
                    }
                    NavigationLink { AttendanceView() } label: {
                        MoreRow(icon: "clock.badge.checkmark.fill", title: "Attendance", tint: Theme.Colors.success)
                    }
                    NavigationLink { AnnouncementsView() } label: {
                        MoreRow(icon: "megaphone.fill", title: "Announcements", tint: Theme.Colors.violet)
                    }
                    NavigationLink { TemplatesView() } label: {
                        MoreRow(icon: "square.on.square", title: "Shift templates", tint: Theme.Colors.info)
                    }
                    NavigationLink { PayrollView() } label: {
                        MoreRow(icon: "sterlingsign.circle.fill", title: "Payroll summary", tint: Theme.Colors.warning)
                    }
                }

                VStack(spacing: Theme.Spacing.sm) {
                    NavigationLink { OrganizationSettingsView() } label: {
                        MoreRow(icon: "building.2.fill", title: "Organization settings", tint: Theme.Colors.textSecondary)
                    }
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
        .navigationTitle("More")
    }

    private var profileHeader: some View {
        RotaCard {
            HStack(spacing: Theme.Spacing.md) {
                Avatar(name: session.currentUser?.fullName ?? "U", size: 56, imageURL: session.currentUser?.avatarURL)
                VStack(alignment: .leading, spacing: 3) {
                    Text(session.currentUser?.fullName ?? "User").font(.Rota.title3).foregroundColor(Theme.Colors.textPrimary)
                    Text(session.organization?.name ?? "Organization").font(.Rota.footnote).foregroundColor(Theme.Colors.textSecondary)
                    if let role = session.currentUser?.role { Badge(text: role.title, tone: role.badgeTone) }
                }
                Spacer()
            }
        }
    }
}

struct MoreRow: View {
    let icon: String
    let title: String
    var tint: Color = Theme.Colors.accent

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous).fill(tint.opacity(0.15)).frame(width: 38, height: 38)
                Image(systemName: icon).foregroundColor(tint).font(.system(size: 16, weight: .semibold))
            }
            Text(title).font(.Rota.bodyMedium).foregroundColor(Theme.Colors.textPrimary)
            Spacer()
            Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold)).foregroundColor(Theme.Colors.textTertiary)
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
        .themeShadow(.soft)
    }
}
