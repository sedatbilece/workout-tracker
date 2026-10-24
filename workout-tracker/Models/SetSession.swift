import Foundation
import SwiftData

@Model
final class SetSession {
    var uuid: UUID?
    // `uuid` of the originating SetTemplate.
    var setTemplateUUID: UUID?
    // Legacy: encoded PersistentIdentifier, converted to `setTemplateUUID` by DataMigrator.
    var setTemplateIdData: Data?
    var orderIndex: Int = 0
    var kg: Double = 0
    var reps: Int = 0
    var isCompleted: Bool = false
    var completedAt: Date?

    var exercise: ExerciseSession?

    init(
        setTemplateUUID: UUID? = nil,
        orderIndex: Int = 0,
        kg: Double = 0,
        reps: Int = 0
    ) {
        self.uuid = UUID()
        self.setTemplateUUID = setTemplateUUID
        self.orderIndex = orderIndex
        self.kg = kg
        self.reps = reps
        self.isCompleted = false
        self.completedAt = nil
    }
}
