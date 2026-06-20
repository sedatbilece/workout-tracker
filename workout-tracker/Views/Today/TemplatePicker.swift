import SwiftUI
import SwiftData

struct TemplatePicker: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(LocalizationManager.self) private var lm

    @Query(sort: \WorkoutTemplate.name)
    private var templates: [WorkoutTemplate]

    var body: some View {
        NavigationStack {
            Group {
                if templates.isEmpty {
                    ContentUnavailableView(
                        lm["templates_no_templates_title"],
                        systemImage: "list.bullet.clipboard",
                        description: Text(lm["template_picker_empty"])
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
                                    Text(lm.format("today_exercises_count", template.exercises.count))
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
            .navigationTitle(lm["template_picker_title"])
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(lm["common_cancel"]) { dismiss() }
                }
            }
        }
    }

    private func addToToday(template: WorkoutTemplate) {
        // Persist any unsaved template edits first so the snapshotted set/exercise
        // ids are permanent (not temporary), otherwise syncing back later fails.
        try? modelContext.save()
        let session = TemplateSessionBuilder.build(from: template)
        modelContext.insert(session)
        dismiss()
    }
}

#Preview {
    TemplatePicker()
        .modelContainer(for: WorkoutTemplate.self, inMemory: true)
        .environment(LocalizationManager())
}
