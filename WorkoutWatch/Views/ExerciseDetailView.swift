import SwiftUI
import WatchKit

/// What tapping an exercise opens: its first open set, or (when every set is
/// done) the list of its sets to undo one.
struct ExerciseDetailView: View {
    @Environment(WatchStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let exerciseUUID: UUID
    /// Decided when the screen opens, so finishing the last set returns to
    /// the exercise list instead of switching to the set list.
    @State private var showsSetList: Bool?

    private var exercise: WatchWorkoutSnapshot.Exercise? {
        store.snapshot?.exercise(exerciseUUID)
    }

    var body: some View {
        Group {
            if let snapshot = store.snapshot, let exercise {
                if showsSetList == false, let set = exercise.firstOpenSet {
                    SetView(snapshot: snapshot, exercise: exercise, set: set)
                        .id(set.uuid)
                } else {
                    ExerciseSetsView(exercise: exercise) {
                        showsSetList = false
                    }
                }
            } else {
                Color.clear
            }
        }
        .onAppear {
            if showsSetList == nil {
                showsSetList = exercise?.isDone ?? true
            }
        }
        .onChange(of: exercise?.firstOpenSet?.uuid) { _, next in
            if next == nil && showsSetList == false {
                dismiss()
            }
        }
        .onChange(of: exercise == nil) { _, isGone in
            if isGone { dismiss() }
        }
    }
}

enum WKHaptics {
    static func play(_ type: WKHapticType) {
        WKInterfaceDevice.current().play(type)
    }
}
