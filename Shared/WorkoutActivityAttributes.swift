#if !os(watchOS)
import Foundation
import ActivityKit

// Live Activity for the running workout, shared by the app (which starts and
// updates it) and the WorkoutWidgets extension (which draws it).
nonisolated struct WorkoutActivityAttributes: ActivityAttributes {
    nonisolated struct ContentState: Codable, Hashable {
        /// Resolved app language ("tr", "en", …), so the extension shows the
        /// language picked in Profile rather than the system one.
        var languageCode: String
        /// Theme color from Settings → Appearance.
        var accent: AppAccent
        var exerciseName: String
        var exerciseIcon: String
        /// 1-based position of the next set within its exercise.
        var setNumber: Int
        var exerciseSetCount: Int
        var nextKg: Double
        var nextReps: Int
        var completedSets: Int
        var skippedSets: Int
        var totalSets: Int
        /// Every set is either completed or skipped.
        var allSetsDone: Bool
        /// One entry per set in workout order, for the segmented progress bar.
        var setStatuses: [SetStatus]
    }

    typealias SetStatus = WorkoutSetStatus

    var sessionUUID: UUID
    var templateName: String
    var startedAt: Date
}

// Deep link opened by tapping the Live Activity: workouttracker://session/<uuid>
extension WorkoutActivityAttributes {
    static let urlScheme = "workouttracker"

    static func url(for sessionUUID: UUID) -> URL {
        URL(string: "\(urlScheme)://session/\(sessionUUID.uuidString)")!
    }

    static func sessionUUID(from url: URL) -> UUID? {
        guard url.scheme == urlScheme, url.host() == "session" else { return nil }
        return UUID(uuidString: url.lastPathComponent)
    }
}
#endif
