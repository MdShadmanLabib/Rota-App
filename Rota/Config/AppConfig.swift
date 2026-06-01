import Foundation

/// Reads build configuration injected via Info.plist (from Secrets.xcconfig).
enum AppConfig {
    enum BackendMode: String {
        case mock = "MOCK"
        case supabase = "SUPABASE"
    }

    private static func string(_ key: String) -> String? {
        let value = Bundle.main.object(forInfoDictionaryKey: key) as? String
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines)
        return (trimmed?.isEmpty == false) ? trimmed : nil
    }

    static var supabaseURLHost: String? { string("SupabaseURLHost") }
    static var supabaseAnonKey: String? { string("SupabaseAnonKey") }

    static var supabaseURL: URL? {
        guard let host = supabaseURLHost else { return nil }
        return URL(string: "https://\(host)")
    }

    /// Effective backend mode. Falls back to mock unless Supabase is fully configured.
    static var backendMode: BackendMode {
        let declared = BackendMode(rawValue: string("BackendMode") ?? "MOCK") ?? .mock
        if declared == .supabase, supabaseURL != nil, supabaseAnonKey != nil {
            return .supabase
        }
        return .mock
    }

    static var isMock: Bool { backendMode == .mock }
}
