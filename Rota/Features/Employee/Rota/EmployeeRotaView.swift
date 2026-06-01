import SwiftUI

@MainActor
@Observable
final class EmployeeRotaViewModel {
    var state: LoadState = .idle
    var weekStart = Date().startOfWeek
    var shifts: [Shift] = []

    var weeklyHours: Double { shifts.reduce(0) { $0 + $1.paidDuration.decimalHours } }

    func shifts(on day: Date) -> [Shift] {
        shifts.filter { $0.startAt.isSameDay(as: day) }.sorted { $0.startAt < $1.startAt }
    }

    func load(repository: RotaRepository, userId: UUID) async {
        if state == .idle { state = .loading }
        let from = weekStart
        let to = weekStart.adding(days: 6).adding(days: 1)
        do {
            shifts = try await repository.fetchShifts(forUser: userId, from: from, to: to)
            state = .loaded
        } catch { state = .failed(AppError.from(error).errorDescription ?? "Failed to load rota") }
    }
}

struct EmployeeRotaView: View {
    @Environment(SessionStore.self) private var session
    @State private var vm = EmployeeRotaViewModel()

    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            WeekNavigator(weekStart: $vm.weekStart) { reloadTask() }
                .padding(.horizontal, Theme.Spacing.lg)

            RotaCard(background: Theme.Colors.accentSoft) {
                HStack {
                    Label("\(vm.weeklyHours, specifier: "%.1f") hours scheduled", systemImage: "clock.fill")
                        .font(.Rota.subheadline).foregroundColor(Theme.Colors.accent)
                    Spacer()
                    Text("\(vm.shifts.count) shifts").font(.Rota.caption).foregroundColor(Theme.Colors.textSecondary)
                }
            }
            .padding(.horizontal, Theme.Spacing.lg)

            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    if vm.state.isLoading && vm.shifts.isEmpty {
                        ForEach(0..<3, id: \.self) { _ in SkeletonCard() }
                    } else if vm.shifts.isEmpty {
                        EmptyStateView(icon: "calendar", title: "No shifts this week",
                                       message: "You have no shifts scheduled for this week.")
                            .padding(.top, Theme.Spacing.xl)
                    } else {
                        ForEach(vm.weekStart.weekDays, id: \.self) { day in
                            let dayShifts = vm.shifts(on: day)
                            if !dayShifts.isEmpty {
                                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                                    Text(day.formatted("EEEE d MMM"))
                                        .font(.Rota.headline)
                                        .foregroundColor(day.isToday ? Theme.Colors.accent : Theme.Colors.textPrimary)
                                    ForEach(dayShifts) { shift in ShiftCard(shift: shift) }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.bottom, Theme.Spacing.xxl)
            }
        }
        .padding(.top, Theme.Spacing.sm)
        .background(Theme.Colors.background)
        .navigationTitle("My Rota")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable { await reload() }
        .task { await reload() }
    }

    private func reloadTask() { Task { await reload() } }
    private func reload() async {
        guard let user = session.currentUser else { return }
        await vm.load(repository: session.repository, userId: user.id)
    }
}
