import Foundation
import SwiftData

@Model
final class ExerciseTemplate {
    var uuid: UUID?
    var name: String = ""
    var iconName: String = "dumbbell"
    var orderIndex: Int = 0

    var workout: WorkoutTemplate?

    @Relationship(deleteRule: .cascade, originalName: "sets", inverse: \SetTemplate.exercise)
    var setItems: [SetTemplate]? = []

    var sets: [SetTemplate] {
        get { setItems ?? [] }
        set { setItems = newValue }
    }

    init(name: String, iconName: String = "dumbbell", orderIndex: Int = 0) {
        self.uuid = UUID()
        self.name = name
        self.iconName = iconName
        self.orderIndex = orderIndex
    }
}
