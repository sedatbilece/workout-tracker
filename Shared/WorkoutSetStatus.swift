import Foundation

/// Where a set stands in a running workout; shared by the Live Activity and
/// the Apple Watch snapshot.
nonisolated enum WorkoutSetStatus: Int, Codable, Hashable {
    case pending, completed, skipped
}
