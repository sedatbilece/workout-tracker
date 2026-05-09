import SwiftUI
import SwiftData

struct WorkoutSessionDetailView: View {
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
}
