import Foundation
import SwiftData

struct TemplateDefaultUpdater {
    static func syncIfNeeded(setSession: SetSession, context: ModelContext) {
        guard
            let templateId = setSession.setTemplateId,
            let setTemplate = context.model(for: templateId) as? SetTemplate
        else { return }

        let kgChanged = setSession.kg != setTemplate.defaultKg
        let repsChanged = setSession.reps != setTemplate.defaultReps

        guard kgChanged || repsChanged else { return }

        setTemplate.defaultKg = setSession.kg
        setTemplate.defaultReps = setSession.reps
    }
}
