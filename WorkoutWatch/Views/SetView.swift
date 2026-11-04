import SwiftUI

/// One open set: weight and reps set with the Digital Crown, then Complete,
/// Skip or Delete. ExerciseDetailView swaps in the next open set afterwards.
struct SetView: View {
    @Environment(WatchStore.self) private var store
    let snapshot: WatchWorkoutSnapshot
    let exercise: WatchWorkoutSnapshot.Exercise
    let set: WatchWorkoutSnapshot.Set

    @State private var kg: Double
    @State private var reps: Double
    @FocusState private var focus: Field?
    @State private var isConfirmingDelete = false

    private enum Field { case kg, reps }

    init(snapshot: WatchWorkoutSnapshot, exercise: WatchWorkoutSnapshot.Exercise, set: WatchWorkoutSnapshot.Set) {
        self.snapshot = snapshot
        self.exercise = exercise
        self.set = set
        _kg = State(initialValue: set.kg)
        _reps = State(initialValue: Double(set.reps))
    }

    private var setNumber: Int {
        (exercise.sets.firstIndex { $0.uuid == set.uuid } ?? 0) + 1
    }

    var body: some View {
        let strings = store.strings
        ScrollView {
            VStack(spacing: 8) {
                TimelineHeader(snapshot: snapshot, isCompact: true)

                VStack(alignment: .leading, spacing: 0) {
                    Text(strings.format("watch_set_progress", setNumber, exercise.sets.count))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(exercise.name)
                        .font(.headline)
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 6) {
                    ValueField(text: formattedKg, unit: strings["watch_kg"], isFocused: focus == .kg)
                        .focusable()
                        .focused($focus, equals: .kg)
                        .digitalCrownRotation($kg, from: 0, through: 500, by: 2.5, sensitivity: .medium, isContinuous: false, isHapticFeedbackEnabled: true)
                        .onTapGesture { focus = .kg }
                    ValueField(text: "\(Int(reps.rounded()))", unit: strings["watch_reps"], isFocused: focus == .reps)
                        .focusable()
                        .focused($focus, equals: .reps)
                        .digitalCrownRotation($reps, from: 1, through: Double(max(20, set.reps)), by: 1, sensitivity: .low, isContinuous: false, isHapticFeedbackEnabled: true)
                        .onTapGesture { focus = .reps }
                }

                Button {
                    WKHaptics.play(.success)
                    store.send(.complete(setUUID: set.uuid, kg: kg, reps: Int(reps.rounded())))
                } label: {
                    Label(strings["watch_complete"], systemImage: "checkmark")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)

                HStack(spacing: 6) {
                    Button {
                        WKHaptics.play(.click)
                        store.send(.skip(setUUID: set.uuid))
                    } label: {
                        Label(strings["watch_skip"], systemImage: "forward.end.fill")
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .frame(maxWidth: .infinity)
                    }
                    .tint(.gray)
                    Button(role: .destructive) {
                        isConfirmingDelete = true
                    } label: {
                        Image(systemName: "trash")
                    }
                    .frame(width: 52)
                    .tint(.red)
                    .accessibilityLabel(strings["watch_delete"])
                }
            }
        }
        .onAppear { focus = .kg }
        .confirmationDialog(strings["watch_delete_message"], isPresented: $isConfirmingDelete, titleVisibility: .visible) {
            Button(strings["watch_delete"], role: .destructive) {
                WKHaptics.play(.directionDown)
                store.send(.delete(setUUID: set.uuid))
            }
            Button(strings["watch_cancel"], role: .cancel) {}
        }
    }

    private var formattedKg: String {
        NumberFormatter.workoutWeight.string(from: NSNumber(value: kg)) ?? "\(kg)"
    }
}

/// A number the Digital Crown changes while it is focused (outlined in the theme color).
private struct ValueField: View {
    let text: String
    let unit: String
    let isFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            Text(text)
                .font(.title2.monospacedDigit().weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(unit)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .stroke(isFocused ? AnyShapeStyle(.tint) : AnyShapeStyle(Color.clear), lineWidth: 2)
        }
        .contentShape(RoundedRectangle(cornerRadius: 10))
    }
}
