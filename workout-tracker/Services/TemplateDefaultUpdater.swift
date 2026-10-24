import Foundation
import SwiftData

struct TemplateDefaultUpdater {
    static func syncIfNeeded(setSession: SetSession, context: ModelContext) {
        guard let setTemplate = template(for: setSession, context: context) else { return }

        let kgChanged = setSession.kg != setTemplate.defaultKg
        let repsChanged = setSession.reps != setTemplate.defaultReps

        guard kgChanged || repsChanged else { return }

        setSession.templateKgBeforeCompletion = setTemplate.defaultKg
        setSession.templateRepsBeforeCompletion = setTemplate.defaultReps
        setTemplate.defaultKg = setSession.kg
        setTemplate.defaultReps = setSession.reps
    }

    /// Undoes `syncIfNeeded` when a completed set is reopened. The template is
    /// only restored if it still holds this set's values, so a later edit or
    /// another workout's update isn't overwritten.
    static func revertIfNeeded(setSession: SetSession, context: ModelContext) {
        defer {
            setSession.templateKgBeforeCompletion = nil
            setSession.templateRepsBeforeCompletion = nil
        }
        guard let previousKg = setSession.templateKgBeforeCompletion,
              let previousReps = setSession.templateRepsBeforeCompletion,
              let setTemplate = template(for: setSession, context: context),
              setTemplate.defaultKg == setSession.kg,
              setTemplate.defaultReps == setSession.reps
        else { return }

        setTemplate.defaultKg = previousKg
        setTemplate.defaultReps = previousReps
    }

    private static func template(for setSession: SetSession, context: ModelContext) -> SetTemplate? {
        guard setSession.setTemplateUUID != nil else { return nil }
        let templateUUID = setSession.setTemplateUUID

        // A deleted template simply matches nothing here.
        var descriptor = FetchDescriptor<SetTemplate>(predicate: #Predicate { $0.uuid == templateUUID })
        descriptor.fetchLimit = 1
        return (try? context.fetch(descriptor))?.first
    }
}
