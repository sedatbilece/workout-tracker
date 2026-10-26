import SwiftUI
import SwiftData

struct ExerciseTemplateEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(LocalizationManager.self) private var lm

    var template: WorkoutTemplate
    var exercise: ExerciseTemplate?

    @State private var name = ""
    @State private var iconName = "dumbbell"
    @State private var showingIconPicker = false

    var isEditing: Bool { exercise != nil }

    var sortedSets: [SetTemplate] {
        (exercise?.sets ?? []).sorted { $0.orderIndex < $1.orderIndex }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(lm["exercise_section_info"]) {
                    TextField(lm["exercise_name_placeholder"], text: $name)

                    Button {
                        showingIconPicker = true
                    } label: {
                        HStack {
                            Text(lm["icon_label"])
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: iconName)
                                .foregroundStyle(.tint)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                if isEditing, let exercise {
                    Section(lm["exercise_section_sets"]) {
                        ForEach(sortedSets) { set in
                            SetTemplateRowView(set: set, index: set.orderIndex)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    // First action is the outermost: Delete sits on the far right.
                                    Button(role: .destructive) {
                                        deleteSet(set, from: exercise)
                                    } label: {
                                        Label(lm["common_delete"], systemImage: "trash")
                                    }
                                    Button {
                                        duplicateSet(set, in: exercise)
                                    } label: {
                                        Label(lm["common_duplicate"], systemImage: "plus.rectangle.on.rectangle")
                                    }
                                    .tint(.blue)
                                }
                        }
                        .onDelete { offsets in
                            deleteSets(offsets: offsets, from: exercise)
                        }
                        .onMove { source, destination in
                            moveSets(from: source, to: destination, in: exercise)
                        }

                        Button {
                            addSet(to: exercise)
                        } label: {
                            Label(lm["exercise_add_set"], systemImage: "plus")
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? lm["exercise_edit_title"] : lm["exercise_new_title"])
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(lm["common_cancel"]) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(lm["common_save"]) { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                if isEditing {
                    ToolbarItem(placement: .navigationBarLeading) {
                        EditButton()
                    }
                }
            }
            .sheet(isPresented: $showingIconPicker) {
                IconPickerView(selectedIcon: $iconName)
            }
            .onAppear {
                if let exercise {
                    name = exercise.name
                    iconName = exercise.iconName
                }
            }
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        if let exercise {
            exercise.name = trimmedName
            exercise.iconName = iconName
            template.updatedAt = Date()
        } else {
            let newExercise = ExerciseTemplate(
                name: trimmedName,
                iconName: iconName,
                orderIndex: template.exercises.count
            )
            template.exercises.append(newExercise)
            template.updatedAt = Date()
        }
        dismiss()
    }

    private func addSet(to exercise: ExerciseTemplate) {
        let set = SetTemplate(orderIndex: exercise.sets.count)
        exercise.sets.append(set)
    }

    /// Inserts a copy right below `set`; the sets after it move down by one.
    private func duplicateSet(_ set: SetTemplate, in exercise: ExerciseTemplate) {
        let newIndex = set.orderIndex + 1
        for s in exercise.sets where s.orderIndex >= newIndex {
            s.orderIndex += 1
        }
        let copy = SetTemplate(orderIndex: newIndex, defaultKg: set.defaultKg, defaultReps: set.defaultReps)
        exercise.sets.append(copy)
    }

    private func deleteSet(_ set: SetTemplate, from exercise: ExerciseTemplate) {
        exercise.sets.removeAll { $0 === set }
        modelContext.delete(set)
        reindexSets(in: exercise)
    }

    private func deleteSets(offsets: IndexSet, from exercise: ExerciseTemplate) {
        let sorted = exercise.sets.sorted { $0.orderIndex < $1.orderIndex }
        for index in offsets {
            let set = sorted[index]
            exercise.sets.removeAll { $0 === set }
            modelContext.delete(set)
        }
        reindexSets(in: exercise)
    }

    private func moveSets(from source: IndexSet, to destination: Int, in exercise: ExerciseTemplate) {
        var sorted = exercise.sets.sorted { $0.orderIndex < $1.orderIndex }
        sorted.move(fromOffsets: source, toOffset: destination)
        for (index, set) in sorted.enumerated() {
            set.orderIndex = index
        }
    }

    private func reindexSets(in exercise: ExerciseTemplate) {
        let sorted = exercise.sets.sorted { $0.orderIndex < $1.orderIndex }
        for (index, set) in sorted.enumerated() {
            set.orderIndex = index
        }
    }
}
