import SwiftUI

struct OrganizationSettingsView: View {
    @Environment(SessionStore.self) private var session
    @Environment(ToastCenter.self) private var toasts

    @State private var name = ""
    @State private var overtimeThreshold = 40.0
    @State private var radius = 150.0
    @State private var isSaving = false

    var body: some View {
        Form {
            Section("Organization") {
                TextField("Name", text: $name)

                LabeledContent(
                    "Invite code",
                    value: session.organization?.inviteCode ?? "—"
                )
            }

            Section("Scheduling") {
                Stepper(
                    "Overtime threshold: \(Int(overtimeThreshold))h/week",
                    value: $overtimeThreshold,
                    in: 20...80,
                    step: 1
                )
            }

            Section("Clock-in") {
                VStack(alignment: .leading) {
                    Text("Geofence radius: \(Int(radius))m")
                        .font(.Rota.subheadline)

                    Slider(
                        value: $radius,
                        in: 50...500,
                        step: 10
                    )
                }

                Text("Employees must be within this distance of the workplace to clock in.")
                    .font(.Rota.caption)
                    .foregroundColor(Theme.Colors.textTertiary)
            }

            Section {
                Button {
                    save()
                } label: {
                    HStack {
                        Spacer()

                        if isSaving {
                            ProgressView()
                        } else {
                            Text("Save changes")
                                .fontWeight(.semibold)
                        }

                        Spacer()
                    }
                }
                .disabled(
                    isSaving ||
                    name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                )
            }
        }
        .navigationTitle("Organization")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: populate)
    }

    private func populate() {
        guard let org = session.organization else { return }

        name = org.name
        overtimeThreshold = org.weeklyOvertimeThreshold
        radius = org.clockInRadiusMeters
    }

    private func save() {
        guard var org = session.organization else { return }

        org.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        org.weeklyOvertimeThreshold = overtimeThreshold
        org.clockInRadiusMeters = radius

        isSaving = true

        Task {
            do {
                let updated = try await session.repository.updateOrganization(org)

                await MainActor.run {
                    // refreshOrganization is synchronous, so no await here
                    session.refreshOrganization(updated)

                    toasts.show("Organization updated")
                    isSaving = false
                }
            } catch {
                await MainActor.run {
                    toasts.error("Couldn't save changes")
                    isSaving = false
                }
            }
        }
    }
}
