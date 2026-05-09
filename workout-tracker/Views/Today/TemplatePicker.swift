import SwiftUI
import SwiftData

struct TemplatePicker: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \WorkoutTemplate.name)
    private var templates: [WorkoutTemplate]

    var body: some View {
        NavigationStack {
            Group {
                if templates.isEmpty {
                    ContentUnavailableView(
                        "Şablon Yok",
                        systemImage: "list.bullet.clipboard",
                        description: Text("Önce Şablonlar sekmesinden bir antrenman şablonu oluştur.")
                    )
                } else {
                    List(templates) { template in
                        Button {
                            addToToday(template: template)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(template.name)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                HStack {
                                    Text("\(template.exercises.count) hareket")
                                    if !template.descriptionText.isEmpty {
                                        Text("·")
                                        Text(template.descriptionText)
                                            .lineLimit(1)
                                    }
                                }
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("Şablon Seç")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") { dismiss() }
                }
            }
        }
    }

    private func addToToday(template: WorkoutTemplate) {
        let session = TemplateSessionBuilder.build(from: template)
        modelContext.insert(session)
        dismiss()
    }
}

#Preview {
    TemplatePicker()
        .modelContainer(for: WorkoutTemplate.self, inMemory: true)
}
