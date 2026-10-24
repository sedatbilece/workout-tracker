import SwiftUI
import SwiftData

// Keeps the Live Activity in step with the running workout. Reading the
// workout's sets in `body` lets Observation re-run it on every change (set
// completed or undone, set/exercise/workout deleted, Finish/Resume, iCloud
// import), so no call site has to notify the Live Activity itself.
struct LiveActivitySync: ViewModifier {
    @Query(filter: #Predicate<WorkoutSession> { $0.endedAt == nil })
    private var unfinishedSessions: [WorkoutSession]
    @Environment(LocalizationManager.self) private var lm
    @Environment(\.scenePhase) private var scenePhase

    private struct SyncKey: Equatable {
        var snapshot: WorkoutActivitySnapshot?
        var scenePhase: ScenePhase
    }

    /// The most recently started workout that is still running today.
    private var snapshot: WorkoutActivitySnapshot? {
        unfinishedSessions
            .filter(\.isRunning)
            .max { $0.createdAt < $1.createdAt }?
            .liveActivitySnapshot(languageCode: LocalizationManager.resolve(lm.languageCode))
    }

    func body(content: Content) -> some View {
        let snapshot = snapshot
        // Re-syncing when the app becomes active retries a start that failed
        // in the background and ends a workout that ran past midnight.
        return content.task(id: SyncKey(snapshot: snapshot, scenePhase: scenePhase)) {
            await LiveActivityService.sync(snapshot)
        }
    }
}
