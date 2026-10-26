import Foundation
import SwiftData

@Model
final class SetTemplate {
    var uuid: UUID?
    var orderIndex: Int = 0
    var defaultKg: Double = 0
    var defaultReps: Int = 0

    var exercise: ExerciseTemplate?

    init(orderIndex: Int = 0, defaultKg: Double = 0, defaultReps: Int = 0) {
        self.uuid = UUID()
        self.orderIndex = orderIndex
        self.defaultKg = defaultKg
        self.defaultReps = defaultReps
    }
}
