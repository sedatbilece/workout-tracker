import Foundation
import SwiftData

@Model
final class SetSession {
    var setTemplateIdData: Data?
    var orderIndex: Int
    var kg: Double
    var reps: Int
    var isCompleted: Bool
    var completedAt: Date?

    var setTemplateId: PersistentIdentifier? {
        get {
            guard let data = setTemplateIdData else { return nil }
            return try? JSONDecoder().decode(PersistentIdentifier.self, from: data)
        }
        set {
            setTemplateIdData = try? JSONEncoder().encode(newValue)
        }
    }

    init(
        setTemplateId: PersistentIdentifier? = nil,
        orderIndex: Int = 0,
        kg: Double = 0,
        reps: Int = 0
    ) {
        self.setTemplateIdData = try? JSONEncoder().encode(setTemplateId)
        self.orderIndex = orderIndex
        self.kg = kg
        self.reps = reps
        self.isCompleted = false
        self.completedAt = nil
    }
}
