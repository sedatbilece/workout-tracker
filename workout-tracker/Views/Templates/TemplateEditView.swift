import SwiftUI
import SwiftData

struct TemplateEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(LocalizationManager.self) private var lm

    var template: WorkoutTemplate?

    @State private var name = ""
    @State private var descriptionText = ""

    var isEditing: Bool { template != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section(lm["template_section_info"]) {
                    TextField(lm["template_name_placeholder"], text: $name)
                    TextField(lm["template_description_placeholder"], text: $descriptionText, axis: .vertical)
                        .lineLimit(3...)
                }
            }
            .navigationTitle(isEditing ? lm["template_edit_title"] : lm["template_new_title"])
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(lm["common_cancel"]) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(lm["common_save"]) { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if let template {
                    name = template.name
                    descriptionText = template.descriptionText
                }
            }
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        if let template {
            template.name = trimmedName
            template.descriptionText = descriptionText
            template.updatedAt = Date()
        } else {
            let newTemplate = WorkoutTemplate(name: trimmedName, descriptionText: descriptionText)
            modelContext.insert(newTemplate)
        }
        dismiss()
    }
}

#Preview {
    TemplateEditView()
        .modelContainer(for: WorkoutTemplate.self, inMemory: true)
        .environment(LocalizationManager())
}
