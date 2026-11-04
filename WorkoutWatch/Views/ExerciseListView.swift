import SwiftUI

/// The running workout: timeline on top, one large row per exercise, Finish at the bottom.
struct ExerciseListView: View {
    @Environment(WatchStore.self) private var store
    let snapshot: WatchWorkoutSnapshot
    @State private var isConfirmingFinish = false

    var body: some View {
        let strings = store.strings
        List {
            TimelineHeader(snapshot: snapshot)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 0, leading: 4, bottom: 4, trailing: 4))

            ForEach(snapshot.exercises) { exercise in
                NavigationLink(value: exercise.uuid) {
                    ExerciseRow(exercise: exercise)
                }
            }

            Button(role: .destructive) {
                isConfirmingFinish = true
            } label: {
                Label(strings["watch_finish"], systemImage: "flag.checkered")
                    .frame(maxWidth: .infinity)
            }
            .listRowBackground(Color.red.opacity(0.2).clipShape(.capsule))
        }
        .navigationTitle(snapshot.templateName)
        .confirmationDialog(strings["watch_finish_message"], isPresented: $isConfirmingFinish, titleVisibility: .visible) {
            Button(strings["watch_finish_confirm"], role: .destructive) {
                WKHaptics.play(.success)
                store.finish()
            }
            Button(strings["watch_cancel"], role: .cancel) {}
        }
    }
}

/// Small Dynamic Island–style summary: elapsed time, heart rate and one segment per set.
struct TimelineHeader: View {
    @Environment(WatchStore.self) private var store
    let snapshot: WatchWorkoutSnapshot
    var isCompact = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if !isCompact {
                HStack(spacing: 4) {
                    Text(timerInterval: snapshot.timerStart...Date.distantFuture, countsDown: false)
                        .font(.body.monospacedDigit().weight(.semibold))
                        .foregroundStyle(.tint)
                    Spacer(minLength: 4)
                    if let heartRate = store.metrics.heartRate {
                        Label("\(Int(heartRate.rounded()))", systemImage: "heart.fill")
                            .font(.footnote.monospacedDigit())
                            .foregroundStyle(.red)
                            .labelStyle(.titleAndIcon)
                    }
                }
            }
            SetProgressBar(statuses: snapshot.setStatuses, accent: snapshot.accent.color, height: isCompact ? 3 : 4)
            if !isCompact {
                Text(store.strings.format("watch_sets_done", snapshot.completedSetCount, snapshot.totalSetCount))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct ExerciseRow: View {
    @Environment(WatchStore.self) private var store
    let exercise: WatchWorkoutSnapshot.Exercise

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: exercise.isDone ? "checkmark.circle.fill" : exercise.icon)
                .font(.title3)
                .foregroundStyle(exercise.isDone ? AnyShapeStyle(.green) : AnyShapeStyle(.tint))
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.name)
                    .font(.headline)
                    .lineLimit(2)
                Text("\(exercise.doneCount)/\(exercise.sets.count)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .frame(minHeight: 44)
        .opacity(exercise.isDone ? 0.55 : 1)
    }
}
