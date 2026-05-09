import SwiftUI
import SwiftData

struct TemplateDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var template: WorkoutTemplate

    @State private var showingEditSheet = false
    @State private var showingAddExerciseSheet = false

    var sortedExercises: [ExerciseTemplate] {
        template.exercises.sorted { $0.orderIndex < $1.orderIndex }
    }

    var body: some View {
        List {
            if !template.descriptionText.isEmpty {
                Section {
                    Text(template.descriptionText)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Hareketler") {
                ForEach(sortedExercises) { exercise in
                    NavigationLink(destination: ExerciseTemplateEditView(template: template, exercise: exercise)) {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(exercise.name)
                                    .font(.body)
                                Text("\(exercise.sets.count) set")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: exercise.iconName)
                                .foregroundStyle(.tint)
                        }
                    }
                }
                .onDelete(perform: deleteExercises)
                .onMove(perform: moveExercises)

                Button {
                    showingAddExerciseSheet = true
                } label: {
                    Label("Hareket Ekle", systemImage: "plus")
                }
            }

            Section {
                Button {
                    addToToday()
                } label: {
                    Label("Bugüne Ekle", systemImage: "calendar.badge.plus")
                        .frame(maxWidth: .infinity)
                        .font(.headline)
                }
                .tint(.accentColor)
            }
        }
        .navigationTitle(template.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Düzenle") {
                    showingEditSheet = true
                }
            }
            ToolbarItem(placement: .navigationBarLeading) {
                EditButton()
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            TemplateEditView(template: template)
        }
        .sheet(isPresented: $showingAddExerciseSheet) {
            ExerciseTemplateEditView(template: template)
        }
    }

    private func addToToday() {
        let session = TemplateSessionBuilder.build(from: template)
        modelContext.insert(session)
    }

    private func deleteExercises(offsets: IndexSet) {
        let sorted = sortedExercises
        for index in offsets {
            modelContext.delete(sorted[index])
        }
        reindexExercises()
    }

    private func moveExercises(from source: IndexSet, to destination: Int) {
        var sorted = sortedExercises
        sorted.move(fromOffsets: source, toOffset: destination)
        for (index, exercise) in sorted.enumerated() {
            exercise.orderIndex = index
        }
    }

    private func reindexExercises() {
        let sorted = template.exercises.sorted { $0.orderIndex < $1.orderIndex }
        for (index, exercise) in sorted.enumerated() {
            exercise.orderIndex = index
        }
    }
}
