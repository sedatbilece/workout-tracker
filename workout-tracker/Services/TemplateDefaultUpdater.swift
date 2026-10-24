import Foundation
import SwiftData

struct TemplateDefaultUpdater {
    static func syncIfNeeded(setSession: SetSession, context: ModelContext) {
        guard setSession.setTemplateUUID != nil else { return }
        let templateUUID = setSession.setTemplateUUID

        // A deleted template simply matches nothing here.
        var descriptor = FetchDescriptor<SetTemplate>(predicate: #Predicate { $0.uuid == templateUUID })
        descriptor.fetchLimit = 1
        guard let setTemplate = (try? context.fetch(descriptor))?.first else { return }

        let kgChanged = setSession.kg != setTemplate.defaultKg
        let repsChanged = setSession.reps != setTemplate.defaultReps

        guard kgChanged || repsChanged else { return }

        setTemplate.defaultKg = setSession.kg
        setTemplate.defaultReps = setSession.reps
    }
}
