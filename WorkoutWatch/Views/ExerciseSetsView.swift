import SwiftUI

/// The sets of an exercise whose sets are all done; tapping one offers Undo.
struct ExerciseSetsView: View {
    @Environment(WatchStore.self) private var store
    let exercise: WatchWorkoutSnapshot.Exercise
    /// Called after an undo, so the reopened set is shown.
    let onUndo: () -> Void
    @State private var undoTarget: WatchWorkoutSnapshot.Set?

    var body: some View {
        let strings = store.strings
        List {
            ForEach(Array(exercise.sets.enumerated()), id: \.element.id) { index, set in
                Button {
                    undoTarget = set
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 1) {
                            Text(strings.format("watch_set_label", index + 1))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(strings.weightReps(kg: set.kg, reps: set.reps))
                                .font(.body.monospacedDigit())
                        }
                        Spacer(minLength: 4)
                        statusIcon(set.status)
                    }
                }
                .disabled(set.status == .pending)
            }
        }
        .navigationTitle(exercise.name)
        .confirmationDialog(
            strings["watch_undo_message"],
            isPresented: Binding(get: { undoTarget != nil }, set: { if !$0 { undoTarget = nil } }),
            titleVisibility: .visible
        ) {
            Button(strings["watch_undo"]) {
                guard let set = undoTarget else { return }
                WKHaptics.play(.click)
                store.send(.undo(setUUID: set.uuid))
                onUndo()
            }
            Button(strings["watch_cancel"], role: .cancel) {}
        }
    }

    @ViewBuilder
    private func statusIcon(_ status: WorkoutSetStatus) -> some View {
        switch status {
        case .completed:
            Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
        case .skipped:
            Image(systemName: "forward.end.circle.fill").foregroundStyle(.secondary)
        case .pending:
            Image(systemName: "circle").foregroundStyle(.secondary)
        }
    }
}
