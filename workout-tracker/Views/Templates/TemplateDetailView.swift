import SwiftUI
import SwiftData

struct TemplateDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(LocalizationManager.self) private var lm
    @Environment(TabRouter.self) private var tabRouter
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

            Section(lm["template_section_exercises"]) {
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
                    Label(lm["template_add_exercise"], systemImage: "plus")
                }
            }

            Section {
                Button {
                    addToToday()
                } label: {
                    Label(lm["template_add_to_today"], systemImage: "calendar.badge.plus")
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
                Button(lm["common_edit"]) {
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
        tabRouter.selectedTab = 0
    }

    private func deleteExercises(offsets: IndexSet) {
        let sorted = sortedExercises
        for index in offsets {
            let exercise = sorted[index]
            template.exercises.removeAll { $0 === exercise }
            modelContext.delete(exercise)
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
