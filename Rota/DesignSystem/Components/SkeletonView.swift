import SwiftUI

/// Shimmering skeleton placeholder for loading states.
struct SkeletonView: View {
    var cornerRadius: CGFloat = Theme.Radius.sm
    @State private var phase: CGFloat = -1

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(Theme.Colors.surfaceMuted)
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        colors: [.clear, Color.white.opacity(0.35), .clear],
                        startPoint: .leading, endPoint: .trailing
                    )
                    .frame(width: geo.size.width * 0.5)
                    .offset(x: phase * geo.size.width * 1.5)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .onAppear {
                withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

/// A reusable skeleton list row mimicking the shift card layout.
struct SkeletonCard: View {
    var body: some View {
        RotaCard {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                HStack {
                    SkeletonView().frame(width: 120, height: 16)
                    Spacer()
                    SkeletonView(cornerRadius: Theme.Radius.pill).frame(width: 60, height: 22)
                }
                SkeletonView().frame(width: 200, height: 12)
                SkeletonView().frame(maxWidth: .infinity).frame(height: 12)
            }
        }
    }
}
