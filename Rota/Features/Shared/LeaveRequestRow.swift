import SwiftUI

/// Compact leave request row with type icon and status.
struct LeaveRequestRow: View {
    let request: LeaveRequest
    var name: String? = nil
    var onApprove: (() -> Void)? = nil
    var onReject: (() -> Void)? = nil

    var body: some View {
        RotaCard {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                HStack(spacing: Theme.Spacing.sm) {
                    ZStack {
                        Circle().fill(Theme.Colors.accentSoft).frame(width: 40, height: 40)
                        Image(systemName: request.type.icon)
                            .foregroundColor(Theme.Colors.accent)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        if let name {
                            Text(name).font(.Rota.headline).foregroundColor(Theme.Colors.textPrimary)
                        }
                        Text("\(request.type.label) · \(request.dayCount) day\(request.dayCount > 1 ? "s" : "")")
                            .font(.Rota.footnote)
                            .foregroundColor(Theme.Colors.textSecondary)
                    }
                    Spacer()
                    Badge(text: request.status.label, tone: request.status.tone)
                }

                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                    Text(request.rangeLabel)
                }
                .font(.Rota.footnote)
                .foregroundColor(Theme.Colors.textSecondary)

                if let reason = request.reason, !reason.isEmpty {
                    Text(reason)
                        .font(.Rota.footnote)
                        .foregroundColor(Theme.Colors.textTertiary)
                }

                if request.status == .pending, onApprove != nil || onReject != nil {
                    HStack(spacing: Theme.Spacing.sm) {
                        RotaButton(title: "Reject", style: .secondary) { onReject?() }
                        RotaButton(title: "Approve") { onApprove?() }
                    }
                    .padding(.top, Theme.Spacing.xxs)
                }
            }
        }
    }
}
