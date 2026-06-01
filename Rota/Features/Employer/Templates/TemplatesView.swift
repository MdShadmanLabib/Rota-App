import SwiftUI

@MainActor
@Observable
final class TemplatesViewModel {
    var templates: [ShiftTemplate] = []
    var state: LoadState = .idle

    func load(repository: RotaRepository, organizationId: UUID) async {
        if state == .idle { state = .loading }
        do { templates = try await repository.fetchTemplates(organizationId: organizationId); state = .loaded }
        catch { state = .failed(AppError.from(error).errorDescription ?? "Failed to load") }
    }

    func create(_ template: ShiftTemplate, repository: RotaRepository) async {
        do { let created = try await repository.createTemplate(template); templates.append(created); Haptics.success() }
        catch { Haptics.error() }
    }

    func delete(_ template: ShiftTemplate, repository: RotaRepository) async {
        do { try await repository.deleteTemplate(id: template.id); templates.removeAll { $0.id == template.id } }
        catch { Haptics.error() }
    }
}

struct TemplatesView: View {
    @Environment(SessionStore.self) private var session
    @State private var vm = TemplatesViewModel()
    @State private var showEditor = false

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.sm) {
                if vm.templates.isEmpty && !vm.state.isLoading {
                    EmptyStateView(icon: "square.on.square", title: "No templates",
                                   message: "Save common shifts as templates to build rotas faster.",
                                   actionTitle: "Create template") { showEditor = true }
                        .padding(.top, Theme.Spacing.xl)
                } else {
                    ForEach(vm.templates) { template in
                        TemplateRow(template: template)
                            .contextMenu {
                                Button(role: .destructive) { Task { await vm.delete(template, repository: session.repository) } } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
            }
            .padding(Theme.Spacing.lg)
        }
        .background(Theme.Colors.background)
        .navigationTitle("Templates")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showEditor = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $showEditor) {
            TemplateEditor { name, role, start, end, brk, color in
                guard let orgId = session.organization?.id else { return }
                let template = ShiftTemplate(id: UUID(), organizationId: orgId, name: name, role: role,
                                             startTime: start, endTime: end, breakMinutes: brk, colorHex: color)
                Task { await vm.create(template, repository: session.repository) }
            }
        }
        .task {
            guard let orgId = session.organization?.id else { return }
            await vm.load(repository: session.repository, organizationId: orgId)
        }
    }
}

struct TemplateEditor: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var role = "Floor"
    @State private var start = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: .now) ?? .now
    @State private var end = Calendar.current.date(bySettingHour: 17, minute: 0, second: 0, of: .now) ?? .now
    @State private var breakMinutes = 30
    @State private var colorHex = "#6366F1"

    private let roles = ["Barista", "Floor", "Kitchen", "Shift Lead", "Manager", "Cleaner", "Driver"]
    private let colors = ["#6366F1", "#10B981", "#EC4899", "#F59E0B", "#06B6D4", "#F43F5E"]
    let onSave: (String, String, String, String, Int, String) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Template") {
                    TextField("Name (e.g. Opening)", text: $name)
                    Picker("Role", selection: $role) { ForEach(roles, id: \.self) { Text($0) } }
                }
                Section("Time") {
                    DatePicker("Starts", selection: $start, displayedComponents: .hourAndMinute)
                    DatePicker("Ends", selection: $end, displayedComponents: .hourAndMinute)
                    Stepper("Break: \(breakMinutes) min", value: $breakMinutes, in: 0...120, step: 15)
                }
                Section("Colour") {
                    HStack(spacing: Theme.Spacing.sm) {
                        ForEach(colors, id: \.self) { hex in
                            Circle().fill(Color(hex: hex)).frame(width: 30, height: 30)
                                .overlay(Circle().stroke(Theme.Colors.textPrimary, lineWidth: colorHex == hex ? 2 : 0))
                                .onTapGesture { colorHex = hex; Haptics.selection() }
                        }
                    }
                }
            }
            .navigationTitle("New template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(name, role, start.timeLabel, end.timeLabel, breakMinutes, colorHex); dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
