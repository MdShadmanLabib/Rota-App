import SwiftUI
import Charts

@MainActor
@Observable
final class WorkedHoursViewModel {
    struct WeekBar: Identifiable { let id = UUID(); let label: String; let hours: Double }
    var state: LoadState = .idle
    var bars: [WeekBar] = []
    var totalHours = 0.0
    var thisWeekHours = 0.0
    var avgPerWeek = 0.0

    func load(repository: RotaRepository, userId: UUID) async {
        if state == .idle { state = .loading }
        let thisWeekStart = Date().startOfWeek
        let from = thisWeekStart.adding(weeks: -5)
        let to = thisWeekStart.adding(days: 7)
        do {
            let entries = try await repository.fetchTimeEntries(forUser: userId, from: from, to: to)
            var weekly: [Date: Double] = [:]
            for entry in entries where !entry.isActive {
                let ws = entry.clockInAt.startOfWeek
                weekly[ws, default: 0] += entry.duration.decimalHours
            }
            bars = (0..<6).map { offset in
                let ws = from.adding(weeks: offset)
                return WeekBar(label: ws.formatted("d MMM"), hours: (weekly[ws] ?? 0).rounded(toPlaces: 1))
            }
            totalHours = weekly.values.reduce(0, +)
            thisWeekHours = weekly[thisWeekStart] ?? 0
            let worked = bars.filter { $0.hours > 0 }
            avgPerWeek = worked.isEmpty ? 0 : worked.reduce(0) { $0 + $1.hours } / Double(worked.count)
            state = .loaded
        } catch { state = .failed(AppError.from(error).errorDescription ?? "Failed to load") }
    }
}

struct WorkedHoursView: View {
    @Environment(SessionStore.self) private var session
    @State private var vm = WorkedHoursViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.md) {
                HStack(spacing: Theme.Spacing.sm) {
                    StatTile(title: "This week", value: String(format: "%.1fh", vm.thisWeekHours), icon: "clock.fill", tone: .accent)
                    StatTile(title: "Avg / week", value: String(format: "%.1fh", vm.avgPerWeek), icon: "chart.bar.fill", tone: .info)
                    StatTile(title: "6‑wk total", value: String(format: "%.0fh", vm.totalHours), icon: "sum", tone: .success)
                }

                RotaCard {
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        Text("Hours worked").font(.Rota.headline).foregroundColor(Theme.Colors.textPrimary)
                        Chart(vm.bars) { bar in
                            BarMark(x: .value("Week", bar.label), y: .value("Hours", bar.hours))
                                .foregroundStyle(Theme.Colors.accent.gradient)
                                .cornerRadius(6)
                        }
                        .frame(height: 200)
                    }
                }

                if vm.totalHours == 0 && !vm.state.isLoading {
                    EmptyStateView(icon: "clock.arrow.circlepath", title: "No worked hours yet",
                                   message: "Clock in to start tracking your hours.")
                }
            }
            .padding(Theme.Spacing.lg)
        }
        .background(Theme.Colors.background)
        .navigationTitle("My hours")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            guard let user = session.currentUser else { return }
            await vm.load(repository: session.repository, userId: user.id)
        }
    }
}
