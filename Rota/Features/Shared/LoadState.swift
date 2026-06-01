import Foundation

/// Generic async load state for view models.
enum LoadState: Equatable {
    case idle
    case loading
    case loaded
    case failed(String)

    var isLoading: Bool { self == .loading }
    var errorMessage: String? {
        if case let .failed(message) = self { return message }
        return nil
    }
}
