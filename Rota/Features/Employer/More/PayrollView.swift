import SwiftUI

@MainActor
@Observable
final class PayrollViewModel {
    struct Row: Identifiable { let id: UUID; let name: String; let hours: Double; let rate: Double?; var pay: Double? { rate.map { $0 * hours } } }
    var state: LoadState = .idle
    var rows: [Row] = []
    var totalHours = 0.0
    var totalPay = 0.0

    func load(repository: RotaRepository, organizationId: UUID) async {
        if state == .idle { state = .loading }
        let from = Date().startOfWeek
        let to = from.adding(days: 6).adding(days: 1)
        do {
            async let entriesTask = repository.fetchTimeEntries(organizationId: organizationId, from: from, to: to)
            async let teamTask = repository.fetchTeam(organizationId: organizationId)
            let (entries, team) = try await (entriesTask, teamTask)
            let hoursByUser = entries.reduce(into: [UUID: Double]()) { $0[$1.userId, default: 0] += $1.duration.decimalHours }
            rows = team.compactMap { member in
                let hours = hoursByUser[member.id] ?? 0
                guard hours > 0 else { return nil }
                return Row(id: member.id, name: member.fullName, hours: hours, rate: member.hourlyRate)
            }.sorted { $0.hours > $1.hours }
            totalHours = rows.reduce(0) { $0 + $1.hours }
            totalPay = rows.reduce(0) { $0 + ($1.pay ?? 0) }
            state = .loaded
        } catch { state = .failed(AppError.from(error).errorDescription ?? "Failed to load") }
    }
}

struct PayrollView: View {
    @Environment(SessionStore.self) private var session
    @State private var vm = PayrollViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.md) {
                RotaCard(background: Theme.Colors.accentSoft) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("This week").font(.Rota.footnote).foregroundColor(Theme.Colors.textSecondary)
                            Text("\(vm.totalHours, specifier: "%.1f") hours").font(.Rota.title2).foregroundColor(Theme.Colors.textPrimary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Est. cost").font(.Rota.footnote).foregroundColor(Theme.Colors.textSecondary)
                            Text("£\(vm.totalPay, specifier: "%.0f")").font(.Rota.title2).foregroundColor(Theme.Colors.accent)
                        }
                    }
                }

                if vm.rows.isEmpty && !vm.state.isLoading {
                    EmptyStateView(icon: "sterlingsign.circle", title: "No hours yet",
                                   message: "Worked hours from clock‑ins will appear here.")
                } else {
                    ForEach(vm.rows) { row in
                        RotaCard {
                            HStack(spacing: Theme.Spacing.md) {
                                Avatar(name: row.name, size: 40)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(row.name).font(.Rota.headline).foregroundColor(Theme.Colors.textPrimary)
                                    if let rate = row.rate {
                                        Text("£\(rate, specifier: "%.2f")/h").font(.Rota.caption).foregroundColor(Theme.Colors.textSecondary)
                                    }
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("\(row.hours, specifier: "%.1f")h").font(.Rota.headline).foregroundColor(Theme.Colors.textPrimary)
                                    if let pay = row.pay {
                                        Text("£\(pay, specifier: "%.0f")").font(.Rota.caption).foregroundColor(Theme.Colors.accent)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding(Theme.Spacing.lg)
        }
        .background(Theme.Colors.background)
        .navigationTitle("Payroll")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            guard let orgId = session.organization?.id else { return }
            await vm.load(repository: session.repository, organizationId: orgId)
        }
    }
}
