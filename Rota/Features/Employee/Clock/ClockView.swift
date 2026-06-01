import SwiftUI

struct ClockView: View {
    @Environment(SessionStore.self) private var session
    @Environment(ToastCenter.self) private var toasts
    @State private var vm = ClockViewModel()
    @State private var location = LocationProvider()

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                clockCard
                if let shift = vm.currentShift { shiftContextCard(shift) }
                recentSection
            }
            .padding(Theme.Spacing.lg)
        }
        .background(Theme.Colors.background)
        .navigationTitle("Time clock")
        .navigationBarTitleDisplayMode(.inline)
        .task { await reload() }
        .refreshable { await reload() }
    }

    private func reload() async {
        guard let user = session.currentUser else { return }
        await vm.load(repository: session.repository, userId: user.id)
    }

    private var isOnClock: Bool { vm.activeEntry != nil }

    private var clockCard: some View {
        RotaCard(background: isOnClock ? Theme.Colors.success : Theme.Colors.surface) {
            VStack(spacing: Theme.Spacing.md) {
                HStack(spacing: 6) {
                    Circle().fill(isOnClock ? .white : Theme.Colors.textTertiary).frame(width: 8, height: 8)
                    Text(isOnClock ? "On the clock" : "Off the clock")
                        .font(.Rota.subheadline)
                        .foregroundColor(isOnClock ? .white : Theme.Colors.textSecondary)
                }

                Text(isOnClock ? vm.elapsed.clockString : "--:--:--")
                    .font(.Rota.mono)
                    .foregroundColor(isOnClock ? .white : Theme.Colors.textPrimary)
                    .contentTransition(.numericText())

                if isOnClock, let entry = vm.activeEntry {
                    Text("Started at \(entry.clockInAt.timeLabel)")
                        .font(.Rota.footnote)
                        .foregroundColor(.white.opacity(0.85))
                }

                Button { toggle() } label: {
                    HStack(spacing: Theme.Spacing.xs) {
                        if vm.isWorking { ProgressView().tint(isOnClock ? Theme.Colors.success : .white) }
                        else { Image(systemName: isOnClock ? "stop.fill" : "play.fill") }
                        Text(isOnClock ? "Clock out" : "Clock in").fontWeight(.semibold)
                    }
                    .font(.Rota.headline)
                    .frame(maxWidth: .infinity).frame(height: 52)
                    .foregroundColor(isOnClock ? Theme.Colors.success : .white)
                    .background(isOnClock ? Color.white : Theme.Colors.accent)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
                }
                .buttonStyle(PressableCardStyle())
                .disabled(vm.isWorking)
            }
        }
    }

    private func shiftContextCard(_ shift: Shift) -> some View {
        RotaCard {
            HStack(spacing: Theme.Spacing.md) {
                RoundedRectangle(cornerRadius: 4).fill(shift.accentColor).frame(width: 5, height: 42)
                VStack(alignment: .leading, spacing: 2) {
                    Text(shift.title).font(.Rota.headline).foregroundColor(Theme.Colors.textPrimary)
                    Text(shift.timeRangeLabel).font(.Rota.footnote).foregroundColor(Theme.Colors.textSecondary)
                }
                Spacer()
                if let location = shift.location {
                    Label(location, systemImage: "mappin.circle.fill")
                        .font(.Rota.caption).foregroundColor(Theme.Colors.textSecondary)
                }
            }
        }
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            SectionHeader(title: "Recent activity")
            let completed = vm.recentEntries.filter { !$0.isActive }.sorted { $0.clockInAt > $1.clockInAt }
            if completed.isEmpty {
                EmptyStateView(icon: "clock.arrow.circlepath", title: "No history yet",
                               message: "Your clock‑in history will appear here.")
            } else {
                ForEach(completed) { entry in
                    RotaCard {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.clockInAt.formatted("EEE d MMM")).font(.Rota.subheadline).foregroundColor(Theme.Colors.textPrimary)
                                Text("\(entry.clockInAt.timeLabel) – \(entry.clockOutAt?.timeLabel ?? "—")")
                                    .font(.Rota.caption).foregroundColor(Theme.Colors.textSecondary)
                            }
                            Spacer()
                            Text(entry.duration.hoursMinutes).font(.Rota.headline).foregroundColor(Theme.Colors.accent)
                        }
                    }
                }
            }
        }
    }

    private func toggle() {
        guard let user = session.currentUser, let orgId = user.organizationId else { return }
        Task {
            if isOnClock {
                if let err = await vm.clockOut(repository: session.repository, userId: user.id) {
                    toasts.error(err)
                } else {
                    Haptics.success(); toasts.show("Clocked out")
                }
            } else {
                let loc = await location.currentLocation()
                if let err = await vm.clockIn(repository: session.repository, userId: user.id,
                                              organizationId: orgId, organization: session.organization, location: loc) {
                    toasts.error(err)
                } else {
                    Haptics.success(); toasts.show("Clocked in")
                }
            }
        }
    }
}
