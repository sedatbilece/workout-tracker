import Foundation
import SwiftData

@Model
final class WorkoutTemplate {
    var name: String
    var descriptionText: String
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade)
    var exercises: [ExerciseTemplate] = []

    init(name: String, descriptionText: String = "") {
        self.name = name
        self.descriptionText = descriptionText
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
