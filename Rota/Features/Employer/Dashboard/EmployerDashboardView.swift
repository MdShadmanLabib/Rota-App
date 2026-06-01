import SwiftUI
import Charts

struct EmployerDashboardView: View {
    @Environment(SessionStore.self) private var session
    @State private var vm = EmployerDashboardViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                greeting

                if vm.state.isLoading && vm.shifts.isEmpty {
                    loadingState
                } else {
                    statsGrid
                    coverageCard
                    if !vm.overtimeNames.isEmpty { overtimeCard }
                    todaySection
                    requestsSummary
                }
            }
            .padding(Theme.Spacing.lg)
        }
        .background(Theme.Colors.background)
        .navigationTitle("Dashboard")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable { await reload() }
        .task { await reload() }
    }

    private func reload() async {
        guard let orgId = session.organization?.id else { return }
        await vm.load(repository: session.repository, organizationId: orgId)
    }

    private var greeting: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(greetingText)
                    .font(.Rota.footnote)
                    .foregroundColor(Theme.Colors.textSecondary)
                Text(session.currentUser?.firstName ?? "There")
                    .font(.Rota.title)
                    .foregroundColor(Theme.Colors.textPrimary)
            }
            Spacer()
            Avatar(name: session.currentUser?.fullName ?? "U", size: 46,
                   imageURL: session.currentUser?.avatarURL)
        }
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Theme.Spacing.sm) {
            StatTile(title: "Scheduled this week", value: "\(Int(vm.weeklyHours))h", icon: "clock.fill", tone: .accent)
            StatTile(title: "On the clock", value: "\(vm.onTheClock)", icon: "dot.radiowaves.left.and.right", tone: .success)
            StatTile(title: "Open shifts", value: "\(vm.openShiftCount)", icon: "calendar.badge.exclamationmark", tone: .warning)
            StatTile(title: "Pending requests", value: "\(vm.pendingRequests)", icon: "tray.full.fill", tone: .info)
        }
    }

    private var coverageCard: some View {
        RotaCard {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                Text("Staffing coverage")
                    .font(.Rota.title3)
                    .foregroundColor(Theme.Colors.textPrimary)
                Chart(vm.coverage(weekStart: Date().startOfWeek), id: \.day) { item in
                    BarMark(
                        x: .value("Day", item.day.weekdayShort),
                        y: .value("Shifts", item.count)
                    )
                    .foregroundStyle(
                        LinearGradient(colors: [Theme.Colors.accent, Theme.Colors.violet],
                                       startPoint: .top, endPoint: .bottom)
                    )
                    .cornerRadius(6)
                }
                .frame(height: 160)
                .chartYAxis { AxisMarks(position: .leading) }
            }
        }
    }

    private var overtimeCard: some View {
        RotaCard(background: Theme.Colors.warningSoft) {
            HStack(alignment: .top, spacing: Theme.Spacing.sm) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(Theme.Colors.warning)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Overtime warning")
                        .font(.Rota.headline)
                        .foregroundColor(Theme.Colors.textPrimary)
                    Text("\(vm.overtimeNames.joined(separator: ", ")) exceed 40h this week.")
                        .font(.Rota.footnote)
                        .foregroundColor(Theme.Colors.textSecondary)
                }
            }
        }
    }

    private var todaySection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            SectionHeader(title: "Today")
            if vm.todayShifts.isEmpty {
                RotaCard {
                    Text("No shifts scheduled today.")
                        .font(.Rota.callout)
                        .foregroundColor(Theme.Colors.textSecondary)
                }
            } else {
                ForEach(vm.todayShifts) { shift in
                    ShiftCard(shift: shift, assigneeName: vm.name(for: shift.assignedUserId))
                }
            }
        }
    }

    private var requestsSummary: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            SectionHeader(title: "Needs attention")
            let pending = vm.leave.filter { $0.status == .pending }
            if pending.isEmpty {
                RotaCard {
                    HStack {
                        Image(systemName: "checkmark.seal.fill").foregroundColor(Theme.Colors.success)
                        Text("All caught up — no pending requests.")
                            .font(.Rota.callout)
                            .foregroundColor(Theme.Colors.textSecondary)
                    }
                }
            } else {
                ForEach(pending.prefix(3)) { request in
                    LeaveRequestRow(request: request, name: vm.name(for: request.userId))
                }
            }
        }
    }

    private var loadingState: some View {
        VStack(spacing: Theme.Spacing.sm) {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Theme.Spacing.sm) {
                ForEach(0..<4, id: \.self) { _ in SkeletonView(cornerRadius: Theme.Radius.lg).frame(height: 96) }
            }
            ForEach(0..<3, id: \.self) { _ in SkeletonCard() }
        }
    }
}
