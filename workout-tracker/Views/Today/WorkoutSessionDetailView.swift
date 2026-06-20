import SwiftUI
import SwiftData

struct WorkoutSessionDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(LocalizationManager.self) private var lm
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
                        lm["session_no_exercises_title"],
                        systemImage: "dumbbell",
                        description: Text(lm["session_no_exercises_message"])
                    )
                    .padding(.top, 40)
                } else {
                    ForEach(sortedExercises) { exercise in
                        ExerciseSessionCardView(exercise: exercise)
                            .contextMenu {
                                Button(role: .destructive) {
                                    deleteExercise(exercise)
                                } label: {
                                    Label(lm["exercise_delete_title"], systemImage: "trash")
                                }
                            }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .navigationTitle(session.templateNameSnapshot)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 6) {
                    Text(session.templateNameSnapshot)
                        .font(.headline)
                    Text(session.createdAt.timeFormatted)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            ToolbarItem(placement: .bottomBar) {
                Text(lm.format("today_sets_completed", completedSets, totalSets))
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
