import SwiftUI

enum BadgeTone {
    case neutral, accent, success, warning, danger, info

    var fg: Color {
        switch self {
        case .neutral: return Theme.Colors.textSecondary
        case .accent: return Theme.Colors.accent
        case .success: return Theme.Colors.success
        case .warning: return Theme.Colors.warning
        case .danger: return Theme.Colors.danger
        case .info: return Theme.Colors.info
        }
    }

    var bg: Color {
        switch self {
        case .neutral: return Theme.Colors.surfaceMuted
        case .accent: return Theme.Colors.accentSoft
        case .success: return Theme.Colors.successSoft
        case .warning: return Theme.Colors.warningSoft
        case .danger: return Theme.Colors.dangerSoft
        case .info: return Theme.Colors.infoSoft
        }
    }
}

/// Small status pill.
struct Badge: View {
    let text: String
    var tone: BadgeTone = .neutral
    var icon: String? = nil

    var body: some View {
        HStack(spacing: 4) {
            if let icon { Image(systemName: icon).font(.system(size: 10, weight: .bold)) }
            Text(text).font(.Rota.caption2)
        }
        .foregroundColor(tone.fg)
        .padding(.horizontal, Theme.Spacing.xs)
        .padding(.vertical, 5)
        .background(tone.bg)
        .clipShape(Capsule())
    }
}
