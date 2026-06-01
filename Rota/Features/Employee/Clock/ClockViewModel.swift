import Foundation
import CoreLocation

@MainActor
@Observable
final class ClockViewModel {
    var state: LoadState = .idle
    var activeEntry: TimeEntry?
    var todayShifts: [Shift] = []
    var recentEntries: [TimeEntry] = []
    var isWorking = false
    var elapsed: TimeInterval = 0

    private var timerTask: Task<Void, Never>?

    /// The shift most relevant to clock into right now.
    var currentShift: Shift? {
        let now = Date()
        return todayShifts.first { $0.startAt.addingTimeInterval(-3600) <= now && $0.endAt.addingTimeInterval(3600) >= now }
            ?? todayShifts.first { $0.endAt > now }
    }

    func load(repository: RotaRepository, userId: UUID) async {
        if state == .idle { state = .loading }
        let dayStart = Date().startOfDay
        let dayEnd = dayStart.adding(days: 1)
        let weekAgo = dayStart.adding(days: -7)
        do {
            async let active = repository.activeTimeEntry(userId: userId)
            async let shifts = repository.fetchShifts(forUser: userId, from: dayStart, to: dayEnd)
            async let entries = repository.fetchTimeEntries(forUser: userId, from: weekAgo, to: dayEnd)
            activeEntry = try await active
            todayShifts = try await shifts
            recentEntries = try await entries
            state = .loaded
            startTimerIfNeeded()
        } catch { state = .failed(AppError.from(error).errorDescription ?? "Failed to load") }
    }

    func clockIn(repository: RotaRepository, userId: UUID, organizationId: UUID, organization: Organization?, location: CLLocation?) async -> String? {
        guard activeEntry == nil else { return nil }
        if let org = organization, let lat = org.workplaceLatitude, let lng = org.workplaceLongitude {
            guard let loc = location else { return "Location needed to clock in. Enable location access." }
            let distance = LocationProvider.distance(from: loc.coordinate, toLat: lat, lng: lng)
            if distance > org.clockInRadiusMeters {
                return "You're \(Int(distance))m from work. Move closer to clock in."
            }
        }
        isWorking = true
        defer { isWorking = false }
        let entry = TimeEntry(
            id: UUID(), organizationId: organizationId, userId: userId,
            shiftId: currentShift?.id, clockInAt: .now, clockOutAt: nil,
            clockInLat: location?.coordinate.latitude, clockInLng: location?.coordinate.longitude,
            method: location != nil ? "geo" : "manual", createdAt: .now
        )
        do {
            activeEntry = try await repository.clockIn(entry)
            startTimerIfNeeded()
            return nil
        } catch { return AppError.from(error).errorDescription }
    }

    func clockOut(repository: RotaRepository, userId: UUID) async -> String? {
        guard let entry = activeEntry else { return nil }
        isWorking = true
        defer { isWorking = false }
        do {
            _ = try await repository.clockOut(entryId: entry.id, at: .now)
            activeEntry = nil
            stopTimer()
            let weekAgo = Date().startOfDay.adding(days: -7)
            recentEntries = (try? await repository.fetchTimeEntries(forUser: userId, from: weekAgo, to: Date().adding(days: 1))) ?? recentEntries
            return nil
        } catch { return AppError.from(error).errorDescription }
    }

    private func startTimerIfNeeded() {
        stopTimer()
        guard let entry = activeEntry else { return }
        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                await MainActor.run { self?.elapsed = Date().timeIntervalSince(entry.clockInAt) }
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }

    private func stopTimer() {
        timerTask?.cancel()
        timerTask = nil
        elapsed = 0
    }

    deinit { timerTask?.cancel() }
}
