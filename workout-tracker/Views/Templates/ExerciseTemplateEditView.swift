import SwiftUI
import SwiftData

struct ExerciseTemplateEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

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
                Section("Hareket Bilgileri") {
                    TextField("Hareket Adı", text: $name)

                    Button {
                        showingIconPicker = true
                    } label: {
                        HStack {
                            Text("İkon")
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
                    Section("Setler") {
                        ForEach(sortedSets) { set in
                            SetTemplateRowView(set: set, index: set.orderIndex)
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
                            Label("Set Ekle", systemImage: "plus")
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Hareketi Düzenle" : "Yeni Hareket")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") { save() }
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
