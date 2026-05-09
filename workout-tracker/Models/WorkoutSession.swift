import Foundation
import SwiftData

@Model
final class WorkoutSession {
    var templateNameSnapshot: String
    var date: Date
    var isCompleted: Bool
    var createdAt: Date

    @Relationship(deleteRule: .cascade)
    var exercises: [ExerciseSession] = []

    init(templateNameSnapshot: String, date: Date = Date()) {
        self.templateNameSnapshot = templateNameSnapshot
        self.date = date
        self.isCompleted = false
        self.createdAt = Date()
    }
}
