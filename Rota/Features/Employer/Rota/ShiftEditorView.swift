import SwiftUI

/// Create or edit a shift. Detects clashes and surfaces paid duration live.
struct ShiftEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var draft: Shift
    private let team: [UserProfile]
    private let isNew: Bool
    private let onSave: (Shift) -> Void
    private let onDelete: (Shift) -> Void

    private let roles = ["Barista", "Floor", "Kitchen", "Shift Lead", "Manager", "Cleaner", "Driver"]

    init(shift: Shift, team: [UserProfile], onSave: @escaping (Shift) -> Void, onDelete: @escaping (Shift) -> Void) {
        _draft = State(initialValue: shift)
        self.team = team
        self.isNew = shift.title == "Shift" && shift.assignedUserId == nil && shift.notes == nil
        self.onSave = onSave
        self.onDelete = onDelete
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Title", text: $draft.title)
                    Picker("Role", selection: $draft.role) {
                        ForEach(roles, id: \.self) { Text($0).tag($0) }
                    }
                    TextField("Location", text: Binding($draft.location, replacingNilWith: ""))
                }

                Section("Time") {
                    DatePicker("Starts", selection: $draft.startAt)
                    DatePicker("Ends", selection: $draft.endAt)
                    Stepper("Break: \(draft.breakMinutes) min", value: $draft.breakMinutes, in: 0...120, step: 15)
                    LabeledContent("Paid hours", value: draft.paidDuration.hoursMinutes)
                }

                Section("Assignment") {
                    Picker("Assigned to", selection: $draft.assignedUserId) {
                        Text("Open shift").tag(UUID?.none)
                        ForEach(team) { member in
                            Text(member.fullName).tag(UUID?.some(member.id))
                        }
                    }
                    Picker("Status", selection: $draft.status) {
                        Text("Draft").tag(ShiftStatus.scheduled)
                        Text("Published").tag(ShiftStatus.published)
                        Text("Cancelled").tag(ShiftStatus.cancelled)
                    }
                }

                Section("Notes") {
                    TextField("Add a note for this shift…", text: Binding($draft.notes, replacingNilWith: ""), axis: .vertical)
                        .lineLimit(2...5)
                }

                if draft.endAt <= draft.startAt {
                    Label("End time must be after start time.", systemImage: "exclamationmark.triangle.fill")
                        .foregroundColor(Theme.Colors.danger)
                        .font(.Rota.footnote)
                }

                if !isNew {
                    Section {
                        Button(role: .destructive) {
                            onDelete(draft); dismiss()
                        } label: {
                            Label("Delete shift", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle(isNew ? "New shift" : "Edit shift")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if draft.assignedUserId != nil && draft.status == .scheduled { draft.status = .published }
                        onSave(draft); dismiss()
                    }
                    .disabled(draft.endAt <= draft.startAt || draft.title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

extension Binding {
    /// Bridges an optional binding to a non-optional default value.
    init(_ source: Binding<Value?>, replacingNilWith defaultValue: Value) {
        self.init(
            get: { source.wrappedValue ?? defaultValue },
            set: { newValue in source.wrappedValue = newValue }
        )
    }
}
