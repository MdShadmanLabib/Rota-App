import SwiftUI

struct RequestsView: View {
    @Environment(SessionStore.self) private var session
    @Environment(ToastCenter.self) private var toasts
    @State private var vm = RequestsViewModel()
    @State private var tab: RequestTab = .leave

    enum RequestTab: String, CaseIterable { case leave = "Leave", swaps = "Swaps" }

    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            RotaSegmentedControl(options: RequestTab.allCases, titleFor: { $0.rawValue }, selection: $tab)
                .padding(.horizontal, Theme.Spacing.lg)

            ScrollView {
                VStack(spacing: Theme.Spacing.sm) {
                    if tab == .leave { leaveList } else { swapList }
                }
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.bottom, Theme.Spacing.xl)
            }
        }
        .padding(.top, Theme.Spacing.sm)
        .background(Theme.Colors.background)
        .navigationTitle("Requests")
        .refreshable { await reload() }
        .task { await reload() }
    }

    private func reload() async {
        guard let orgId = session.organization?.id else { return }
        await vm.load(repository: session.repository, organizationId: orgId)
    }

    @ViewBuilder private var leaveList: some View {
        if vm.state.isLoading && vm.leave.isEmpty {
            ForEach(0..<3, id: \.self) { _ in SkeletonCard() }
        } else if vm.leave.isEmpty {
            EmptyStateView(icon: "calendar.badge.checkmark", title: "No leave requests",
                           message: "Time‑off requests from your team will appear here.")
        } else {
            ForEach(vm.leave) { request in
                LeaveRequestRow(
                    request: request, name: vm.name(for: request.userId),
                    onApprove: {
                        Task {
                            await vm.decide(request, approve: true, repository: session.repository, reviewerId: session.currentUser?.id)
                            toasts.show("Leave approved")
                        }
                    },
                    onReject: {
                        Task {
                            await vm.decide(request, approve: false, repository: session.repository, reviewerId: session.currentUser?.id)
                            toasts.show("Leave rejected", tone: .danger, icon: "xmark.circle.fill")
                        }
                    }
                )
            }
        }
    }

    @ViewBuilder private var swapList: some View {
        if vm.state.isLoading && vm.swaps.isEmpty {
            ForEach(0..<2, id: \.self) { _ in SkeletonCard() }
        } else if vm.swaps.isEmpty {
            EmptyStateView(icon: "arrow.triangle.2.circlepath", title: "No swap requests",
                           message: "Shift swap requests from your team will appear here.")
        } else {
            ForEach(vm.swaps) { swap in
                SwapRequestRow(
                    swap: swap,
                    requesterName: vm.name(for: swap.requestedBy),
                    shift: vm.shift(for: swap.shiftId),
                    onApprove: {
                        Task {
                            await vm.decideSwap(swap, approve: true, repository: session.repository)
                            toasts.show("Swap approved")
                        }
                    },
                    onReject: {
                        Task {
                            await vm.decideSwap(swap, approve: false, repository: session.repository)
                            toasts.show("Swap declined", tone: .danger, icon: "xmark.circle.fill")
                        }
                    }
                )
            }
        }
    }
}

struct SwapRequestRow: View {
    let swap: SwapRequest
    let requesterName: String
    let shift: Shift?
    var onApprove: (() -> Void)? = nil
    var onReject: (() -> Void)? = nil

    var body: some View {
        RotaCard {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                HStack {
                    Avatar(name: requesterName, size: 36)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(requesterName).font(.Rota.headline).foregroundColor(Theme.Colors.textPrimary)
                        Text("wants to swap a shift").font(.Rota.footnote).foregroundColor(Theme.Colors.textSecondary)
                    }
                    Spacer()
                    Badge(text: swap.status.label, tone: swap.status.tone)
                }
                if let shift {
                    HStack(spacing: 6) {
                        Image(systemName: "clock")
                        Text("\(shift.startAt.dayMonthLabel) · \(shift.timeRangeLabel)")
                    }
                    .font(.Rota.footnote)
                    .foregroundColor(Theme.Colors.textSecondary)
                }
                if let message = swap.message, !message.isEmpty {
                    Text(message).font(.Rota.footnote).foregroundColor(Theme.Colors.textTertiary)
                }
                if swap.status == .pending {
                    HStack(spacing: Theme.Spacing.sm) {
                        RotaButton(title: "Decline", style: .secondary) { onReject?() }
                        RotaButton(title: "Approve") { onApprove?() }
                    }
                }
            }
        }
    }
}
