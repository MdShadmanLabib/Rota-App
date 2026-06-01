import SwiftUI

struct TeamView: View {
    @Environment(SessionStore.self) private var session
    @Environment(ToastCenter.self) private var toasts
    @State private var vm = TeamViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.md) {
                inviteCard
                ForEach(vm.filteredTeam) { member in
                    TeamMemberRow(
                        member: member,
                        hours: vm.hoursByUser[member.id] ?? 0,
                        isActive: vm.activeUserIds.contains(member.id)
                    )
                }
                if vm.state.isLoading && vm.team.isEmpty {
                    ForEach(0..<4, id: \.self) { _ in SkeletonCard() }
                }
            }
            .padding(Theme.Spacing.lg)
        }
        .background(Theme.Colors.background)
        .navigationTitle("Team")
        .searchable(text: $vm.searchText, prompt: "Search teammates")
        .refreshable { await reload() }
        .task { await reload() }
    }

    private func reload() async {
        guard let orgId = session.organization?.id else { return }
        await vm.load(repository: session.repository, organizationId: orgId)
    }

    private var inviteCard: some View {
        RotaCard {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Invite code").font(.Rota.footnote).foregroundColor(Theme.Colors.textSecondary)
                    Text(session.organization?.inviteCode ?? "—")
                        .font(.system(size: 26, weight: .bold, design: .monospaced))
                        .foregroundColor(Theme.Colors.accent)
                    Text("Share with staff to let them join \(session.organization?.name ?? "your team").")
                        .font(.Rota.caption).foregroundColor(Theme.Colors.textTertiary)
                }
                Spacer()
                Button {
                    UIPasteboard.general.string = session.organization?.inviteCode
                    Haptics.success(); toasts.show("Invite code copied")
                } label: {
                    Image(systemName: "doc.on.doc.fill")
                        .font(.system(size: 18))
                        .foregroundColor(Theme.Colors.accent)
                        .frame(width: 44, height: 44)
                        .background(Theme.Colors.accentSoft)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous))
                }
            }
        }
    }
}

struct TeamMemberRow: View {
    let member: UserProfile
    let hours: Double
    let isActive: Bool

    var body: some View {
        RotaCard {
            HStack(spacing: Theme.Spacing.md) {
                ZStack(alignment: .bottomTrailing) {
                    Avatar(name: member.fullName, size: 48, imageURL: member.avatarURL)
                    if isActive {
                        Circle().fill(Theme.Colors.success)
                            .frame(width: 13, height: 13)
                            .overlay(Circle().stroke(Theme.Colors.surface, lineWidth: 2))
                    }
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(member.fullName).font(.Rota.headline).foregroundColor(Theme.Colors.textPrimary)
                    HStack(spacing: 6) {
                        Badge(text: member.role.title, tone: member.role.badgeTone)
                        if let title = member.jobTitle {
                            Text(title).font(.Rota.caption).foregroundColor(Theme.Colors.textSecondary)
                        }
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(hours, specifier: "%.1f")h").font(.Rota.headline).foregroundColor(Theme.Colors.textPrimary)
                    Text("this week").font(.Rota.caption2).foregroundColor(Theme.Colors.textTertiary)
                }
            }
        }
    }
}
