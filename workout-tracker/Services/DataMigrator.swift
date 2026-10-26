import Foundation
import SwiftData

// Brings older stores up to the current schema conventions. Idempotent, safe
// to run on every launch (also covers rows arriving from iCloud sync).
struct DataMigrator {
    static func run(context: ModelContext) {
        assignMissingUUIDs(WorkoutTemplate.self, context: context)
        assignMissingUUIDs(ExerciseTemplate.self, context: context)
        assignMissingUUIDs(SetTemplate.self, context: context)
        assignMissingUUIDs(WorkoutSession.self, context: context)
        assignMissingUUIDs(ExerciseSession.self, context: context)
        assignMissingUUIDs(SetSession.self, context: context)

        convertLegacyTemplateLinks(context: context)

        if context.hasChanges {
            try? context.save()
        }
    }

    private static func assignMissingUUIDs<T: PersistentModel & UUIDIdentified>(_ type: T.Type, context: ModelContext) {
        let models = (try? context.fetch(FetchDescriptor<T>())) ?? []
        for model in models where model.uuid == nil {
            model.uuid = UUID()
        }
    }

    // Sessions used to reference templates by an encoded `PersistentIdentifier`,
    // which is only valid in the local store. Map those to template UUIDs and
    // drop the legacy data. A decoded identifier doesn't hash like the one read
    // from the store, so both sides are matched by their encoded URI instead.
    private static func convertLegacyTemplateLinks(context: ModelContext) {
        let exerciseSessions = ((try? context.fetch(FetchDescriptor<ExerciseSession>())) ?? [])
            .filter { $0.exerciseTemplateIdData != nil }
        let setSessions = ((try? context.fetch(FetchDescriptor<SetSession>())) ?? [])
            .filter { $0.setTemplateIdData != nil }
        guard !exerciseSessions.isEmpty || !setSessions.isEmpty else { return }

        let exerciseTemplates = (try? context.fetch(FetchDescriptor<ExerciseTemplate>())) ?? []
        let setTemplates = (try? context.fetch(FetchDescriptor<SetTemplate>())) ?? []
        let exerciseUUIDs = uuidsByURI(exerciseTemplates)
        let setUUIDs = uuidsByURI(setTemplates)

        for session in exerciseSessions {
            if session.exerciseTemplateUUID == nil, let uri = legacyURI(session.exerciseTemplateIdData) {
                session.exerciseTemplateUUID = exerciseUUIDs[uri]
            }
            session.exerciseTemplateIdData = nil
        }
        for session in setSessions {
            if session.setTemplateUUID == nil, let uri = legacyURI(session.setTemplateIdData) {
                session.setTemplateUUID = setUUIDs[uri]
            }
            session.setTemplateIdData = nil
        }
    }

    private static func uuidsByURI<T: PersistentModel & UUIDIdentified>(_ models: [T]) -> [String: UUID] {
        var result: [String: UUID] = [:]
        for model in models {
            guard let uuid = model.uuid,
                  let data = try? JSONEncoder().encode(model.persistentModelID),
                  let uri = legacyURI(data) else { continue }
            result[uri] = uuid
        }
        return result
    }

    private struct EncodedIdentifier: Decodable {
        struct Implementation: Decodable { let uriRepresentation: String }
        let implementation: Implementation
    }

    private static func legacyURI(_ data: Data?) -> String? {
        guard let data else { return nil }
        return (try? JSONDecoder().decode(EncodedIdentifier.self, from: data))?.implementation.uriRepresentation
    }
}

protocol UUIDIdentified: AnyObject {
    var uuid: UUID? { get set }
}

extension WorkoutTemplate: UUIDIdentified {}
extension ExerciseTemplate: UUIDIdentified {}
extension SetTemplate: UUIDIdentified {}
extension WorkoutSession: UUIDIdentified {}
extension ExerciseSession: UUIDIdentified {}
extension SetSession: UUIDIdentified {}
