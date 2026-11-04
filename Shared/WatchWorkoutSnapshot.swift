import Foundation

/// The running workout as the Apple Watch sees it. The iPhone builds it from
/// SwiftData (`WorkoutSession.watchSnapshot`) and sends it as the
/// WatchConnectivity application context; the watch keeps no store of its own.
nonisolated struct WatchWorkoutSnapshot: Codable, Hashable {
    var sessionUUID: UUID
    var templateName: String
    /// Start of the pause-free timer (`WorkoutSession.timerStart`).
    var timerStart: Date
    /// Resolved app language ("tr", "en", …).
    var languageCode: String
    var accent: AppAccent
    /// In workout order; exercises without sets are left out.
    var exercises: [Exercise]

    nonisolated struct Exercise: Codable, Hashable, Identifiable {
        var uuid: UUID
        var name: String
        var icon: String
        var sets: [Set]

        var id: UUID { uuid }

        /// The set the watch opens: the first one neither completed nor skipped.
        var firstOpenSet: Set? { sets.first { $0.status == .pending } }
        var isDone: Bool { firstOpenSet == nil }
        var doneCount: Int { sets.filter { $0.status != .pending }.count }
    }

    nonisolated struct Set: Codable, Hashable, Identifiable {
        var uuid: UUID
        var kg: Double
        var reps: Int
        var status: WorkoutSetStatus

        var id: UUID { uuid }
    }

    var setStatuses: [WorkoutSetStatus] { exercises.flatMap(\.sets).map(\.status) }
    var completedSetCount: Int { setStatuses.filter { $0 == .completed }.count }
    var totalSetCount: Int { setStatuses.count }

    func exercise(_ uuid: UUID) -> Exercise? {
        exercises.first { $0.uuid == uuid }
    }

    /// What the iPhone will send back once it has applied `command`, so the
    /// watch can show the result right away. Nil once the workout is finished.
    func applying(_ command: WatchCommand) -> WatchWorkoutSnapshot? {
        var copy = self
        switch command {
        case let .complete(setUUID, kg, reps):
            copy.updateSet(setUUID) { set in
                guard set.status != .completed else { return }
                set.kg = kg
                set.reps = reps
                set.status = .completed
            }
        case let .skip(setUUID):
            copy.updateSet(setUUID) { set in
                if set.status == .pending { set.status = .skipped }
            }
        case let .undo(setUUID):
            copy.updateSet(setUUID) { $0.status = .pending }
        case let .delete(setUUID):
            for i in copy.exercises.indices {
                copy.exercises[i].sets.removeAll { $0.uuid == setUUID }
            }
            copy.exercises.removeAll { $0.sets.isEmpty }
        case let .finish(sessionUUID):
            if sessionUUID == self.sessionUUID { return nil }
        case .metrics, .refresh:
            break
        }
        return copy
    }

    private mutating func updateSet(_ uuid: UUID, _ change: (inout Set) -> Void) {
        for i in exercises.indices {
            if let j = exercises[i].sets.firstIndex(where: { $0.uuid == uuid }) {
                change(&exercises[i].sets[j])
                return
            }
        }
    }
}

/// What the watch asks the iPhone to do. Applying the same command twice has
/// no further effect, so a message retried through `transferUserInfo` is safe.
nonisolated enum WatchCommand: Codable, Hashable {
    case complete(setUUID: UUID, kg: Double, reps: Int)
    case skip(setUUID: UUID)
    case undo(setUUID: UUID)
    case delete(setUUID: UUID)
    case finish(sessionUUID: UUID)
    case metrics(WatchMetrics)
    /// Asks for the current snapshot (sent when the watch app opens).
    case refresh
}

/// Heart rate and energy measured by the watch while its app is open.
nonisolated struct WatchMetrics: Codable, Hashable {
    var sessionUUID: UUID
    var heartRate: Double?
    var averageHeartRate: Double?
    var maxHeartRate: Double?
    var activeEnergyKcal: Double?
    /// Sent once the measurement stops; only then does the iPhone store it.
    var isFinal: Bool
}

/// Sent when a workout starts on the iPhone, so the watch can offer to continue there.
nonisolated struct WatchWorkoutStarted: Codable, Hashable {
    var sessionUUID: UUID
    var templateName: String
    var languageCode: String
}

/// Dictionary keys and coding for the WatchConnectivity payloads. Values
/// travel as JSON `Data`, since WatchConnectivity only takes property-list types.
nonisolated enum WatchPayload {
    static let snapshotKey = "snapshot"
    static let commandKey = "command"
    static let workoutStartedKey = "workoutStarted"
    /// Makes every application context differ, so an unchanged snapshot is
    /// still delivered (e.g. after the watch app was reinstalled).
    static let sentAtKey = "sentAt"

    static func encode<T: Encodable>(_ value: T) -> Data? {
        try? JSONEncoder().encode(value)
    }

    static func decode<T: Decodable>(_ type: T.Type, from payload: [String: Any], key: String) -> T? {
        guard let data = payload[key] as? Data else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    /// No snapshot key means no workout is running.
    static func context(for snapshot: WatchWorkoutSnapshot?) -> [String: Any] {
        var payload: [String: Any] = [sentAtKey: Date()]
        if let snapshot, let data = encode(snapshot) {
            payload[snapshotKey] = data
        }
        return payload
    }
}
