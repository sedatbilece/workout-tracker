import Foundation
import SwiftData

@Model
final class ExerciseTemplate {
    var name: String
    var iconName: String
    var orderIndex: Int

    @Relationship(deleteRule: .cascade)
    var sets: [SetTemplate] = []

    init(name: String, iconName: String = "dumbbell", orderIndex: Int = 0) {
        self.name = name
        self.iconName = iconName
        self.orderIndex = orderIndex
    }
}
