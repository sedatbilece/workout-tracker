import Foundation
import SwiftData

@Model
final class ExerciseSession {
    var exerciseTemplateIdData: Data?
    var nameSnapshot: String
    var iconNameSnapshot: String
    var orderIndex: Int

    @Relationship(deleteRule: .cascade)
    var sets: [SetSession] = []

    var exerciseTemplateId: PersistentIdentifier? {
        get {
            guard let data = exerciseTemplateIdData else { return nil }
            return try? JSONDecoder().decode(PersistentIdentifier.self, from: data)
        }
        set {
            exerciseTemplateIdData = try? JSONEncoder().encode(newValue)
        }
    }

    init(
        exerciseTemplateId: PersistentIdentifier? = nil,
        nameSnapshot: String,
        iconNameSnapshot: String,
        orderIndex: Int = 0
    ) {
        self.exerciseTemplateIdData = try? JSONEncoder().encode(exerciseTemplateId)
        self.nameSnapshot = nameSnapshot
        self.iconNameSnapshot = iconNameSnapshot
        self.orderIndex = orderIndex
    }
}
