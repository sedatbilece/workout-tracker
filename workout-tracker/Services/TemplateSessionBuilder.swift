import Foundation
import SwiftData

struct TemplateSessionBuilder {
    static func build(from template: WorkoutTemplate) -> WorkoutSession {
        let session = WorkoutSession(templateNameSnapshot: template.name)

        session.exercises = template.exercises
            .sorted { $0.orderIndex < $1.orderIndex }
            .map { exercise in
                let exSession = ExerciseSession(
                    exerciseTemplateUUID: exercise.uuid,
                    nameSnapshot: exercise.name,
                    iconNameSnapshot: exercise.iconName,
                    orderIndex: exercise.orderIndex
                )
                exSession.sets = exercise.sets
                    .sorted { $0.orderIndex < $1.orderIndex }
                    .map { set in
                        SetSession(
                            setTemplateUUID: set.uuid,
                            orderIndex: set.orderIndex,
                            kg: set.defaultKg,
                            reps: set.defaultReps
                        )
                    }
                return exSession
            }

        return session
    }
}
