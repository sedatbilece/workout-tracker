import Foundation
import ActivityKit

/// Everything the Live Activity shows for one workout. `LiveActivitySync`
/// recomputes it from SwiftData and calls `LiveActivityService.sync` on change.
struct WorkoutActivitySnapshot: Hashable {
    var sessionUUID: UUID
    var templateName: String
    var startedAt: Date
    var state: WorkoutActivityAttributes.ContentState

    var attributes: WorkoutActivityAttributes {
        WorkoutActivityAttributes(sessionUUID: sessionUUID, templateName: templateName, startedAt: startedAt)
    }
}

extension WorkoutSession {
    /// The next set is the first unfinished one in exercise, then set order;
    /// once every set is done the last exercise stays on screen.
    func liveActivitySnapshot(languageCode: String) -> WorkoutActivitySnapshot? {
        guard let uuid else { return nil }
        let orderedExercises = exercises
            .sorted { $0.orderIndex < $1.orderIndex }
            .map { ($0, $0.sets.sorted { $0.orderIndex < $1.orderIndex }) }
            .filter { !$0.1.isEmpty }

        let current = orderedExercises.lazy
            .compactMap { exercise, sets in
                sets.firstIndex { !$0.isCompleted }.map { (exercise, sets, $0) }
            }
            .first
            ?? orderedExercises.last.map { ($0.0, $0.1, $0.1.count - 1) }

        let totalSets = orderedExercises.reduce(0) { $0 + $1.1.count }
        let nextSet = current.map { $0.1[$0.2] }
        let state = WorkoutActivityAttributes.ContentState(
            languageCode: languageCode,
            exerciseName: current?.0.nameSnapshot ?? "",
            exerciseIcon: current?.0.iconNameSnapshot ?? "dumbbell",
            setNumber: current.map { $0.2 + 1 } ?? 0,
            exerciseSetCount: current?.1.count ?? 0,
            nextKg: nextSet?.kg ?? 0,
            nextReps: nextSet?.reps ?? 0,
            completedSets: completedSetCount,
            totalSets: totalSets,
            allSetsDone: totalSets > 0 && completedSetCount == totalSets
        )
        return WorkoutActivitySnapshot(
            sessionUUID: uuid,
            templateName: templateNameSnapshot,
            startedAt: createdAt,
            state: state
        )
    }
}

// Lock Screen / Dynamic Island card for the running workout. The timer runs
// on its own (`Text(timerInterval:)`), so updates are only sent when the
// workout itself changes; no push notifications are involved.
enum LiveActivityService {
    /// The user's choice in Settings → Lock Screen & Dynamic Island (on by default).
    static let enabledKey = "liveActivityEnabled"

    /// Starts, updates or ends activities so that exactly the given workout
    /// is shown, or none when `snapshot` is nil.
    static func sync(_ snapshot: WorkoutActivitySnapshot?) async {
        var current: Activity<WorkoutActivityAttributes>?
        for activity in Activity<WorkoutActivityAttributes>.activities {
            if current == nil,
               activity.attributes.sessionUUID == snapshot?.sessionUUID,
               activity.activityState == .active || activity.activityState == .stale {
                current = activity
            } else {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }

        guard let snapshot else { return }
        let content = ActivityContent(state: snapshot.state, staleDate: nil)

        if let current {
            if current.content.state != snapshot.state {
                await current.update(content)
            }
            return
        }

        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        do {
            _ = try Activity.request(attributes: snapshot.attributes, content: content, pushType: nil)
        } catch {
            // Only allowed while the app is in the foreground; the next sync retries.
            print("Live Activity unavailable: \(error)")
        }
    }
}
