import SwiftUI
import SwiftData

struct ExerciseSessionCardView: View {
    @Environment(\.modelContext) private var modelContext
    let exercise: ExerciseSession

    var sortedSets: [SetSession] {
        exercise.sets.sorted { $0.orderIndex < $1.orderIndex }
    }

    var completedCount: Int {
        exercise.sets.filter(\.isCompleted).count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Image(systemName: exercise.iconNameSnapshot)
                    .font(.title3)
                    .foregroundStyle(.tint)
                    .frame(width: 28)

                Text(exercise.nameSnapshot)
                    .font(.headline)

                Spacer()

                Text("\(completedCount)/\(exercise.sets.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 10)

            Divider()
                .padding(.horizontal, 16)

            VStack(spacing: 0) {
                ForEach(Array(sortedSets.enumerated()), id: \.element.id) { index, set in
                    SetSessionRowView(
                        set: set,
                        index: index,
                        onDuplicate: { duplicateSet(set) },
                        onDelete: { deleteSet(set) }
                    )

                    if index < sortedSets.count - 1 {
                        Divider()
                            .padding(.leading, 76)
                    }
                }
            }
            .padding(.bottom, 4)
        }
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func duplicateSet(_ set: SetSession) {
        let newIndex = set.orderIndex + 1
        for s in exercise.sets where s.orderIndex >= newIndex {
            s.orderIndex += 1
        }
        let newSet = SetSession(orderIndex: newIndex, kg: set.kg, reps: set.reps)
        exercise.sets.append(newSet)
    }

    private func deleteSet(_ set: SetSession) {
        exercise.sets.removeAll { $0 === set }
        modelContext.delete(set)
        reindexSets()
    }

    private func reindexSets() {
        let sorted = exercise.sets.sorted { $0.orderIndex < $1.orderIndex }
        for (i, s) in sorted.enumerated() {
            s.orderIndex = i
        }
    }
}
