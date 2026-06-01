import Foundation
import Supabase

/// Production repository backed by Supabase (Auth + Postgres + RLS).
/// All reads/writes are scoped by Row-Level Security policies on the server.
final class SupabaseRepository: RotaRepository {

    private let service: SupabaseService
    private var client: SupabaseClient { service.client }

    init(service: SupabaseService) {
        self.service = service
    }

    private func iso(_ date: Date) -> String { JSONCoders.string(from: date) }

    // MARK: Auth

    func currentSession() async -> AuthSession? {
        guard let session = try? await client.auth.session else { return nil }
        return AuthSession(userId: session.user.id, email: session.user.email ?? "")
    }

    func signIn(email: String, password: String) async throws -> AuthSession {
        do {
            let session = try await client.auth.signIn(email: email, password: password)
            return AuthSession(userId: session.user.id, email: session.user.email ?? email)
        } catch {
            throw AppError.invalidCredentials
        }
    }

    func signUp(_ payload: SignUpPayload) async throws -> AuthSession {
        let response = try await client.auth.signUp(
            email: payload.email,
            password: payload.password,
            data: ["full_name": .string(payload.fullName), "role": .string(payload.role.rawValue)]
        )
        let user = response.user
        // Atomically create the org (employer) or join via invite code (employee).
        struct BootstrapParams: Encodable {
            let p_full_name: String
            let p_role: String
            let p_org_name: String?
            let p_invite_code: String?
        }
        let params = BootstrapParams(
            p_full_name: payload.fullName,
            p_role: payload.role.rawValue,
            p_org_name: payload.organizationName,
            p_invite_code: payload.inviteCode
        )
        _ = try? await client.rpc("bootstrap_account", params: params).execute()
        return AuthSession(userId: user.id, email: user.email ?? payload.email)
    }

    func signOut() async {
        try? await client.auth.signOut()
    }

    // MARK: Profiles

    func fetchProfile(userId: UUID) async throws -> UserProfile {
        try await client.from(Table.profiles)
            .select().eq("id", value: userId).single()
            .execute().value
    }

    func updateProfile(_ profile: UserProfile) async throws -> UserProfile {
        try await client.from(Table.profiles)
            .update(profile).eq("id", value: profile.id).select().single()
            .execute().value
    }

    func fetchTeam(organizationId: UUID) async throws -> [UserProfile] {
        try await client.from(Table.profiles)
            .select().eq("organization_id", value: organizationId).order("full_name")
            .execute().value
    }

    // MARK: Organization

    func fetchOrganization(id: UUID) async throws -> Organization {
        try await client.from(Table.organizations)
            .select().eq("id", value: id).single()
            .execute().value
    }

    func updateOrganization(_ organization: Organization) async throws -> Organization {
        try await client.from(Table.organizations)
            .update(organization).eq("id", value: organization.id).select().single()
            .execute().value
    }

    // MARK: Shifts

    func fetchShifts(organizationId: UUID, from: Date, to: Date) async throws -> [Shift] {
        try await client.from(Table.shifts)
            .select()
            .eq("organization_id", value: organizationId)
            .gte("start_at", value: iso(from))
            .lte("start_at", value: iso(to))
            .order("start_at")
            .execute().value
    }

    func fetchShifts(forUser userId: UUID, from: Date, to: Date) async throws -> [Shift] {
        try await client.from(Table.shifts)
            .select()
            .eq("assigned_user_id", value: userId)
            .gte("start_at", value: iso(from))
            .lte("start_at", value: iso(to))
            .order("start_at")
            .execute().value
    }

    func createShift(_ shift: Shift) async throws -> Shift {
        try await client.from(Table.shifts).insert(shift).select().single().execute().value
    }

    func updateShift(_ shift: Shift) async throws -> Shift {
        try await client.from(Table.shifts)
            .update(shift).eq("id", value: shift.id).select().single().execute().value
    }

    func deleteShift(id: UUID) async throws {
        _ = try await client.from(Table.shifts).delete().eq("id", value: id).execute()
    }

    func assignShift(shiftId: UUID, to userId: UUID?) async throws -> Shift {
        struct Patch: Encodable { let assigned_user_id: UUID? }
        return try await client.from(Table.shifts)
            .update(Patch(assigned_user_id: userId)).eq("id", value: shiftId)
            .select().single().execute().value
    }

    // MARK: Templates

    func fetchTemplates(organizationId: UUID) async throws -> [ShiftTemplate] {
        try await client.from(Table.templates)
            .select().eq("organization_id", value: organizationId).order("name")
            .execute().value
    }

    func createTemplate(_ template: ShiftTemplate) async throws -> ShiftTemplate {
        try await client.from(Table.templates).insert(template).select().single().execute().value
    }

    func deleteTemplate(id: UUID) async throws {
        _ = try await client.from(Table.templates).delete().eq("id", value: id).execute()
    }

    // MARK: Leave

    func fetchLeaveRequests(organizationId: UUID) async throws -> [LeaveRequest] {
        try await client.from(Table.leave)
            .select().eq("organization_id", value: organizationId).order("created_at", ascending: false)
            .execute().value
    }

    func fetchLeaveRequests(forUser userId: UUID) async throws -> [LeaveRequest] {
        try await client.from(Table.leave)
            .select().eq("user_id", value: userId).order("created_at", ascending: false)
            .execute().value
    }

    func createLeaveRequest(_ request: LeaveRequest) async throws -> LeaveRequest {
        try await client.from(Table.leave).insert(request).select().single().execute().value
    }

    func updateLeaveStatus(id: UUID, status: RequestStatus, reviewerId: UUID?) async throws -> LeaveRequest {
        struct Patch: Encodable { let status: String; let reviewed_by: UUID? }
        return try await client.from(Table.leave)
            .update(Patch(status: status.rawValue, reviewed_by: reviewerId)).eq("id", value: id)
            .select().single().execute().value
    }

    // MARK: Swaps

    func fetchSwapRequests(organizationId: UUID) async throws -> [SwapRequest] {
        try await client.from(Table.swaps)
            .select().eq("organization_id", value: organizationId).order("created_at", ascending: false)
            .execute().value
    }

    func createSwapRequest(_ request: SwapRequest) async throws -> SwapRequest {
        try await client.from(Table.swaps).insert(request).select().single().execute().value
    }

    func updateSwapStatus(id: UUID, status: RequestStatus) async throws -> SwapRequest {
        struct Patch: Encodable { let status: String }
        return try await client.from(Table.swaps)
            .update(Patch(status: status.rawValue)).eq("id", value: id)
            .select().single().execute().value
    }

    // MARK: Time tracking

    func activeTimeEntry(userId: UUID) async throws -> TimeEntry? {
        let entries: [TimeEntry] = try await client.from(Table.timeEntries)
            .select().eq("user_id", value: userId).is("clock_out_at", value: nil)
            .order("clock_in_at", ascending: false).limit(1)
            .execute().value
        return entries.first
    }

    func clockIn(_ entry: TimeEntry) async throws -> TimeEntry {
        try await client.from(Table.timeEntries).insert(entry).select().single().execute().value
    }

    func clockOut(entryId: UUID, at date: Date) async throws -> TimeEntry {
        struct Patch: Encodable { let clock_out_at: String }
        return try await client.from(Table.timeEntries)
            .update(Patch(clock_out_at: iso(date))).eq("id", value: entryId)
            .select().single().execute().value
    }

    func fetchTimeEntries(organizationId: UUID, from: Date, to: Date) async throws -> [TimeEntry] {
        try await client.from(Table.timeEntries)
            .select()
            .eq("organization_id", value: organizationId)
            .gte("clock_in_at", value: iso(from))
            .lte("clock_in_at", value: iso(to))
            .order("clock_in_at", ascending: false)
            .execute().value
    }

    func fetchTimeEntries(forUser userId: UUID, from: Date, to: Date) async throws -> [TimeEntry] {
        try await client.from(Table.timeEntries)
            .select()
            .eq("user_id", value: userId)
            .gte("clock_in_at", value: iso(from))
            .lte("clock_in_at", value: iso(to))
            .order("clock_in_at", ascending: false)
            .execute().value
    }

    // MARK: Availability

    func fetchAvailability(userId: UUID) async throws -> [Availability] {
        try await client.from(Table.availability)
            .select().eq("user_id", value: userId).order("weekday")
            .execute().value
    }

    func upsertAvailability(_ items: [Availability]) async throws -> [Availability] {
        try await client.from(Table.availability)
            .upsert(items, onConflict: "user_id,weekday").select()
            .execute().value
    }

    // MARK: Announcements

    func fetchAnnouncements(organizationId: UUID) async throws -> [Announcement] {
        try await client.from(Table.announcements)
            .select()
            .eq("organization_id", value: organizationId)
            .order("is_pinned", ascending: false)
            .order("created_at", ascending: false)
            .execute().value
    }

    func createAnnouncement(_ announcement: Announcement) async throws -> Announcement {
        try await client.from(Table.announcements).insert(announcement).select().single().execute().value
    }

    func deleteAnnouncement(id: UUID) async throws {
        _ = try await client.from(Table.announcements).delete().eq("id", value: id).execute()
    }
}
