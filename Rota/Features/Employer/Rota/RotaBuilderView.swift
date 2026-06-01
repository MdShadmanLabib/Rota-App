import SwiftUI

struct RotaBuilderView: View {
    @Environment(SessionStore.self) private var session
    @Environment(ToastCenter.self) private var toasts
    @State private var vm = RotaBuilderViewModel()

    @State private var viewMode: ViewMode = .day
    @State private var editingShift: Shift?
    @State private var assigningShift: Shift?
    @State private var showTemplates = false
    @State private var shareURL: ShareURL?

    enum ViewMode: String, CaseIterable { case day = "Day", week = "Week" }

    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            WeekNavigator(weekStart: $vm.weekStart) {
                Task { await vm.load(repository: session.repository) }
            }
            .padding(.horizontal, Theme.Spacing.lg)

            RotaSegmentedControl(options: ViewMode.allCases, titleFor: { $0.rawValue }, selection: $viewMode)
                .padding(.horizontal, Theme.Spacing.lg)

            summaryBar.padding(.horizontal, Theme.Spacing.lg)

            if viewMode == .day {
                DayStrip(weekStart: vm.weekStart, selectedDay: $vm.selectedDay)
                    .padding(.horizontal, Theme.Spacing.lg)
            } else {
                teamPalette
            }

            content
        }
        .padding(.top, Theme.Spacing.sm)
        .background(Theme.Colors.background)
        .navigationTitle("Rota")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { autoSchedule() } label: { Label("Auto‑schedule open shifts", systemImage: "wand.and.stars") }
                    Button { showTemplates = true } label: { Label("Apply template", systemImage: "square.on.square") }
                    Button { exportPDF() } label: { Label("Export PDF", systemImage: "square.and.arrow.up") }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button { editingShift = vm.newShiftTemplate(on: vm.selectedDay) } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .task {
            vm.configure(organizationId: session.organization?.id ?? UUID(), createdBy: session.currentUser?.id)
            await vm.load(repository: session.repository)
        }
        .sheet(item: $editingShift) { shift in
            ShiftEditorView(shift: shift, team: vm.team) { saved in
                Task { await vm.save(saved, repository: session.repository); toasts.show("Shift saved") }
            } onDelete: { toDelete in
                Task { await vm.delete(toDelete, repository: session.repository); toasts.show("Shift deleted", tone: .danger, icon: "trash.fill") }
            }
        }
        .sheet(item: $assigningShift) { shift in
            AssignSheet(shift: shift, team: vm.team) { userId in
                Task { await vm.assign(shift, to: userId, repository: session.repository); toasts.show("Shift assigned") }
            }
        }
        .sheet(isPresented: $showTemplates) {
            TemplatePickerSheet(templates: vm.templates) { template in
                Task { await vm.apply(template: template, on: vm.selectedDay, repository: session.repository); toasts.show("Template applied") }
            }
        }
        .sheet(item: $shareURL) { item in ShareSheet(url: item.url) }
    }

    private var summaryBar: some View {
        HStack(spacing: Theme.Spacing.sm) {
            metric(icon: "clock.fill", value: "\(Int(vm.weeklyHours))h", label: "scheduled", tone: .accent)
            metric(icon: "calendar.badge.exclamationmark", value: "\(vm.openCount)", label: "open", tone: .warning)
            metric(icon: "exclamationmark.triangle.fill", value: "\(vm.conflicts.count)", label: "clashes",
                   tone: vm.conflicts.isEmpty ? .success : .danger)
        }
    }

    private func metric(icon: String, value: String, label: String, tone: BadgeTone) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).foregroundColor(tone.fg).font(.system(size: 13, weight: .semibold))
            Text(value).font(.Rota.subheadline).foregroundColor(Theme.Colors.textPrimary)
            Text(label).font(.Rota.caption).foregroundColor(Theme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.xs)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous))
    }

    private var teamPalette: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.sm) {
                Text("Drag onto a shift →")
                    .font(.Rota.caption)
                    .foregroundColor(Theme.Colors.textTertiary)
                ForEach(vm.team) { member in
                    VStack(spacing: 4) {
                        Avatar(name: member.fullName, size: 40)
                        Text(member.firstName).font(.Rota.caption2).foregroundColor(Theme.Colors.textSecondary)
                    }
                    .draggable(member.id.uuidString)
                }
            }
            .padding(.horizontal, Theme.Spacing.lg)
        }
    }

    @ViewBuilder private var content: some View {
        if vm.state.isLoading && vm.shifts.isEmpty {
            ScrollView { VStack(spacing: Theme.Spacing.sm) { ForEach(0..<4, id: \.self) { _ in SkeletonCard() } }.padding(Theme.Spacing.lg) }
        } else if viewMode == .day {
            dayList
        } else {
            weekList
        }
    }

    private var dayList: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.sm) {
                let dayShifts = vm.shifts(on: vm.selectedDay)
                if dayShifts.isEmpty {
                    EmptyStateView(icon: "calendar.badge.plus", title: "No shifts yet",
                                   message: "Add a shift or apply a template to build \(vm.selectedDay.formatted("EEEE"))'s rota.",
                                   actionTitle: "Add shift") {
                        editingShift = vm.newShiftTemplate(on: vm.selectedDay)
                    }
                    .padding(.top, Theme.Spacing.xl)
                } else {
                    ForEach(dayShifts) { shift in shiftRow(shift) }
                }
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.bottom, Theme.Spacing.xxl)
        }
    }

    private var weekList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                ForEach(vm.weekStart.weekDays, id: \.self) { day in
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        HStack {
                            Text(day.formatted("EEEE d")).font(.Rota.headline)
                                .foregroundColor(day.isToday ? Theme.Colors.accent : Theme.Colors.textPrimary)
                            Spacer()
                            Button { editingShift = vm.newShiftTemplate(on: day) } label: {
                                Image(systemName: "plus.circle.fill").foregroundColor(Theme.Colors.accent)
                            }
                        }
                        let dayShifts = vm.shifts(on: day)
                        if dayShifts.isEmpty {
                            Text("No shifts").font(.Rota.footnote).foregroundColor(Theme.Colors.textTertiary)
                        } else {
                            ForEach(dayShifts) { shift in shiftRow(shift) }
                        }
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.bottom, Theme.Spacing.xxl)
        }
    }

    private func shiftRow(_ shift: Shift) -> some View {
        ShiftCard(shift: shift, assigneeName: vm.name(for: shift.assignedUserId)) {
            editingShift = shift
        }
        .overlay(alignment: .topTrailing) {
            if vm.hasConflict(shift) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Theme.Colors.danger)
                    .padding(8)
            }
        }
        .contextMenu {
            Button { assigningShift = shift } label: { Label("Assign", systemImage: "person.badge.plus") }
            Button(role: .destructive) {
                Task { await vm.delete(shift, repository: session.repository) }
            } label: { Label("Delete", systemImage: "trash") }
        }
        .dropDestination(for: String.self) { items, _ in
            guard let first = items.first, let userId = UUID(uuidString: first) else { return false }
            Task { await vm.assign(shift, to: userId, repository: session.repository); toasts.show("Shift assigned") }
            return true
        }
    }

    private func autoSchedule() {
        Task {
            let count = await vm.autoSchedule(repository: session.repository)
            if count > 0 { toasts.show("Auto‑assigned \(count) shift\(count > 1 ? "s" : "")") }
            else { toasts.show("No open shifts to assign", tone: .info, icon: "info.circle.fill") }
        }
    }

    private func exportPDF() {
        guard let url = PDFExporter.exportWeeklyRota(
            organizationName: session.organization?.name ?? "Rota",
            weekStart: vm.weekStart, shifts: vm.shifts, nameFor: { vm.name(for: $0) }
        ) else { toasts.error("Couldn't generate PDF"); return }
        shareURL = ShareURL(url: url)
    }
}

struct ShareURL: Identifiable { let id = UUID(); let url: URL }
