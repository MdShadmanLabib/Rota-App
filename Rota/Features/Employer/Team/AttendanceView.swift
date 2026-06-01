import SwiftUI

@MainActor
@Observable
final class AttendanceViewModel {
    var state: LoadState = .idle
    var entries: [TimeEntry] = []
    private var nameMap: [UUID: String] = [:]
    func name(for id: UUID) -> String { nameMap[id] ?? "Teammate" }

    var active: [TimeEntry] { entries.filter(\.isActive) }
    var completed: [TimeEntry] { entries.filter { !$0.isActive } }

    func load(repository: RotaRepository, organizationId: UUID) async {
        if state == .idle { state = .loading }
        let from = Date().startOfWeek
        let to = from.adding(days: 6).adding(days: 1)
        do {
            async let entriesTask = repository.fetchTimeEntries(organizationId: organizationId, from: from, to: to)
            async let teamTask = repository.fetchTeam(organizationId: organizationId)
            let (e, t) = try await (entriesTask, teamTask)
            entries = e
            nameMap = Dictionary(uniqueKeysWithValues: t.map { ($0.id, $0.fullName) })
            state = .loaded
        } catch { state = .failed(AppError.from(error).errorDescription ?? "Failed to load") }
    }
}

struct AttendanceView: View {
    @Environment(SessionStore.self) private var session
    @State private var vm = AttendanceViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                section(title: "On the clock now", entries: vm.active, live: true)
                section(title: "Recent", entries: vm.completed, live: false)
            }
            .padding(Theme.Spacing.lg)
        }
        .background(Theme.Colors.background)
        .navigationTitle("Attendance")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable { await reload() }
        .task { await reload() }
    }

    private func reload() async {
        guard let orgId = session.organization?.id else { return }
        await vm.load(repository: session.repository, organizationId: orgId)
    }

    @ViewBuilder
    private func section(title: String, entries: [TimeEntry], live: Bool) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            SectionHeader(title: title)
            if entries.isEmpty {
                RotaCard { Text(live ? "Nobody is clocked in right now." : "No recent clock‑ins this week.")
                    .font(.Rota.callout).foregroundColor(Theme.Colors.textSecondary) }
            } else {
                ForEach(entries) { entry in
                    RotaCard {
                        HStack(spacing: Theme.Spacing.md) {
                            ZStack(alignment: .bottomTrailing) {
                                Avatar(name: vm.name(for: entry.userId), size: 44)
                                if live {
                                    Circle().fill(Theme.Colors.success).frame(width: 12, height: 12)
                                        .overlay(Circle().stroke(Theme.Colors.surface, lineWidth: 2))
                                }
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(vm.name(for: entry.userId)).font(.Rota.headline).foregroundColor(Theme.Colors.textPrimary)
                                Text("In \(entry.clockInAt.timeLabel)\(entry.clockOutAt.map { " · Out \($0.timeLabel)" } ?? "")")
                                    .font(.Rota.footnote).foregroundColor(Theme.Colors.textSecondary)
                            }
                            Spacer()
                            if live {
                                Badge(text: entry.duration.hoursMinutes, tone: .success, icon: "timer")
                            } else {
                                Text(entry.duration.hoursMinutes).font(.Rota.subheadline).foregroundColor(Theme.Colors.textPrimary)
                            }
                        }
                    }
                }
            }
        }
    }
}
