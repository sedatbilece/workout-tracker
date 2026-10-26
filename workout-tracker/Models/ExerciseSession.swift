import Foundation
import SwiftData

@Model
final class ExerciseSession {
    var uuid: UUID?
    // `uuid` of the originating ExerciseTemplate.
    var exerciseTemplateUUID: UUID?
    // Legacy: encoded PersistentIdentifier, converted to `exerciseTemplateUUID` by DataMigrator.
    var exerciseTemplateIdData: Data?
    var nameSnapshot: String = ""
    var iconNameSnapshot: String = "dumbbell"
    var orderIndex: Int = 0

    var workout: WorkoutSession?

    @Relationship(deleteRule: .cascade, originalName: "sets", inverse: \SetSession.exercise)
    var setItems: [SetSession]? = []

    var sets: [SetSession] {
        get { setItems ?? [] }
        set { setItems = newValue }
    }

    init(
        exerciseTemplateUUID: UUID? = nil,
        nameSnapshot: String,
        iconNameSnapshot: String,
        orderIndex: Int = 0
    ) {
        self.uuid = UUID()
        self.exerciseTemplateUUID = exerciseTemplateUUID
        self.nameSnapshot = nameSnapshot
        self.iconNameSnapshot = iconNameSnapshot
        self.orderIndex = orderIndex
    }
}
