import Foundation
import SwiftData

// Restoring the same backup on two devices before they synced leaves two
// copies of a template or workout with the same `uuid`. Keep one and delete
// the rest. Every device must pick the same survivor, so the choice depends
// only on synced data: the copy without an `importID` (the original) wins,
// otherwise the smallest `importID`.
struct DuplicateCleaner {
    static func run(context: ModelContext) {
        removeDuplicates(WorkoutTemplate.self, context: context)
        removeDuplicates(WorkoutSession.self, context: context)

        if context.hasChanges {
            try? context.save()
        }
    }

    private static func removeDuplicates<T: PersistentModel & UUIDIdentified & ImportStamped>(_ type: T.Type, context: ModelContext) {
        let models = (try? context.fetch(FetchDescriptor<T>())) ?? []
        let groups = Dictionary(grouping: models.filter { $0.uuid != nil }, by: { $0.uuid! })

        for copies in groups.values where copies.count > 1 {
            let sorted = copies.sorted { ($0.importID?.uuidString ?? "") < ($1.importID?.uuidString ?? "") }
            for duplicate in sorted.dropFirst() {
                context.delete(duplicate)
            }
        }
    }
}

protocol ImportStamped: AnyObject {
    var importID: UUID? { get }
}

extension WorkoutTemplate: ImportStamped {}
extension WorkoutSession: ImportStamped {}
