import SwiftUI

struct AppSettingsView: View {
    @Environment(SessionStore.self) private var session
    @State private var showSignOutConfirm = false

    var body: some View {
        Form {
            Section("Security") {
                if BiometricAuth.available != .none {
                    Toggle(isOn: Binding(
                        get: { session.biometricEnabled },
                        set: { session.biometricEnabled = $0; Haptics.selection() }
                    )) {
                        Label("Unlock with \(BiometricAuth.label)", systemImage: "faceid")
                    }
                } else {
                    Label("Biometrics unavailable on this device", systemImage: "faceid")
                        .foregroundColor(Theme.Colors.textSecondary)
                }
            }

            Section("Appearance") {
                Label("Rota follows your system Light/Dark setting", systemImage: "circle.lefthalf.filled")
                    .font(.Rota.subheadline).foregroundColor(Theme.Colors.textSecondary)
            }

            Section("About") {
                LabeledContent("Version", value: appVersion)
                LabeledContent("Backend", value: session.mode == .mock ? "Demo (mock)" : "Supabase")
                Link(destination: URL(string: "https://docs.devin.ai")!) {
                    Label("Help & support", systemImage: "questionmark.circle")
                }
            }

            Section {
                Button(role: .destructive) { showSignOutConfirm = true } label: {
                    Label("Sign out", systemImage: "rectangle.portrait.and.arrow.right")
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Sign out of Rota?", isPresented: $showSignOutConfirm, titleVisibility: .visible) {
            Button("Sign out", role: .destructive) { Task { await session.signOut() } }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var appVersion: String {
        let v = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        return v
    }
}
