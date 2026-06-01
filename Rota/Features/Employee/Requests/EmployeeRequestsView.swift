import SwiftUI

struct EmployeeRequestsView: View {
    @Environment(SessionStore.self) private var session
    @Environment(ToastCenter.self) private var toasts
    @State private var vm = EmployeeRequestsViewModel()
    @State private var tab: Tab = .leave
    @State private var showLeaveSheet = false
    @State private var showSwapSheet = false

    enum Tab: Hashable { case leave, swaps }

    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            RotaSegmentedControl(options: [Tab.leave, .swaps], titleFor: { $0 == .leave ? "Leave" : "Swaps" }, selection: $tab)
                .padding(.horizontal, Theme.Spacing.lg)

            ScrollView {
                VStack(spacing: Theme.Spacing.sm) {
                    if tab == .leave { leaveList } else { swapList }
                }
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.bottom, Theme.Spacing.xxl)
            }
        }
        .padding(.top, Theme.Spacing.sm)
        .background(Theme.Colors.background)
        .navigationTitle("Requests")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { tab == .leave ? (showLeaveSheet = true) : (showSwapSheet = true) } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showLeaveSheet) { leaveSheet }
        .sheet(isPresented: $showSwapSheet) { swapSheet }
        .task { await reload() }
        .refreshable { await reload() }
    }

    private func reload() async {
        guard let user = session.currentUser else { return }
        await vm.load(repository: session.repository, userId: user.id, organizationId: user.organizationId)
    }

    @ViewBuilder private var leaveList: some View {
        if vm.leave.isEmpty && !vm.state.isLoading {
            EmptyStateView(icon: "sun.max", title: "No leave requests",
                           message: "Request time off and track approvals here.",
                           actionTitle: "Request leave") { showLeaveSheet = true }
                .padding(.top, Theme.Spacing.xl)
        } else {
            ForEach(vm.leave) { request in
                RotaCard {
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        HStack {
                            Label(request.type.label, systemImage: request.type.icon)
                                .font(.Rota.headline).foregroundColor(Theme.Colors.textPrimary)
                            Spacer()
                            Badge(text: request.status.label, tone: request.status.tone)
                        }
                        Text(request.rangeLabel).font(.Rota.subheadline).foregroundColor(Theme.Colors.textSecondary)
                        Text("\(request.dayCount) day\(request.dayCount > 1 ? "s" : "")")
                            .font(.Rota.caption).foregroundColor(Theme.Colors.textTertiary)
                        if let reason = request.reason {
                            Text(reason).font(.Rota.footnote).foregroundColor(Theme.Colors.textSecondary)
                        }
                        if request.status == .pending {
                            Button("Cancel request", role: .destructive) {
                                Task { await vm.cancelLeave(request, repository: session.repository); toasts.show("Request cancelled") }
                            }
                            .font(.Rota.subheadline)
                            .padding(.top, 2)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder private var swapList: some View {
        if vm.swaps.isEmpty && !vm.state.isLoading {
            EmptyStateView(icon: "arrow.left.arrow.right", title: "No swap requests",
                           message: "Offer a shift to a teammate when you can't make it.",
                           actionTitle: "Request swap") { showSwapSheet = true }
                .padding(.top, Theme.Spacing.xl)
        } else {
            ForEach(vm.swaps) { request in
                RotaCard {
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        HStack {
                            Text(vm.shift(request.shiftId)?.title ?? "Shift")
                                .font(.Rota.headline).foregroundColor(Theme.Colors.textPrimary)
                            Spacer()
                            Badge(text: request.status.label, tone: request.status.tone)
                        }
                        if let shift = vm.shift(request.shiftId) {
                            Text("\(shift.startAt.dayMonthLabel) · \(shift.timeRangeLabel)")
                                .font(.Rota.subheadline).foregroundColor(Theme.Colors.textSecondary)
                        }
                        Text("To: \(vm.name(for: request.targetUserId))")
                            .font(.Rota.caption).foregroundColor(Theme.Colors.textTertiary)
                        if let message = request.message {
                            Text(message).font(.Rota.footnote).foregroundColor(Theme.Colors.textSecondary)
                        }
                    }
                }
            }
        }
    }

    private var leaveSheet: some View {
        LeaveRequestSheet { type, start, end, reason in
            guard let user = session.currentUser, let orgId = user.organizationId else { return false }
            let err = await vm.submitLeave(repository: session.repository, userId: user.id, organizationId: orgId,
                                           type: type, start: start, end: end, reason: reason)
            if let err { toasts.error(err); return false }
            toasts.show("Leave requested"); return true
        }
    }

    private var swapSheet: some View {
        SwapRequestSheet(shifts: vm.myShifts, team: vm.team, currentUserId: session.currentUser?.id) { shiftId, target, message in
            guard let user = session.currentUser, let orgId = user.organizationId else { return false }
            let err = await vm.submitSwap(repository: session.repository, userId: user.id, organizationId: orgId,
                                          shiftId: shiftId, targetUserId: target, message: message)
            if let err { toasts.error(err); return false }
            toasts.show("Swap requested"); return true
        }
    }
}
