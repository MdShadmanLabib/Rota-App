import SwiftUI

struct EmployeeDashboardView: View {
    @Environment(SessionStore.self) private var session
    @State private var vm = EmployeeDashboardViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                greeting

                if vm.state.isLoading && vm.weekShifts.isEmpty {
                    SkeletonView(cornerRadius: Theme.Radius.xl).frame(height: 150)
                    ForEach(0..<3, id: \.self) { _ in SkeletonCard() }
                } else {
                    nextShiftCard
                    statsRow
                    if let announcement = vm.latestAnnouncement { announcementPeek(announcement) }
                    upcomingSection
                }
            }
            .padding(Theme.Spacing.lg)
        }
        .background(Theme.Colors.background)
        .navigationTitle("Home")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable { await reload() }
        .task { await reload() }
    }

    private func reload() async {
        guard let user = session.currentUser else { return }
        await vm.load(repository: session.repository, userId: user.id, organizationId: user.organizationId)
    }

    private var greeting: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Hi \(session.currentUser?.firstName ?? "there") 👋").font(.Rota.title).foregroundColor(Theme.Colors.textPrimary)
                Text(Date().formatted("EEEE d MMMM")).font(.Rota.footnote).foregroundColor(Theme.Colors.textSecondary)
            }
            Spacer()
            Avatar(name: session.currentUser?.fullName ?? "U", size: 46, imageURL: session.currentUser?.avatarURL)
        }
    }

    @ViewBuilder private var nextShiftCard: some View {
        if let shift = vm.nextShift {
            RotaCard(background: Theme.Colors.accent) {
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    HStack {
                        Label(shift.startAt.isToday ? "Today" : shift.startAt.relativeLabel, systemImage: "calendar")
                            .font(.Rota.subheadline).foregroundColor(.white.opacity(0.9))
                        Spacer()
                        Badge(text: shift.status.label, tone: .neutral)
                    }
                    Text(shift.title).font(.Rota.title2).foregroundColor(.white)
                    HStack(spacing: Theme.Spacing.md) {
                        Label(shift.timeRangeLabel, systemImage: "clock").foregroundColor(.white)
                        if let location = shift.location { Label(location, systemImage: "mappin").foregroundColor(.white.opacity(0.9)) }
                    }
                    .font(.Rota.callout)
                    Text("\(shift.paidDuration.hoursMinutes) paid").font(.Rota.caption).foregroundColor(.white.opacity(0.85))
                }
            }
        } else {
            RotaCard {
                HStack(spacing: Theme.Spacing.md) {
                    Image(systemName: "calendar.badge.checkmark").font(.system(size: 28)).foregroundColor(Theme.Colors.success)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("No upcoming shifts").font(.Rota.headline).foregroundColor(Theme.Colors.textPrimary)
                        Text("Enjoy your time off!").font(.Rota.footnote).foregroundColor(Theme.Colors.textSecondary)
                    }
                    Spacer()
                }
            }
        }
    }

    private var statsRow: some View {
        HStack(spacing: Theme.Spacing.sm) {
            StatTile(title: "This week", value: String(format: "%.1fh", vm.weeklyHours), icon: "clock.fill", tone: .accent)
            StatTile(title: "Shifts done", value: "\(vm.completedThisWeek)", icon: "checkmark.circle.fill", tone: .success)
            StatTile(title: "Status", value: vm.activeEntry != nil ? "On" : "Off", icon: "dot.radiowaves.left.and.right",
                     tone: vm.activeEntry != nil ? .success : .neutral)
        }
    }

    private func announcementPeek(_ announcement: Announcement) -> some View {
        NavigationLink { AnnouncementsView() } label: {
            RotaCard {
                HStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "megaphone.fill").foregroundColor(Theme.Colors.violet)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(announcement.title).font(.Rota.subheadline).foregroundColor(Theme.Colors.textPrimary).lineLimit(1)
                        Text(announcement.body).font(.Rota.caption).foregroundColor(Theme.Colors.textSecondary).lineLimit(1)
                    }
                    Spacer()
                    Image(systemName: "chevron.right").font(.system(size: 12, weight: .bold)).foregroundColor(Theme.Colors.textTertiary)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var upcomingSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            SectionHeader(title: "Upcoming shifts")
            let upcoming = vm.upcomingShifts.filter { $0.endAt > .now }
            if upcoming.isEmpty {
                EmptyStateView(icon: "calendar", title: "Nothing scheduled", message: "Your upcoming shifts will show up here.")
            } else {
                ForEach(upcoming.prefix(5)) { shift in
                    ShiftCard(shift: shift, showDate: true)
                }
            }
        }
    }
}
