import SwiftUI
import SwiftData

struct TemplateEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var template: WorkoutTemplate?

    @State private var name = ""
    @State private var descriptionText = ""

    var isEditing: Bool { template != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Şablon Bilgileri") {
                    TextField("Şablon Adı", text: $name)
                    TextField("Açıklama (isteğe bağlı)", text: $descriptionText, axis: .vertical)
                        .lineLimit(3...)
                }
            }
            .navigationTitle(isEditing ? "Şablonu Düzenle" : "Yeni Şablon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") { save() }
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
}
