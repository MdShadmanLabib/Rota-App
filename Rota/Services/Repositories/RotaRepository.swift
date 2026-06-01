import Foundation

/// The single data-access contract used by the whole app.
/// Implemented by `MockRepository` (in-memory sample data) and
/// `SupabaseRepository` (real backend). View models depend only on this.
protocol RotaRepository: Sendable {

    // MARK: Auth
    func currentSession() async -> AuthSession?
    func signIn(email: String, password: String) async throws -> AuthSession
    func signUp(_ payload: SignUpPayload) async throws -> AuthSession
    func signOut() async

    // MARK: Profiles
    func fetchProfile(userId: UUID) async throws -> UserProfile
    func updateProfile(_ profile: UserProfile) async throws -> UserProfile
    func fetchTeam(organizationId: UUID) async throws -> [UserProfile]

    // MARK: Organization
    func fetchOrganization(id: UUID) async throws -> Organization
    func updateOrganization(_ organization: Organization) async throws -> Organization

    // MARK: Shifts
    func fetchShifts(organizationId: UUID, from: Date, to: Date) async throws -> [Shift]
    func fetchShifts(forUser userId: UUID, from: Date, to: Date) async throws -> [Shift]
    func createShift(_ shift: Shift) async throws -> Shift
    func updateShift(_ shift: Shift) async throws -> Shift
    func deleteShift(id: UUID) async throws
    func assignShift(shiftId: UUID, to userId: UUID?) async throws -> Shift

    // MARK: Templates
    func fetchTemplates(organizationId: UUID) async throws -> [ShiftTemplate]
    func createTemplate(_ template: ShiftTemplate) async throws -> ShiftTemplate
    func deleteTemplate(id: UUID) async throws

    // MARK: Leave
    func fetchLeaveRequests(organizationId: UUID) async throws -> [LeaveRequest]
    func fetchLeaveRequests(forUser userId: UUID) async throws -> [LeaveRequest]
    func createLeaveRequest(_ request: LeaveRequest) async throws -> LeaveRequest
    func updateLeaveStatus(id: UUID, status: RequestStatus, reviewerId: UUID?) async throws -> LeaveRequest

    // MARK: Swaps
    func fetchSwapRequests(organizationId: UUID) async throws -> [SwapRequest]
    func createSwapRequest(_ request: SwapRequest) async throws -> SwapRequest
    func updateSwapStatus(id: UUID, status: RequestStatus) async throws -> SwapRequest

    // MARK: Time tracking
    func activeTimeEntry(userId: UUID) async throws -> TimeEntry?
    func clockIn(_ entry: TimeEntry) async throws -> TimeEntry
    func clockOut(entryId: UUID, at date: Date) async throws -> TimeEntry
    func fetchTimeEntries(organizationId: UUID, from: Date, to: Date) async throws -> [TimeEntry]
    func fetchTimeEntries(forUser userId: UUID, from: Date, to: Date) async throws -> [TimeEntry]

    // MARK: Availability
    func fetchAvailability(userId: UUID) async throws -> [Availability]
    func upsertAvailability(_ items: [Availability]) async throws -> [Availability]

    // MARK: Announcements
    func fetchAnnouncements(organizationId: UUID) async throws -> [Announcement]
    func createAnnouncement(_ announcement: Announcement) async throws -> Announcement
    func deleteAnnouncement(id: UUID) async throws
}
