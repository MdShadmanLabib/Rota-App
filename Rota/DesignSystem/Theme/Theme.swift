import SwiftUI

/// Central design tokens for the Rota design system.
/// Premium, minimal aesthetic inspired by Linear / Notion / Stripe.
enum Theme {

    // MARK: - Colors

    enum Colors {
        // Brand
        static let accent = Color.dynamic(light: Color(hex: "#4F46E5"), dark: Color(hex: "#818CF8"))
        static let accentStrong = Color.dynamic(light: Color(hex: "#4338CA"), dark: Color(hex: "#6366F1"))
        static let accentSoft = Color.dynamic(light: Color(hex: "#EEF2FF"), dark: Color(hex: "#1E1B4B"))
        static let violet = Color(hex: "#7C3AED")

        // Surfaces
        static let background = Color.dynamic(light: Color(hex: "#FAFAFB"), dark: Color(hex: "#0B0C0E"))
        static let surface = Color.dynamic(light: Color(hex: "#FFFFFF"), dark: Color(hex: "#16181D"))
        static let surfaceElevated = Color.dynamic(light: Color(hex: "#FFFFFF"), dark: Color(hex: "#1C1F26"))
        static let surfaceMuted = Color.dynamic(light: Color(hex: "#F4F4F6"), dark: Color(hex: "#21242C"))

        // Text
        static let textPrimary = Color.dynamic(light: Color(hex: "#0F172A"), dark: Color(hex: "#F8FAFC"))
        static let textSecondary = Color.dynamic(light: Color(hex: "#475569"), dark: Color(hex: "#94A3B8"))
        static let textTertiary = Color.dynamic(light: Color(hex: "#94A3B8"), dark: Color(hex: "#64748B"))

        // Lines
        static let border = Color.dynamic(light: Color(hex: "#E5E7EB"), dark: Color(hex: "#2A2E37"))
        static let separator = Color.dynamic(light: Color(hex: "#EEF0F3"), dark: Color(hex: "#23272F"))

        // Semantic
        static let success = Color.dynamic(light: Color(hex: "#16A34A"), dark: Color(hex: "#4ADE80"))
        static let warning = Color.dynamic(light: Color(hex: "#D97706"), dark: Color(hex: "#FBBF24"))
        static let danger = Color.dynamic(light: Color(hex: "#DC2626"), dark: Color(hex: "#F87171"))
        static let info = Color.dynamic(light: Color(hex: "#0EA5E9"), dark: Color(hex: "#38BDF8"))

        static let successSoft = Color.dynamic(light: Color(hex: "#DCFCE7"), dark: Color(hex: "#10261A"))
        static let warningSoft = Color.dynamic(light: Color(hex: "#FEF3C7"), dark: Color(hex: "#2A2110"))
        static let dangerSoft = Color.dynamic(light: Color(hex: "#FEE2E2"), dark: Color(hex: "#2A1414"))
        static let infoSoft = Color.dynamic(light: Color(hex: "#E0F2FE"), dark: Color(hex: "#0C2230"))

        /// Deterministic accent palette used for avatars / chart series.
        static let palette: [Color] = [
            Color(hex: "#6366F1"), Color(hex: "#8B5CF6"), Color(hex: "#EC4899"),
            Color(hex: "#F59E0B"), Color(hex: "#10B981"), Color(hex: "#06B6D4"),
            Color(hex: "#F43F5E"), Color(hex: "#84CC16")
        ]
    }

    // MARK: - Spacing (4pt grid)

    enum Spacing {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 20
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
        static let xxxl: CGFloat = 48
    }

    // MARK: - Radius

    enum Radius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 22
        static let pill: CGFloat = 999
    }

    // MARK: - Shadow

    struct Shadow {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat

        static let soft = Shadow(color: Color.black.opacity(0.06), radius: 14, x: 0, y: 6)
        static let card = Shadow(color: Color.black.opacity(0.05), radius: 18, x: 0, y: 10)
        static let floating = Shadow(color: Color.black.opacity(0.12), radius: 26, x: 0, y: 14)
    }

    // MARK: - Motion

    enum Motion {
        static let spring = Animation.spring(response: 0.42, dampingFraction: 0.82)
        static let snappy = Animation.spring(response: 0.3, dampingFraction: 0.85)
        static let smooth = Animation.easeInOut(duration: 0.25)
    }
}

extension View {
    func themeShadow(_ shadow: Theme.Shadow) -> some View {
        self.shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
    }
}
