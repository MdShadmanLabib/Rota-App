import SwiftUI

/// Sheet for composing a leave request. Returns true to dismiss on success.
struct LeaveRequestSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onSubmit: (LeaveType, Date, Date, String) async -> Bool

    @State private var type: LeaveType = .holiday
    @State private var start = Date()
    @State private var end = Date()
    @State private var reason = ""
    @State private var isSubmitting = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Type") {
                    Picker("Type", selection: $type) {
                        ForEach(LeaveType.allCases) { t in
                            Label(t.label, systemImage: t.icon).tag(t)
                        }
                    }
                    .pickerStyle(.menu)
                }
                Section("Dates") {
                    DatePicker("From", selection: $start, displayedComponents: .date)
                    DatePicker("To", selection: $end, in: start..., displayedComponents: .date)
                }
                Section("Reason (optional)") {
                    TextField("Add a note for your manager", text: $reason, axis: .vertical).lineLimit(2...4)
                }
            }
            .navigationTitle("Request leave")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Submit") { submit() }.disabled(isSubmitting)
                }
            }
        }
    }

    private func submit() {
        isSubmitting = true
        Task {
            let ok = await onSubmit(type, start, end, reason)
            isSubmitting = false
            if ok { dismiss() }
        }
    }
}

/// Sheet for offering a shift swap to a teammate.
struct SwapRequestSheet: View {
    @Environment(\.dismiss) private var dismiss
    let shifts: [Shift]
    let team: [UserProfile]
    let currentUserId: UUID?
    let onSubmit: (UUID, UUID?, String) async -> Bool

    @State private var selectedShiftId: UUID?
    @State private var targetId: UUID?
    @State private var message = ""
    @State private var isSubmitting = false

    private var myShifts: [Shift] {
        shifts.filter { $0.assignedUserId == currentUserId && $0.endAt > .now }.sorted { $0.startAt < $1.startAt }
    }
    private var others: [UserProfile] { team.filter { $0.id != currentUserId } }

    var body: some View {
        NavigationStack {
            Form {
                Section("Shift to give away") {
                    if myShifts.isEmpty {
                        Text("You have no upcoming shifts to swap.").foregroundColor(Theme.Colors.textSecondary)
                    } else {
                        Picker("Shift", selection: $selectedShiftId) {
                            Text("Select a shift").tag(UUID?.none)
                            ForEach(myShifts) { shift in
                                Text("\(shift.startAt.dayMonthLabel) · \(shift.timeRangeLabel)").tag(UUID?.some(shift.id))
                            }
                        }
                    }
                }
                Section("Offer to") {
                    Picker("Teammate", selection: $targetId) {
                        Text("Anyone on the team").tag(UUID?.none)
                        ForEach(others) { member in Text(member.fullName).tag(UUID?.some(member.id)) }
                    }
                }
                Section("Message (optional)") {
                    TextField("Add context", text: $message, axis: .vertical).lineLimit(2...4)
                }
            }
            .navigationTitle("Request swap")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Submit") { submit() }.disabled(isSubmitting || selectedShiftId == nil)
                }
            }
            .onAppear { if selectedShiftId == nil { selectedShiftId = myShifts.first?.id } }
        }
    }

    private func submit() {
        guard let shiftId = selectedShiftId else { return }
        isSubmitting = true
        Task {
            let ok = await onSubmit(shiftId, targetId, message)
            isSubmitting = false
            if ok { dismiss() }
        }
    }
}
