import Foundation
import SwiftData

@Model
final class SetTemplate {
    var orderIndex: Int
    var defaultKg: Double
    var defaultReps: Int

    init(orderIndex: Int = 0, defaultKg: Double = 0, defaultReps: Int = 0) {
        self.orderIndex = orderIndex
        self.defaultKg = defaultKg
        self.defaultReps = defaultReps
    }
}
