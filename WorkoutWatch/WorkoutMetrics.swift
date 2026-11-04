import Foundation
import HealthKit
import Observation

// Live heart rate and active energy while the watch app shows a workout.
// It runs a workout session only to get frequent readings (and to keep the
// app in front on wrist raise); the session is discarded at the end, since
// the iPhone writes the workout to Apple Health.
@Observable
final class WorkoutMetrics: NSObject, HKWorkoutSessionDelegate, HKLiveWorkoutBuilderDelegate {
    private(set) var heartRate: Double?
    private(set) var averageHeartRate: Double?
    private(set) var maxHeartRate: Double?
    private(set) var activeEnergyKcal: Double?

    /// Called with live values every few seconds and once with the final ones.
    @ObservationIgnored var onUpdate: ((WatchMetrics) -> Void)?

    @ObservationIgnored private let healthStore = HKHealthStore()
    @ObservationIgnored private var session: HKWorkoutSession?
    @ObservationIgnored private var builder: HKLiveWorkoutBuilder?
    @ObservationIgnored private var sessionUUID: UUID?
    @ObservationIgnored private var lastSent = Date.distantPast

    private static let sendInterval: TimeInterval = 15
    private static let bpm = HKUnit.count().unitDivided(by: .minute())

    /// Starts measuring for the given workout; does nothing if it already is.
    func start(for uuid: UUID) async {
        guard HKHealthStore.isHealthDataAvailable(), sessionUUID != uuid else { return }
        if session != nil {
            await stop()
        }
        sessionUUID = uuid
        do {
            try await healthStore.requestAuthorization(
                toShare: [HKObjectType.workoutType()],
                read: [HKQuantityType(.heartRate), HKQuantityType(.activeEnergyBurned)]
            )
            let configuration = HKWorkoutConfiguration()
            configuration.activityType = .traditionalStrengthTraining
            configuration.locationType = .indoor
            let session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            let builder = session.associatedWorkoutBuilder()
            builder.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: configuration)
            session.delegate = self
            builder.delegate = self
            self.session = session
            self.builder = builder
            let start = Date()
            session.startActivity(with: start)
            try await builder.beginCollection(at: start)
        } catch {
            print("Workout measurement unavailable: \(error)")
            reset()
        }
    }

    /// Ends the session without saving it and reports the final values.
    func stop() async {
        guard let session, let builder, let uuid = sessionUUID else {
            reset()
            return
        }
        session.end()
        try? await builder.endCollection(at: Date())
        builder.discardWorkout()
        onUpdate?(metrics(for: uuid, isFinal: true))
        reset()
    }

    /// A session left running when the app was terminated is ended right
    /// away; a new one starts when a workout is shown again.
    func recoverActiveSession() {
        healthStore.recoverActiveWorkoutSession { session, _ in
            guard let session else { return }
            session.end()
            session.associatedWorkoutBuilder().discardWorkout()
        }
    }

    private func reset() {
        session = nil
        builder = nil
        sessionUUID = nil
        heartRate = nil
        averageHeartRate = nil
        maxHeartRate = nil
        activeEnergyKcal = nil
        lastSent = .distantPast
    }

    private func metrics(for uuid: UUID, isFinal: Bool) -> WatchMetrics {
        WatchMetrics(
            sessionUUID: uuid,
            heartRate: heartRate,
            averageHeartRate: averageHeartRate,
            maxHeartRate: maxHeartRate,
            activeEnergyKcal: activeEnergyKcal,
            isFinal: isFinal
        )
    }

    private func update(from builder: HKLiveWorkoutBuilder) {
        if let stats = builder.statistics(for: HKQuantityType(.heartRate)) {
            heartRate = stats.mostRecentQuantity()?.doubleValue(for: Self.bpm)
            averageHeartRate = stats.averageQuantity()?.doubleValue(for: Self.bpm)
            maxHeartRate = stats.maximumQuantity()?.doubleValue(for: Self.bpm)
        }
        if let stats = builder.statistics(for: HKQuantityType(.activeEnergyBurned)) {
            activeEnergyKcal = stats.sumQuantity()?.doubleValue(for: .kilocalorie())
        }
        guard let uuid = sessionUUID, Date().timeIntervalSince(lastSent) >= Self.sendInterval else { return }
        lastSent = Date()
        onUpdate?(metrics(for: uuid, isFinal: false))
    }

    // MARK: - Delegates

    nonisolated func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        Task { @MainActor in
            guard workoutBuilder === self.builder else { return }
            self.update(from: workoutBuilder)
        }
    }

    nonisolated func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}

    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {}

    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("Workout session failed: \(error)")
    }
}
