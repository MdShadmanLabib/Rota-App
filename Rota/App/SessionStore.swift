import SwiftUI

/// Top-level auth/session state. Owns the current user + organization and
/// drives root routing between onboarding, auth and the role-based home.
@MainActor
@Observable
final class SessionStore {

    enum Phase: Equatable {
        case loading
        case unauthenticated
        case locked          // session exists but biometric unlock required
        case authenticated
    }

    private(set) var phase: Phase = .loading
    private(set) var currentUser: UserProfile?
    private(set) var organization: Organization?

    let repository: RotaRepository
    let mode: AppConfig.BackendMode

    /// Persisted onboarding + biometric preferences.
    @ObservationIgnored @AppStorage("rota.hasOnboarded") var hasOnboarded: Bool = false
    @ObservationIgnored @AppStorage("rota.biometricEnabled") var biometricEnabled: Bool = false

    var isManager: Bool { currentUser?.role.isManager ?? false }

    init(environment: AppEnvironment) {
        self.repository = environment.repository
        self.mode = environment.mode
    }

    /// Called on launch to restore any existing session.
    func bootstrap() async {
        guard let session = await repository.currentSession() else {
            phase = .unauthenticated
            return
        }
        if biometricEnabled, BiometricAuth.available != .none {
            phase = .locked
            // Attempt to load the profile in the background so unlock is instant.
            try? await loadContext(userId: session.userId)
            return
        }
        do {
            try await loadContext(userId: session.userId)
            phase = .authenticated
        } catch {
            phase = .unauthenticated
        }
    }

    func unlock() async {
        let success = await BiometricAuth.authenticate()
        if success {
            phase = currentUser != nil ? .authenticated : .unauthenticated
            if currentUser == nil, let session = await repository.currentSession() {
                try? await loadContext(userId: session.userId)
                phase = .authenticated
            }
        }
    }

    private func loadContext(userId: UUID) async throws {
        let profile = try await repository.fetchProfile(userId: userId)
        currentUser = profile
        if let orgId = profile.organizationId {
            organization = try? await repository.fetchOrganization(id: orgId)
        }
    }

    func signIn(email: String, password: String) async throws {
        let session = try await repository.signIn(email: email, password: password)
        try await loadContext(userId: session.userId)
        phase = .authenticated
        Haptics.success()
    }

    func signUp(_ payload: SignUpPayload) async throws {
        let session = try await repository.signUp(payload)
        try await loadContext(userId: session.userId)
        phase = .authenticated
        Haptics.success()
    }

    func signOut() async {
        await repository.signOut()
        currentUser = nil
        organization = nil
        phase = .unauthenticated
    }

    func completeOnboarding() {
        hasOnboarded = true
    }

    func refreshProfile() async {
        guard let id = currentUser?.id else { return }
        currentUser = try? await repository.fetchProfile(userId: id)
    }

    func updateProfile(_ profile: UserProfile) async throws {
        currentUser = try await repository.updateProfile(profile)
    }

    func refreshOrganization(_ organization: Organization) {
        self.organization = organization
    }
}
