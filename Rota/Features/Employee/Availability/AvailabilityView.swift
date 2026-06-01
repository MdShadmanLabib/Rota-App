import SwiftUI

@MainActor
@Observable
final class AvailabilityViewModel {
    struct DayPref: Identifiable {
        let weekday: Int            // 1=Mon...7=Sun
        var isAvailable: Bool
        var start: Date
        var end: Date
        var id: Int { weekday }
        var name: String { ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"][weekday - 1] }
    }

    var state: LoadState = .idle
    var days: [DayPref] = []
    var isSaving = false

    func load(repository: RotaRepository, userId: UUID) async {
        if state == .idle { state = .loading }
        do {
            let existing = try await repository.fetchAvailability(userId: userId)
            let byDay = Dictionary(uniqueKeysWithValues: existing.map { ($0.weekday, $0) })
            days = (1...7).map { weekday in
                if let a = byDay[weekday] {
                    return DayPref(weekday: weekday, isAvailable: a.isAvailable,
                                   start: Self.time(a.startTime, fallback: 9), end: Self.time(a.endTime, fallback: 17))
                }
                let weekend = weekday >= 6
                return DayPref(weekday: weekday, isAvailable: !weekend,
                               start: Self.time(nil, fallback: 9), end: Self.time(nil, fallback: 17))
            }
            state = .loaded
        } catch { state = .failed(AppError.from(error).errorDescription ?? "Failed to load availability") }
    }

    func save(repository: RotaRepository, userId: UUID, organizationId: UUID) async -> Bool {
        isSaving = true
        defer { isSaving = false }
        let items = days.map { day in
            Availability(id: UUID(), organizationId: organizationId, userId: userId, weekday: day.weekday,
                         isAvailable: day.isAvailable,
                         startTime: day.isAvailable ? day.start.timeLabel : nil,
                         endTime: day.isAvailable ? day.end.timeLabel : nil)
        }
        do { _ = try await repository.upsertAvailability(items); return true }
        catch { return false }
    }

    private static func time(_ value: String?, fallback hour: Int) -> Date {
        let parts = (value ?? "").split(separator: ":").compactMap { Int($0) }
        var comps = DateComponents()
        comps.hour = parts.first ?? hour
        comps.minute = parts.count > 1 ? parts[1] : 0
        return Calendar.current.date(from: comps) ?? Date()
    }
}

struct AvailabilityView: View {
    @Environment(SessionStore.self) private var session
    @Environment(ToastCenter.self) private var toasts
    @State private var vm = AvailabilityViewModel()

    var body: some View {
        Form {
            Section {
                Text("Let your manager know when you can work. This helps with smarter scheduling.")
                    .font(.Rota.footnote).foregroundColor(Theme.Colors.textSecondary)
            }
            ForEach($vm.days) { $day in
                Section {
                    Toggle(isOn: $day.isAvailable) {
                        Text(fullName(day.weekday)).font(.Rota.headline)
                    }
                    if day.isAvailable {
                        DatePicker("From", selection: $day.start, displayedComponents: .hourAndMinute)
                        DatePicker("To", selection: $day.end, displayedComponents: .hourAndMinute)
                    }
                }
            }
        }
        .navigationTitle("Availability")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { save() } label: {
                    if vm.isSaving { ProgressView() } else { Text("Save").fontWeight(.semibold) }
                }
                .disabled(vm.isSaving)
            }
        }
        .task {
            guard let user = session.currentUser else { return }
            await vm.load(repository: session.repository, userId: user.id)
        }
    }

    private func fullName(_ weekday: Int) -> String {
        ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"][weekday - 1]
    }

    private func save() {
        guard let user = session.currentUser, let orgId = user.organizationId else { return }
        Task {
            if await vm.save(repository: session.repository, userId: user.id, organizationId: orgId) {
                Haptics.success(); toasts.show("Availability saved")
            } else { toasts.error("Couldn't save availability") }
        }
    }
}
