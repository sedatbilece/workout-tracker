import Foundation
import HealthKit
import SwiftData

// Writes finished workouts to Apple Health as strength training. Write-only:
// the app never reads Health data.
final class HealthKitService {
    static let shared = HealthKitService()

    private let store = HKHealthStore()

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    private var canWrite: Bool {
        isAvailable && store.authorizationStatus(for: .workoutType()) == .sharingAuthorized
    }

    /// Returns true when the user allowed writing workouts.
    func requestAuthorization() async -> Bool {
        guard isAvailable else { return false }
        do {
            try await store.requestAuthorization(toShare: [.workoutType()], read: [])
        } catch {
            return false
        }
        return canWrite
    }

    /// Saves the session once; does nothing if it was already written.
    @discardableResult
    func save(_ session: WorkoutSession) async -> Bool {
        guard canWrite, session.healthKitWorkoutUUID == nil else { return false }

        let start = session.createdAt
        let end = max(session.endedAt ?? session.effectiveEnd, start.addingTimeInterval(1))

        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .traditionalStrengthTraining
        configuration.locationType = .indoor

        let builder = HKWorkoutBuilder(healthStore: store, configuration: configuration, device: .local())
        do {
            try await builder.beginCollection(at: start)
            if let uuid = session.uuid {
                try await builder.addMetadata([HKMetadataKeyExternalUUID: uuid.uuidString])
            }
            try await builder.endCollection(at: end)
            guard let workout = try await builder.finishWorkout() else { return false }
            session.healthKitWorkoutUUID = workout.uuid
            return true
        } catch {
            return false
        }
    }

    /// Removes the session's workout from Health, e.g. when the user resumes it.
    func delete(_ session: WorkoutSession) async {
        guard let workoutUUID = session.healthKitWorkoutUUID else { return }
        session.healthKitWorkoutUUID = nil
        guard canWrite else { return }
        _ = try? await store.deleteObjects(of: .workoutType(), predicate: HKQuery.predicateForObject(with: workoutUUID))
    }

    /// Writes past workouts that aren't in Health yet. Workouts still running
    /// today are left out. Returns how many were written.
    func exportPast(context: ModelContext) async -> Int {
        let sessions = (try? context.fetch(FetchDescriptor<WorkoutSession>(sortBy: [SortDescriptor(\.createdAt)]))) ?? []
        var written = 0
        for session in sessions where session.healthKitWorkoutUUID == nil && !session.isRunning {
            guard session.endedAt != nil || session.completedSetCount > 0 else { continue }
            if await save(session) {
                written += 1
            }
        }
        try? context.save()
        return written
    }
}
