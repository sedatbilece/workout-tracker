import Foundation
import SwiftData

@Model
final class WorkoutTemplate {
    // Stable id that survives backup/restore and iCloud sync, unlike `persistentModelID`.
    var uuid: UUID?
    var name: String = ""
    var descriptionText: String = ""
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    // Set when created by a backup restore; picks the survivor if the same
    // backup was restored on two devices (see DuplicateCleaner).
    var importID: UUID?

    // CloudKit requires optional relationships; `exercises` below keeps the old non-optional API.
    @Relationship(deleteRule: .cascade, originalName: "exercises", inverse: \ExerciseTemplate.workout)
    var exerciseItems: [ExerciseTemplate]? = []

    var exercises: [ExerciseTemplate] {
        get { exerciseItems ?? [] }
        set { exerciseItems = newValue }
    }

    init(name: String, descriptionText: String = "") {
        self.uuid = UUID()
        self.name = name
        self.descriptionText = descriptionText
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
