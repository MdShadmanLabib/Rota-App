import SwiftUI

/// Compact metric tile used in dashboards.
struct StatTile: View {
    let title: String
    let value: String
    var icon: String
    var tone: BadgeTone = .accent
    var trend: String? = nil
    var trendUp: Bool = true

    var body: some View {
        RotaCard(padding: Theme.Spacing.md) {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous)
                            .fill(tone.bg)
                            .frame(width: 36, height: 36)
                        Image(systemName: icon)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(tone.fg)
                    }
                    Spacer()
                    if let trend {
                        HStack(spacing: 2) {
                            Image(systemName: trendUp ? "arrow.up.right" : "arrow.down.right")
                            Text(trend)
                        }
                        .font(.Rota.caption2)
                        .foregroundColor(trendUp ? Theme.Colors.success : Theme.Colors.danger)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(value)
                        .font(.Rota.title2)
                        .foregroundColor(Theme.Colors.textPrimary)
                    Text(title)
                        .font(.Rota.footnote)
                        .foregroundColor(Theme.Colors.textSecondary)
                }
            }
        }
    }
}
