import SwiftUI

struct ExerciseSessionCardView: View {
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
                    SetSessionRowView(set: set, index: index)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)

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
}
