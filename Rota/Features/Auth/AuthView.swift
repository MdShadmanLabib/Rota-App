import SwiftUI

struct AuthView: View {
    @Environment(SessionStore.self) private var session
    @State private var vm = AuthViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.xl) {
                header

                VStack(spacing: Theme.Spacing.md) {
                    if vm.mode == .signUp {
                        rolePicker
                        RotaTextField(title: "Full name", icon: "person", placeholder: "Jordan Avery",
                                      autocapitalization: .words, text: $vm.fullName)
                    }

                    RotaTextField(title: "Email", icon: "envelope", placeholder: "you@company.com",
                                  keyboard: .emailAddress, text: $vm.email)

                    RotaTextField(title: "Password", icon: "lock", placeholder: "••••••••",
                                  isSecure: true, text: $vm.password)

                    if vm.mode == .signUp {
                        if vm.role.isManager {
                            RotaTextField(title: "Company name", icon: "building.2",
                                          placeholder: "Brew & Co.", autocapitalization: .words,
                                          text: $vm.organizationName)
                        } else {
                            RotaTextField(title: "Invite code", icon: "key",
                                          placeholder: "e.g. BREW42",
                                          autocapitalization: .characters, text: $vm.inviteCode)
                        }
                    }

                    if let error = vm.errorMessage {
                        Label(error, systemImage: "exclamationmark.circle.fill")
                            .font(.Rota.footnote)
                            .foregroundColor(Theme.Colors.danger)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .transition(.opacity)
                    }

                    RotaButton(title: vm.mode == .signIn ? "Sign in" : "Create account",
                               isLoading: vm.isLoading, isEnabled: vm.canSubmit) {
                        Task { await vm.submit(using: session) }
                    }
                    .padding(.top, Theme.Spacing.xxs)
                }

                footer

                if session.mode == .mock {
                    demoBanner
                }
            }
            .padding(Theme.Spacing.lg)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var header: some View {
        VStack(spacing: Theme.Spacing.md) {
            BrandMark(size: 64)
            VStack(spacing: 4) {
                Text(vm.mode == .signIn ? "Welcome back" : "Create your account")
                    .font(.Rota.title)
                    .foregroundColor(Theme.Colors.textPrimary)
                Text(vm.mode == .signIn ? "Sign in to manage your shifts" : "Start scheduling in minutes")
                    .font(.Rota.callout)
                    .foregroundColor(Theme.Colors.textSecondary)
            }
        }
        .padding(.top, Theme.Spacing.xl)
    }

    private var rolePicker: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text("I am an…")
                .font(.Rota.subheadline)
                .foregroundColor(Theme.Colors.textSecondary)
            HStack(spacing: Theme.Spacing.sm) {
                RoleCard(title: "Employer", subtitle: "Manage a team", icon: "briefcase.fill",
                         isSelected: vm.role.isManager) {
                    withAnimation(Theme.Motion.spring) { vm.role = .owner }
                }
                RoleCard(title: "Employee", subtitle: "Join with code", icon: "person.fill",
                         isSelected: !vm.role.isManager) {
                    withAnimation(Theme.Motion.spring) { vm.role = .employee }
                }
            }
        }
    }

    private var footer: some View {
        HStack(spacing: 4) {
            Text(vm.mode == .signIn ? "New to Rota?" : "Already have an account?")
                .foregroundColor(Theme.Colors.textSecondary)
            Button(vm.mode == .signIn ? "Create account" : "Sign in") { vm.toggleMode() }
                .foregroundColor(Theme.Colors.accent)
                .fontWeight(.semibold)
        }
        .font(.Rota.subheadline)
    }

    private var demoBanner: some View {
        RotaCard(background: Theme.Colors.accentSoft) {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Label("Demo mode", systemImage: "sparkles")
                    .font(.Rota.subheadline)
                    .foregroundColor(Theme.Colors.accent)
                Text("Explore with prefilled sample data. Tap a role to autofill credentials.")
                    .font(.Rota.footnote)
                    .foregroundColor(Theme.Colors.textSecondary)
                HStack(spacing: Theme.Spacing.sm) {
                    RotaButton(title: "Employer demo", style: .secondary, fullWidth: true) {
                        vm.prefillDemo(manager: true)
                    }
                    RotaButton(title: "Employee demo", style: .secondary, fullWidth: true) {
                        vm.prefillDemo(manager: false)
                    }
                }
            }
        }
    }
}

private struct RoleCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: { Haptics.selection(); action() }) {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(isSelected ? .white : Theme.Colors.accent)
                Text(title).font(.Rota.headline)
                    .foregroundColor(isSelected ? .white : Theme.Colors.textPrimary)
                Text(subtitle).font(.Rota.caption)
                    .foregroundColor(isSelected ? .white.opacity(0.85) : Theme.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Theme.Spacing.md)
            .background(isSelected ? Theme.Colors.accent : Theme.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                    .stroke(isSelected ? Color.clear : Theme.Colors.border, lineWidth: 1)
            )
        }
        .buttonStyle(PressableCardStyle())
    }
}
