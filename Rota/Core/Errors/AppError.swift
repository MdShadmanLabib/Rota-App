import Foundation

/// Unified error type surfaced to the UI.
enum AppError: LocalizedError, Equatable {
    case notAuthenticated
    case invalidCredentials
    case network
    case notFound
    case permissionDenied
    case validation(String)
    case conflict(String)
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated: return "You need to sign in to continue."
        case .invalidCredentials: return "Incorrect email or password."
        case .network: return "Network error. Please check your connection."
        case .notFound: return "We couldn't find what you were looking for."
        case .permissionDenied: return "You don't have permission to do that."
        case .validation(let msg): return msg
        case .conflict(let msg): return msg
        case .unknown(let msg): return msg
        }
    }

    static func from(_ error: Error) -> AppError {
        if let appError = error as? AppError { return appError }
        let ns = error as NSError
        if ns.domain == NSURLErrorDomain { return .network }
        return .unknown(error.localizedDescription)
    }
}
