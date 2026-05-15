import SwiftUI
import SwiftData

struct TemplatesView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(LocalizationManager.self) private var lm
    @Query(sort: \WorkoutTemplate.createdAt, order: .reverse)
    private var templates: [WorkoutTemplate]

    @State private var showingAddSheet = false

    var body: some View {
        NavigationStack {
            Group {
                if templates.isEmpty {
                    ContentUnavailableView(
                        lm["templates_no_templates_title"],
                        systemImage: "list.bullet.clipboard",
                        description: Text(lm["templates_no_templates_message"])
                    )
                } else {
                    List {
                        ForEach(templates) { template in
                            NavigationLink(destination: TemplateDetailView(template: template)) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(template.name)
                                        .font(.headline)
                                    Text(lm.format("today_exercises_count", template.exercises.count))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .onDelete(perform: deleteTemplates)
                    }
                }
            }
            .navigationTitle(lm["templates_title"])
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                TemplateEditView()
            }
        }
    }

    private func deleteTemplates(offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(templates[index])
        }
    }
}

#Preview {
    TemplatesView()
        .modelContainer(for: WorkoutTemplate.self, inMemory: true)
        .environment(LocalizationManager())
}
