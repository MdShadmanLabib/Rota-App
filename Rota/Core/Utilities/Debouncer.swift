import Foundation

/// Async debouncer for search/filter inputs.
@MainActor
final class Debouncer {
    private var task: Task<Void, Never>?
    private let delay: Duration

    init(delay: Duration = .milliseconds(300)) {
        self.delay = delay
    }

    func run(_ action: @escaping @MainActor () -> Void) {
        task?.cancel()
        task = Task { [delay] in
            try? await Task.sleep(for: delay)
            if Task.isCancelled { return }
            action()
        }
    }
}
