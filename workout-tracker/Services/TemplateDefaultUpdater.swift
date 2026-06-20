import Foundation
import SwiftData

struct TemplateDefaultUpdater {
    static func syncIfNeeded(setSession: SetSession, context: ModelContext) {
        guard let templateId = setSession.setTemplateId else { return }

        // Resolve against rows actually present in the store and match the id in
        // memory. Using `context.model(for:)` or a `persistentModelID` predicate
        // would crash on a stale or temporary identifier (deleted template, or an
        // id snapshotted before the template was saved) whose backing data can no
        // longer be found. A missing id simply matches nothing here.
        let templates = (try? context.fetch(FetchDescriptor<SetTemplate>())) ?? []
        guard let setTemplate = templates.first(where: { $0.persistentModelID == templateId }) else { return }

        let kgChanged = setSession.kg != setTemplate.defaultKg
        let repsChanged = setSession.reps != setTemplate.defaultReps

        guard kgChanged || repsChanged else { return }

        setTemplate.defaultKg = setSession.kg
        setTemplate.defaultReps = setSession.reps
    }
}
