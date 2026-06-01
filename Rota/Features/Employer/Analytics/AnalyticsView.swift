import SwiftUI
import Charts

struct AnalyticsView: View {
    @Environment(SessionStore.self) private var session
    @State private var vm = AnalyticsViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                if vm.state.isLoading && vm.dayMetrics.isEmpty {
                    ForEach(0..<3, id: \.self) { _ in SkeletonView(cornerRadius: Theme.Radius.lg).frame(height: 180) }
                } else {
                    summaryGrid
                    hoursChart
                    productivityChart
                    distributionChart
                    topEmployeesCard
                }
            }
            .padding(Theme.Spacing.lg)
        }
        .background(Theme.Colors.background)
        .navigationTitle("Analytics")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable { await reload() }
        .task { await reload() }
    }

    private func reload() async {
        guard let orgId = session.organization?.id else { return }
        await vm.load(repository: session.repository, organizationId: orgId,
                      overtimeThreshold: session.organization?.weeklyOvertimeThreshold ?? 40)
    }

    private var summaryGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Theme.Spacing.sm) {
            StatTile(title: "Scheduled hours", value: "\(Int(vm.totalScheduled))h", icon: "calendar", tone: .accent)
            StatTile(title: "Worked hours", value: "\(Int(vm.totalWorked))h", icon: "clock.fill", tone: .success)
            StatTile(title: "Attendance", value: "\(Int(vm.attendanceRate * 100))%", icon: "checkmark.seal.fill", tone: .info)
            StatTile(title: "Overtime", value: "\(Int(vm.overtimeHours))h", icon: "exclamationmark.triangle.fill",
                     tone: vm.overtimeHours > 0 ? .warning : .success)
        }
    }

    private var hoursChart: some View {
        RotaCard {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                Text("Hours worked").font(.Rota.title3).foregroundColor(Theme.Colors.textPrimary)
                Chart(vm.dayMetrics) { metric in
                    BarMark(x: .value("Day", metric.label), y: .value("Hours", metric.workedHours))
                        .foregroundStyle(Theme.Colors.accent.gradient)
                        .cornerRadius(6)
                }
                .frame(height: 170)
            }
        }
    }

    private var productivityChart: some View {
        RotaCard {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                Text("Scheduled vs worked").font(.Rota.title3).foregroundColor(Theme.Colors.textPrimary)
                Chart {
                    ForEach(vm.dayMetrics) { metric in
                        LineMark(x: .value("Day", metric.label), y: .value("Scheduled", metric.scheduledHours))
                            .foregroundStyle(Theme.Colors.violet)
                            .symbol(.circle)
                            .interpolationMethod(.catmullRom)
                    }
                    ForEach(vm.dayMetrics) { metric in
                        AreaMark(x: .value("Day", metric.label), y: .value("Worked", metric.workedHours))
                            .foregroundStyle(Theme.Colors.accent.opacity(0.18))
                            .interpolationMethod(.catmullRom)
                    }
                }
                .frame(height: 170)
                HStack(spacing: Theme.Spacing.md) {
                    LegendDot(color: Theme.Colors.violet, label: "Scheduled")
                    LegendDot(color: Theme.Colors.accent, label: "Worked")
                }
            }
        }
    }

    private var distributionChart: some View {
        RotaCard {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                Text("Shift distribution by role").font(.Rota.title3).foregroundColor(Theme.Colors.textPrimary)
                Chart(vm.roleSlices) { slice in
                    SectorMark(
                        angle: .value("Hours", slice.hours),
                        innerRadius: .ratio(0.6),
                        angularInset: 2
                    )
                    .foregroundStyle(by: .value("Role", slice.role))
                    .cornerRadius(4)
                }
                .frame(height: 200)
                .chartLegend(position: .bottom, spacing: Theme.Spacing.sm)
            }
        }
    }

    private var topEmployeesCard: some View {
        RotaCard {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                Text("Top performers").font(.Rota.title3).foregroundColor(Theme.Colors.textPrimary)
                if vm.topEmployees.isEmpty {
                    Text("No worked hours recorded yet.").font(.Rota.callout).foregroundColor(Theme.Colors.textSecondary)
                } else {
                    ForEach(Array(vm.topEmployees.enumerated()), id: \.element.id) { index, employee in
                        HStack(spacing: Theme.Spacing.sm) {
                            Text("\(index + 1)").font(.Rota.headline).foregroundColor(Theme.Colors.textTertiary).frame(width: 20)
                            Avatar(name: employee.name, size: 34)
                            Text(employee.name).font(.Rota.bodyMedium).foregroundColor(Theme.Colors.textPrimary)
                            Spacer()
                            Text("\(employee.hours, specifier: "%.1f")h").font(.Rota.subheadline).foregroundColor(Theme.Colors.accent)
                        }
                        if index < vm.topEmployees.count - 1 { Divider() }
                    }
                }
            }
        }
    }
}

struct LegendDot: View {
    let color: Color
    let label: String
    var body: some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 9, height: 9)
            Text(label).font(.Rota.caption).foregroundColor(Theme.Colors.textSecondary)
        }
    }
}
