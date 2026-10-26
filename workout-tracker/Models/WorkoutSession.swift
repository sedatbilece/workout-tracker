import Foundation
import SwiftData

@Model
final class WorkoutSession {
    var uuid: UUID?
    var templateNameSnapshot: String = ""
    var date: Date = Date()
    var isCompleted: Bool = false
    // Workout timer starts at `createdAt` and stops at `endedAt`.
    var createdAt: Date = Date()
    var endedAt: Date?
    // Time between Finish and a later Resume, left out of the duration so a
    // workout resumed an hour later doesn't count that hour.
    var pausedDuration: TimeInterval = 0
    // Last Resume tap; places the pause when writing to Apple Health.
    var resumedAt: Date?
    // Set once the workout is written to Apple Health, to avoid duplicate writes.
    var healthKitWorkoutUUID: UUID?
    // Set when created by a backup restore; picks the survivor if the same
    // backup was restored on two devices (see DuplicateCleaner).
    var importID: UUID?

    @Relationship(deleteRule: .cascade, originalName: "exercises", inverse: \ExerciseSession.workout)
    var exerciseItems: [ExerciseSession]? = []

    var exercises: [ExerciseSession] {
        get { exerciseItems ?? [] }
        set { exerciseItems = newValue }
    }

    init(templateNameSnapshot: String, date: Date = Date()) {
        self.uuid = UUID()
        self.templateNameSnapshot = templateNameSnapshot
        self.date = date
        self.isCompleted = false
        self.createdAt = Date()
    }
}
