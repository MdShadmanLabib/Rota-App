import Foundation

/// In-memory repository backed by `SampleData`. Simulates network latency and
/// persists the signed-in session so the demo feels real across launches.
actor MockRepository: RotaRepository {

    private var data: SampleData
    private var sessionUserId: UUID?

    private let sessionKey = "rota.mock.sessionUserId"

    init() {
        self.data = SampleData.build()
        if let stored = UserDefaults.standard.string(forKey: sessionKey),
           let uuid = UUID(uuidString: stored) {
            self.sessionUserId = uuid
        }
    }

    private func delay() async {
        try? await Task.sleep(for: .milliseconds(UInt64.random(in: 220...520)))
    }

    private func persistSession() {
        if let id = sessionUserId {
            UserDefaults.standard.set(id.uuidString, forKey: sessionKey)
        } else {
            UserDefaults.standard.removeObject(forKey: sessionKey)
        }
    }

    // MARK: Auth

    func currentSession() async -> AuthSession? {
        guard let id = sessionUserId, let p = data.profiles.first(where: { $0.id == id }) else { return nil }
        return AuthSession(userId: p.id, email: p.email)
    }

    func signIn(email: String, password: String) async throws -> AuthSession {
        await delay()
        let normalized = email.lowercased().trimmingCharacters(in: .whitespaces)
        guard let profile = data.profiles.first(where: { $0.email.lowercased() == normalized }) else {
            throw AppError.invalidCredentials
        }
        // Mock mode accepts the shared demo password for any seeded account.
        guard password == SampleData.demoPassword else { throw AppError.invalidCredentials }
        sessionUserId = profile.id
        persistSession()
        return AuthSession(userId: profile.id, email: profile.email)
    }

    func signUp(_ payload: SignUpPayload) async throws -> AuthSession {
        await delay()
        let normalized = payload.email.lowercased().trimmingCharacters(in: .whitespaces)
        guard !data.profiles.contains(where: { $0.email.lowercased() == normalized }) else {
            throw AppError.validation("An account with that email already exists.")
        }
        let orgId: UUID
        let role: Role
        switch payload.role {
        case .owner, .admin, .manager:
            // Employer flow reuses the demo organization for simplicity in mock mode.
            orgId = data.organization.id
            role = .owner
        case .employee:
            guard let code = payload.inviteCode,
                  code.uppercased() == data.organization.inviteCode else {
                throw AppError.validation("Invalid invite code.")
            }
            orgId = data.organization.id
            role = .employee
        }
        let profile = UserProfile(
            id: UUID(), fullName: payload.fullName, email: normalized, phone: nil,
            avatarURL: nil, jobTitle: role.isManager ? "Manager" : "Team Member",
            role: role, organizationId: orgId, hourlyRate: role.isManager ? nil : 11.5,
            createdAt: .now
        )
        data.profiles.append(profile)
        sessionUserId = profile.id
        persistSession()
        return AuthSession(userId: profile.id, email: profile.email)
    }

    func signOut() async {
        sessionUserId = nil
        persistSession()
    }

    // MARK: Profiles

    func fetchProfile(userId: UUID) async throws -> UserProfile {
        guard let p = data.profiles.first(where: { $0.id == userId }) else { throw AppError.notFound }
        return p
    }

    func updateProfile(_ profile: UserProfile) async throws -> UserProfile {
        await delay()
        guard let idx = data.profiles.firstIndex(where: { $0.id == profile.id }) else { throw AppError.notFound }
        data.profiles[idx] = profile
        return profile
    }

    func fetchTeam(organizationId: UUID) async throws -> [UserProfile] {
        await delay()
        return data.profiles
            .filter { $0.organizationId == organizationId }
            .sorted { $0.fullName < $1.fullName }
    }

    // MARK: Organization

    func fetchOrganization(id: UUID) async throws -> Organization {
        guard data.organization.id == id else { throw AppError.notFound }
        return data.organization
    }

    func updateOrganization(_ organization: Organization) async throws -> Organization {
        await delay()
        data.organization = organization
        return organization
    }

    // MARK: Shifts

    func fetchShifts(organizationId: UUID, from: Date, to: Date) async throws -> [Shift] {
        await delay()
        return data.shifts
            .filter { $0.organizationId == organizationId && $0.startAt >= from && $0.startAt <= to }
            .sorted { $0.startAt < $1.startAt }
    }

    func fetchShifts(forUser userId: UUID, from: Date, to: Date) async throws -> [Shift] {
        await delay()
        return data.shifts
            .filter { $0.assignedUserId == userId && $0.startAt >= from && $0.startAt <= to }
            .sorted { $0.startAt < $1.startAt }
    }

    func createShift(_ shift: Shift) async throws -> Shift {
        await delay()
        data.shifts.append(shift)
        return shift
    }

    func updateShift(_ shift: Shift) async throws -> Shift {
        await delay()
        guard let idx = data.shifts.firstIndex(where: { $0.id == shift.id }) else { throw AppError.notFound }
        data.shifts[idx] = shift
        return shift
    }

    func deleteShift(id: UUID) async throws {
        await delay()
        data.shifts.removeAll { $0.id == id }
    }

    func assignShift(shiftId: UUID, to userId: UUID?) async throws -> Shift {
        await delay()
        guard let idx = data.shifts.firstIndex(where: { $0.id == shiftId }) else { throw AppError.notFound }
        data.shifts[idx].assignedUserId = userId
        if userId != nil, data.shifts[idx].status == .scheduled {
            data.shifts[idx].status = .published
        }
        return data.shifts[idx]
    }

    // MARK: Templates

    func fetchTemplates(organizationId: UUID) async throws -> [ShiftTemplate] {
        await delay()
        return data.templates.filter { $0.organizationId == organizationId }
    }

    func createTemplate(_ template: ShiftTemplate) async throws -> ShiftTemplate {
        await delay()
        data.templates.append(template)
        return template
    }

    func deleteTemplate(id: UUID) async throws {
        await delay()
        data.templates.removeAll { $0.id == id }
    }

    // MARK: Leave

    func fetchLeaveRequests(organizationId: UUID) async throws -> [LeaveRequest] {
        await delay()
        return data.leaveRequests
            .filter { $0.organizationId == organizationId }
            .sorted { $0.createdAt > $1.createdAt }
    }

    func fetchLeaveRequests(forUser userId: UUID) async throws -> [LeaveRequest] {
        await delay()
        return data.leaveRequests
            .filter { $0.userId == userId }
            .sorted { $0.createdAt > $1.createdAt }
    }

    func createLeaveRequest(_ request: LeaveRequest) async throws -> LeaveRequest {
        await delay()
        data.leaveRequests.append(request)
        return request
    }

    func updateLeaveStatus(id: UUID, status: RequestStatus, reviewerId: UUID?) async throws -> LeaveRequest {
        await delay()
        guard let idx = data.leaveRequests.firstIndex(where: { $0.id == id }) else { throw AppError.notFound }
        data.leaveRequests[idx].status = status
        data.leaveRequests[idx].reviewedBy = reviewerId
        return data.leaveRequests[idx]
    }

    // MARK: Swaps

    func fetchSwapRequests(organizationId: UUID) async throws -> [SwapRequest] {
        await delay()
        return data.swapRequests
            .filter { $0.organizationId == organizationId }
            .sorted { $0.createdAt > $1.createdAt }
    }

    func createSwapRequest(_ request: SwapRequest) async throws -> SwapRequest {
        await delay()
        data.swapRequests.append(request)
        return request
    }

    func updateSwapStatus(id: UUID, status: RequestStatus) async throws -> SwapRequest {
        await delay()
        guard let idx = data.swapRequests.firstIndex(where: { $0.id == id }) else { throw AppError.notFound }
        data.swapRequests[idx].status = status
        return data.swapRequests[idx]
    }

    // MARK: Time tracking

    func activeTimeEntry(userId: UUID) async throws -> TimeEntry? {
        data.timeEntries.first { $0.userId == userId && $0.clockOutAt == nil }
    }

    func clockIn(_ entry: TimeEntry) async throws -> TimeEntry {
        await delay()
        if data.timeEntries.contains(where: { $0.userId == entry.userId && $0.clockOutAt == nil }) {
            throw AppError.conflict("You're already clocked in.")
        }
        data.timeEntries.append(entry)
        return entry
    }

    func clockOut(entryId: UUID, at date: Date) async throws -> TimeEntry {
        await delay()
        guard let idx = data.timeEntries.firstIndex(where: { $0.id == entryId }) else { throw AppError.notFound }
        data.timeEntries[idx].clockOutAt = date
        return data.timeEntries[idx]
    }

    func fetchTimeEntries(organizationId: UUID, from: Date, to: Date) async throws -> [TimeEntry] {
        await delay()
        return data.timeEntries
            .filter { $0.organizationId == organizationId && $0.clockInAt >= from && $0.clockInAt <= to }
            .sorted { $0.clockInAt > $1.clockInAt }
    }

    func fetchTimeEntries(forUser userId: UUID, from: Date, to: Date) async throws -> [TimeEntry] {
        await delay()
        return data.timeEntries
            .filter { $0.userId == userId && $0.clockInAt >= from && $0.clockInAt <= to }
            .sorted { $0.clockInAt > $1.clockInAt }
    }

    // MARK: Availability

    func fetchAvailability(userId: UUID) async throws -> [Availability] {
        await delay()
        return data.availability.filter { $0.userId == userId }.sorted { $0.weekday < $1.weekday }
    }

    func upsertAvailability(_ items: [Availability]) async throws -> [Availability] {
        await delay()
        for item in items {
            if let idx = data.availability.firstIndex(where: { $0.id == item.id }) {
                data.availability[idx] = item
            } else if let idx = data.availability.firstIndex(where: { $0.userId == item.userId && $0.weekday == item.weekday }) {
                data.availability[idx] = item
            } else {
                data.availability.append(item)
            }
        }
        return items
    }

    // MARK: Announcements

    func fetchAnnouncements(organizationId: UUID) async throws -> [Announcement] {
        await delay()
        return data.announcements
            .filter { $0.organizationId == organizationId }
            .sorted { ($0.isPinned ? 1 : 0, $0.createdAt) > ($1.isPinned ? 1 : 0, $1.createdAt) }
    }

    func createAnnouncement(_ announcement: Announcement) async throws -> Announcement {
        await delay()
        data.announcements.append(announcement)
        return announcement
    }

    func deleteAnnouncement(id: UUID) async throws {
        await delay()
        data.announcements.removeAll { $0.id == id }
    }
}
