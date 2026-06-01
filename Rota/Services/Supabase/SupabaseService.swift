import Foundation
import Supabase

/// Wraps the configured Supabase client. Only instantiated in SUPABASE mode.
final class SupabaseService: Sendable {
    let client: SupabaseClient

    init?() {
        guard let url = AppConfig.supabaseURL, let key = AppConfig.supabaseAnonKey else {
            return nil
        }
        client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: key,
            options: SupabaseClientOptions(
                db: SupabaseClientOptions.DatabaseOptions(
                    encoder: JSONCoders.encoder,
                    decoder: JSONCoders.decoder
                )
            )
        )
    }
}

/// Database table names (kept in one place).
enum Table {
    static let profiles = "profiles"
    static let organizations = "organizations"
    static let shifts = "shifts"
    static let templates = "shift_templates"
    static let leave = "leave_requests"
    static let swaps = "swap_requests"
    static let timeEntries = "time_entries"
    static let availability = "availability"
    static let announcements = "announcements"
}
