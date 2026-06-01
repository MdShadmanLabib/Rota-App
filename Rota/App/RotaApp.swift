import SwiftUI

@main
struct RotaApp: App {
    @State private var session: SessionStore
    @State private var toasts = ToastCenter()

    init() {
        let environment = AppEnvironment.live()
        _session = State(initialValue: SessionStore(environment: environment))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .tint(Theme.Colors.accent)
                .toastHost()
                .environment(session)
                .environment(toasts)
                .task { await session.bootstrap() }
        }
    }
}
