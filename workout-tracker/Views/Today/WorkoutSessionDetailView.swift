import SwiftUI
import SwiftData

struct WorkoutSessionDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var session: WorkoutSession

    var sortedExercises: [ExerciseSession] {
        session.exercises.sorted { $0.orderIndex < $1.orderIndex }
    }

    var completedSets: Int {
        session.exercises.flatMap(\.sets).filter(\.isCompleted).count
    }

    var totalSets: Int {
        session.exercises.flatMap(\.sets).count
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if sortedExercises.isEmpty {
                    ContentUnavailableView(
                        "Hareket Yok",
                        systemImage: "dumbbell",
                        description: Text("Bu antrenman şablonuna henüz hareket eklenmemiş.")
                    )
                    .padding(.top, 40)
                } else {
                    ForEach(sortedExercises) { exercise in
                        ExerciseSessionCardView(exercise: exercise)
                            .contextMenu {
                                Button(role: .destructive) {
                                    deleteExercise(exercise)
                                } label: {
                                    Label("Egzersizi Sil", systemImage: "trash")
                                }
                            }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .navigationTitle(session.templateNameSnapshot)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .bottomBar) {
                Text("\(completedSets) / \(totalSets) set tamamlandı")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .background(Color(.systemGroupedBackground))
    }

    private func deleteExercise(_ exercise: ExerciseSession) {
        session.exercises.removeAll { $0 === exercise }
        modelContext.delete(exercise)
        reindexExercises()
    }

    private func reindexExercises() {
        let sorted = session.exercises.sorted { $0.orderIndex < $1.orderIndex }
        for (i, ex) in sorted.enumerated() {
            ex.orderIndex = i
        }
    }
}
