import SwiftUI

@MainActor
@Observable
final class RotaBuilderViewModel {
    var state: LoadState = .idle
    var weekStart: Date = Date().startOfWeek
    var selectedDay: Date = Date().startOfDay
    var shifts: [Shift] = []
    var team: [UserProfile] = []
    var templates: [ShiftTemplate] = []

    private var organizationId: UUID?
    private var createdBy: UUID?

    private var nameMap: [UUID: String] = [:]
    func name(for id: UUID?) -> String {
        guard let id else { return "Open shift" }
        return nameMap[id] ?? "Teammate"
    }

    var conflicts: [SchedulingEngine.Conflict] { SchedulingEngine.clashes(in: shifts) }
    func hasConflict(_ shift: Shift) -> Bool { conflicts.contains { $0.shiftIds.contains(shift.id) } }

    var weeklyHours: Double { shifts.reduce(0) { $0 + $1.paidDuration.decimalHours } }
    var openCount: Int { shifts.filter(\.isOpen).count }

    func shifts(on day: Date) -> [Shift] {
        shifts.filter { $0.startAt.isSameDay(as: day) }.sorted { $0.startAt < $1.startAt }
    }

    func configure(organizationId: UUID, createdBy: UUID?) {
        self.organizationId = organizationId
        self.createdBy = createdBy
    }

    func load(repository: RotaRepository) async {
        guard let orgId = organizationId else { return }
        if state == .idle { state = .loading }
        let from = weekStart
        let to = weekStart.adding(days: 6).adding(days: 1)
        do {
            async let shiftsTask = repository.fetchShifts(organizationId: orgId, from: from, to: to)
            async let teamTask = repository.fetchTeam(organizationId: orgId)
            async let templatesTask = repository.fetchTemplates(organizationId: orgId)
            let (s, t, tmpl) = try await (shiftsTask, teamTask, templatesTask)
            shifts = s
            team = t
            templates = tmpl
            nameMap = Dictionary(uniqueKeysWithValues: t.map { ($0.id, $0.fullName) })
            state = .loaded
        } catch {
            state = .failed(AppError.from(error).errorDescription ?? "Failed to load rota")
        }
    }

    func changeWeek(by weeks: Int, repository: RotaRepository) async {
        weekStart = weekStart.adding(weeks: weeks)
        if !selectedDay.isSameDay(as: Date()) || weeks != 0 {
            selectedDay = weekStart
        }
        await load(repository: repository)
    }

    func save(_ shift: Shift, repository: RotaRepository) async {
        do {
            if shifts.contains(where: { $0.id == shift.id }) {
                let updated = try await repository.updateShift(shift)
                if let idx = shifts.firstIndex(where: { $0.id == updated.id }) { shifts[idx] = updated }
            } else {
                let created = try await repository.createShift(shift)
                shifts.append(created)
            }
            Haptics.success()
        } catch { Haptics.error() }
    }

    func delete(_ shift: Shift, repository: RotaRepository) async {
        do {
            try await repository.deleteShift(id: shift.id)
            shifts.removeAll { $0.id == shift.id }
            Haptics.success()
        } catch { Haptics.error() }
    }

    func assign(_ shift: Shift, to userId: UUID?, repository: RotaRepository) async {
        do {
            let updated = try await repository.assignShift(shiftId: shift.id, to: userId)
            if let idx = shifts.firstIndex(where: { $0.id == updated.id }) { shifts[idx] = updated }
            Haptics.success()
        } catch { Haptics.error() }
    }

    func apply(template: ShiftTemplate, on day: Date, repository: RotaRepository) async {
        guard let orgId = organizationId else { return }
        let shift = template.makeShift(on: day, organizationId: orgId, createdBy: createdBy)
        await save(shift, repository: repository)
    }

    /// Runs the heuristic auto-scheduler over open shifts in the week.
    func autoSchedule(repository: RotaRepository) async -> Int {
        let open = shifts.filter(\.isOpen)
        guard !open.isEmpty else { return 0 }
        let suggestions = SchedulingEngine.autoAssign(openShifts: open, team: team, existing: shifts)
        var applied = 0
        for (shiftId, userId) in suggestions {
            if let shift = shifts.first(where: { $0.id == shiftId }) {
                await assign(shift, to: userId, repository: repository)
                applied += 1
            }
        }
        return applied
    }

    func newShiftTemplate(on day: Date) -> Shift {
        let start = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: day) ?? day
        return Shift(
            id: UUID(), organizationId: organizationId ?? UUID(), title: "Shift", role: "Floor",
            location: nil, startAt: start, endAt: start.addingTimeInterval(8 * 3600),
            breakMinutes: 30, assignedUserId: nil, status: .scheduled, notes: nil,
            colorHex: nil, createdBy: createdBy, createdAt: .now
        )
    }
}
