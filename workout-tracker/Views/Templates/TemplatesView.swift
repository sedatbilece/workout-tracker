import SwiftUI
import SwiftData

struct TemplatesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutTemplate.createdAt, order: .reverse)
    private var templates: [WorkoutTemplate]

    @State private var showingAddSheet = false

    var body: some View {
        NavigationStack {
            Group {
                if templates.isEmpty {
                    ContentUnavailableView(
                        "Şablon Yok",
                        systemImage: "list.bullet.clipboard",
                        description: Text("İlk antrenman şablonunu oluşturmak için + butonuna dokun.")
                    )
                } else {
                    List {
                        ForEach(templates) { template in
                            NavigationLink(destination: TemplateDetailView(template: template)) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(template.name)
                                        .font(.headline)
                                    Text("\(template.exercises.count) hareket")
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
            .navigationTitle("Şablonlar")
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
}
