import SwiftUI

struct ProfileView: View {
    @Environment(SessionStore.self) private var session
    @Environment(ToastCenter.self) private var toasts

    @State private var fullName = ""
    @State private var jobTitle = ""
    @State private var phone = ""
    @State private var isSaving = false

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                Avatar(name: session.currentUser?.fullName ?? "U", size: 96, imageURL: session.currentUser?.avatarURL)
                    .padding(.top, Theme.Spacing.md)

                VStack(spacing: Theme.Spacing.md) {
                    RotaTextField(title: "Full name", icon: "person", autocapitalization: .words, text: $fullName)
                    RotaTextField(title: "Job title", icon: "briefcase", autocapitalization: .words, text: $jobTitle)
                    RotaTextField(title: "Phone", icon: "phone", keyboard: .phonePad, text: $phone)

                    if let email = session.currentUser?.email {
                        RotaCard {
                            HStack {
                                Label("Email", systemImage: "envelope").font(.Rota.subheadline).foregroundColor(Theme.Colors.textSecondary)
                                Spacer()
                                Text(email).font(.Rota.subheadline).foregroundColor(Theme.Colors.textPrimary)
                            }
                        }
                    }

                    RotaButton(title: "Save changes", isLoading: isSaving) { save() }
                }
            }
            .padding(Theme.Spacing.lg)
        }
        .background(Theme.Colors.background)
        .navigationTitle("My profile")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: populate)
    }

    private func populate() {
        guard let user = session.currentUser else { return }
        fullName = user.fullName
        jobTitle = user.jobTitle ?? ""
        phone = user.phone ?? ""
    }

    private func save() {
        guard var user = session.currentUser else { return }
        user.fullName = fullName.trimmingCharacters(in: .whitespaces)
        user.jobTitle = jobTitle.isEmpty ? nil : jobTitle
        user.phone = phone.isEmpty ? nil : phone
        isSaving = true
        Task {
            do { try await session.updateProfile(user); toasts.show("Profile updated") }
            catch { toasts.error("Couldn't save profile") }
            isSaving = false
        }
    }
}
