import Foundation

/// Composition root. Builds the concrete repository for the active backend mode.
struct AppEnvironment {
    let repository: RotaRepository
    let mode: AppConfig.BackendMode

    static func live() -> AppEnvironment {
        switch AppConfig.backendMode {
        case .supabase:
            if let service = SupabaseService() {
                return AppEnvironment(repository: SupabaseRepository(service: service), mode: .supabase)
            }
            // Misconfigured → fall back to mock so the app still runs.
            return AppEnvironment(repository: MockRepository(), mode: .mock)
        case .mock:
            return AppEnvironment(repository: MockRepository(), mode: .mock)
        }
    }
}
