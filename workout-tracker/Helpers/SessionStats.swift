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

// Workout timer: starts at `createdAt`, stops when the user taps Finish (`endedAt`).
extension WorkoutSession {
    /// The timer is live only for today's unfinished workouts.
    var isRunning: Bool {
        endedAt == nil && createdAt.isToday
    }

    /// Upper bound when a finish time has to be inferred from completed sets.
    static let maxInferredDuration: TimeInterval = 4 * 60 * 60

    /// Finish time, or for an unfinished workout the last completed set that
    /// falls within a plausible window after the start.
    var effectiveEnd: Date {
        if let endedAt { return endedAt }
        let latest = createdAt.addingTimeInterval(Self.maxInferredDuration)
        return completedSets
            .compactMap(\.completedAt)
            .filter { $0 >= createdAt && $0 <= latest }
            .max() ?? createdAt
    }

    var duration: TimeInterval {
        max(0, effectiveEnd.timeIntervalSince(createdAt))
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
