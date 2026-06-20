import Foundation

// Aggregation helpers over completed sets. The Statistics tab only counts
// sets the user actually finished (`isCompleted == true`).

extension WorkoutSession {
    var completedSets: [SetSession] {
        exercises.flatMap(\.sets).filter(\.isCompleted)
    }

    var completedSetCount: Int { completedSets.count }

    var completedReps: Int {
        completedSets.reduce(0) { $0 + $1.reps }
    }

    var completedVolume: Double {
        completedSets.reduce(0) { $0 + $1.kg * Double($1.reps) }
    }
}

extension ExerciseSession {
    var completedSets: [SetSession] {
        sets.filter(\.isCompleted)
    }

    var completedSetCount: Int { completedSets.count }

    var completedReps: Int {
        completedSets.reduce(0) { $0 + $1.reps }
    }
}
