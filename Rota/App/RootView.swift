import SwiftUI

/// Routes between onboarding, auth, biometric lock and the role-based home.
struct RootView: View {
    @Environment(SessionStore.self) private var session

    var body: some View {
        ZStack {
            ScreenBackground()
            content
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
        }
        .animation(Theme.Motion.spring, value: session.phase)
        .animation(Theme.Motion.spring, value: session.currentUser?.role)
    }

    @ViewBuilder
    private var content: some View {
        switch session.phase {
        case .loading:
            LaunchView()
        case .locked:
            LockView()
        case .unauthenticated:
            if session.hasOnboarded {
                AuthView()
            } else {
                OnboardingView()
            }
        case .authenticated:
            if session.isManager {
                EmployerHomeView()
            } else {
                EmployeeHomeView()
            }
        }
    }
}

/// Branded launch / splash view shown while restoring session.
struct LaunchView: View {
    @State private var animate = false

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            BrandMark(size: 84)
                .scaleEffect(animate ? 1 : 0.85)
                .opacity(animate ? 1 : 0.4)
            ProgressView().tint(Theme.Colors.accent)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
    }
}

/// Reusable brand logo mark.
struct BrandMark: View {
    var size: CGFloat = 64

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.26, style: .continuous)
                .fill(
                    LinearGradient(colors: [Theme.Colors.accent, Theme.Colors.violet],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                )
            Image(systemName: "calendar.day.timeline.left")
                .font(.system(size: size * 0.46, weight: .bold))
                .foregroundColor(.white)
        }
        .frame(width: size, height: size)
        .themeShadow(.card)
    }
}

/// Biometric lock screen.
struct LockView: View {
    @Environment(SessionStore.self) private var session

    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            Spacer()
            BrandMark(size: 76)
            VStack(spacing: Theme.Spacing.xs) {
                Text("Welcome back")
                    .font(.Rota.title2)
                    .foregroundColor(Theme.Colors.textPrimary)
                Text("Unlock with \(BiometricAuth.label) to continue")
                    .font(.Rota.callout)
                    .foregroundColor(Theme.Colors.textSecondary)
            }
            Spacer()
            RotaButton(title: "Unlock with \(BiometricAuth.label)",
                       icon: BiometricAuth.available == .faceID ? "faceid" : "touchid") {
                Task { await session.unlock() }
            }
            Button("Sign in with password") {
                Task { await session.signOut() }
            }
            .font(.Rota.subheadline)
            .foregroundColor(Theme.Colors.textSecondary)
        }
        .padding(Theme.Spacing.xl)
        .task { await session.unlock() }
    }
}
