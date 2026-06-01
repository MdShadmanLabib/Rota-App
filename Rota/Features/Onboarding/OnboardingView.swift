import SwiftUI

struct OnboardingPage: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let subtitle: String
    let tint: Color
}

struct OnboardingView: View {
    @Environment(SessionStore.self) private var session
    @State private var index = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(icon: "calendar.badge.clock", title: "Scheduling, simplified",
                       subtitle: "Build weekly and monthly rotas in minutes with templates and drag‑to‑assign.",
                       tint: Theme.Colors.accent),
        OnboardingPage(icon: "bolt.heart.fill", title: "Your team, in sync",
                       subtitle: "Clock in, swap shifts, request leave and get notified — all in real time.",
                       tint: Theme.Colors.violet),
        OnboardingPage(icon: "chart.line.uptrend.xyaxis", title: "Insights that matter",
                       subtitle: "Track hours, attendance, coverage and overtime with beautiful analytics.",
                       tint: Theme.Colors.info)
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button("Skip") {
                    Haptics.tap()
                    session.completeOnboarding()
                }
                .font(.Rota.subheadline)
                .foregroundColor(Theme.Colors.textSecondary)
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.top, Theme.Spacing.sm)
            .opacity(index == pages.count - 1 ? 0 : 1)

            TabView(selection: $index) {
                ForEach(Array(pages.enumerated()), id: \.element.id) { i, page in
                    OnboardingPageView(page: page).tag(i)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(Theme.Motion.spring, value: index)

            PageDots(count: pages.count, index: index)
                .padding(.bottom, Theme.Spacing.lg)

            VStack(spacing: Theme.Spacing.sm) {
                RotaButton(title: index == pages.count - 1 ? "Get started" : "Continue",
                           icon: index == pages.count - 1 ? "arrow.right" : nil) {
                    if index == pages.count - 1 {
                        session.completeOnboarding()
                    } else {
                        withAnimation(Theme.Motion.spring) { index += 1 }
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.bottom, Theme.Spacing.xl)
        }
    }
}

private struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            Spacer()
            ZStack {
                Circle().fill(page.tint.opacity(0.14)).frame(width: 180, height: 180)
                Circle().fill(page.tint.opacity(0.10)).frame(width: 240, height: 240)
                Image(systemName: page.icon)
                    .font(.system(size: 72, weight: .semibold))
                    .foregroundColor(page.tint)
            }
            VStack(spacing: Theme.Spacing.sm) {
                Text(page.title)
                    .font(.Rota.title)
                    .multilineTextAlignment(.center)
                    .foregroundColor(Theme.Colors.textPrimary)
                Text(page.subtitle)
                    .font(.Rota.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(Theme.Colors.textSecondary)
                    .padding(.horizontal, Theme.Spacing.xl)
            }
            Spacer()
        }
        .padding(Theme.Spacing.lg)
    }
}

struct PageDots: View {
    let count: Int
    let index: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<count, id: \.self) { i in
                Capsule()
                    .fill(i == index ? Theme.Colors.accent : Theme.Colors.border)
                    .frame(width: i == index ? 22 : 8, height: 8)
                    .animation(Theme.Motion.spring, value: index)
            }
        }
    }
}
