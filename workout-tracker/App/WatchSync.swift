import SwiftUI
import SwiftData

// Keeps the Apple Watch app in step with the running workout, the same way
// LiveActivitySync keeps the Live Activity: any change to the workout re-runs
// `body` and sends a new snapshot (WatchSyncService skips unchanged ones).
struct WatchSync: ViewModifier {
    @Query(filter: #Predicate<WorkoutSession> { $0.endedAt == nil })
    private var unfinishedSessions: [WorkoutSession]
    @AppStorage(AppAccent.storageKey) private var accent = AppAccent.defaultValue
    @Environment(LocalizationManager.self) private var lm

    private var runningSession: WorkoutSession? {
        unfinishedSessions
            .filter(\.isRunning)
            .max { $0.createdAt < $1.createdAt }
    }

    func body(content: Content) -> some View {
        let session = runningSession
        let snapshot = session?.watchSnapshot(languageCode: LocalizationManager.resolve(lm.languageCode), accent: accent)
        return content.task(id: snapshot) {
            WatchSyncService.shared.send(snapshot)
            if let snapshot, let session {
                WatchSyncService.shared.announceStart(of: snapshot, createdAt: session.createdAt)
            }
        }
    }
}
