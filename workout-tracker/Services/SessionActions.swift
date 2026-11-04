import Foundation
import SwiftData

// What happens when a set is completed, skipped, undone or deleted, or a
// workout is finished. Shared by the iPhone screens and the commands that
// arrive from the Apple Watch (WatchSyncService).
enum SessionActions {
    /// Same key as the Apple Health toggle in Settings → Data.
    static let healthKitEnabledKey = "healthKitEnabled"

    static func complete(_ set: SetSession, context: ModelContext) {
        guard !set.isCompleted else { return }
        set.isSkipped = false
        set.isCompleted = true
        set.completedAt = Date()
        TemplateDefaultUpdater.syncIfNeeded(setSession: set, context: context)
    }

    /// Passes over the set; the template defaults stay as they were.
    static func skip(_ set: SetSession) {
        guard !set.isCompleted else { return }
        set.isSkipped = true
    }

    /// Reopens a set completed or skipped by mistake so it can be done again.
    static func undo(_ set: SetSession, context: ModelContext) {
        if set.isCompleted {
            TemplateDefaultUpdater.revertIfNeeded(setSession: set, context: context)
            set.isCompleted = false
            set.completedAt = nil
        }
        set.isSkipped = false
    }

    static func delete(_ set: SetSession, context: ModelContext) {
        guard let exercise = set.exercise else {
            context.delete(set)
            return
        }
        exercise.sets.removeAll { $0 === set }
        context.delete(set)
        let sorted = exercise.sets.sorted { $0.orderIndex < $1.orderIndex }
        for (i, s) in sorted.enumerated() {
            s.orderIndex = i
        }
    }

    static func finish(_ session: WorkoutSession) {
        // A workout left open on an earlier day ends at its last completed set.
        session.endedAt = session.isRunning ? Date() : session.effectiveEnd
        session.isCompleted = true
        guard UserDefaults.standard.bool(forKey: healthKitEnabledKey) else { return }
        Task {
            await HealthKitService.shared.save(session)
        }
    }
}
