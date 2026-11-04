import Foundation
import SwiftData
import UIKit
import WatchConnectivity

extension WorkoutSession {
    func watchSnapshot(languageCode: String, accent: AppAccent) -> WatchWorkoutSnapshot? {
        guard let uuid else { return nil }
        let exercises = exercises
            .sorted { $0.orderIndex < $1.orderIndex }
            .compactMap { exercise -> WatchWorkoutSnapshot.Exercise? in
                guard let exerciseUUID = exercise.uuid else { return nil }
                let sets = exercise.sets
                    .sorted { $0.orderIndex < $1.orderIndex }
                    .compactMap { set -> WatchWorkoutSnapshot.Set? in
                        guard let setUUID = set.uuid else { return nil }
                        let status: WorkoutSetStatus = set.isCompleted ? .completed : set.isSkipped ? .skipped : .pending
                        return WatchWorkoutSnapshot.Set(uuid: setUUID, kg: set.kg, reps: set.reps, status: status)
                    }
                guard !sets.isEmpty else { return nil }
                return WatchWorkoutSnapshot.Exercise(
                    uuid: exerciseUUID,
                    name: exercise.nameSnapshot,
                    icon: exercise.iconNameSnapshot,
                    sets: sets
                )
            }
        return WatchWorkoutSnapshot(
            sessionUUID: uuid,
            templateName: templateNameSnapshot,
            timerStart: timerStart,
            languageCode: languageCode,
            accent: accent,
            exercises: exercises
        )
    }
}

// The iPhone side of the Apple Watch app. The watch holds no data: it shows
// the snapshot sent here (by `WatchSync` on every change, and in reply to
// each command) and sends back what the user did. Commands may wake the app
// in the background, where no view is on screen, so this applies them
// through SessionActions, saves right away and updates the Live Activity itself.
@Observable
final class WatchSyncService: NSObject, WCSessionDelegate {
    static let shared = WatchSyncService()

    /// Last values measured by the watch, for the running workout's screen.
    private(set) var liveMetrics: WatchMetrics?

    @ObservationIgnored private var container: ModelContainer?
    @ObservationIgnored private var lastSentSnapshot: WatchWorkoutSnapshot??
    /// Workout the watch was last told about, so it is announced only once.
    private static let announcedSessionKey = "watchAnnouncedSessionUUID"

    func activate(container: ModelContainer) {
        self.container = container
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    // MARK: - Sending

    /// Sends the running workout (or none) unless the watch already has it.
    func send(_ snapshot: WatchWorkoutSnapshot?) {
        guard lastSentSnapshot != .some(snapshot) else { return }
        guard canReachWatchApp else { return }
        do {
            try WCSession.default.updateApplicationContext(WatchPayload.context(for: snapshot))
            lastSentSnapshot = .some(snapshot)
        } catch {
            print("Watch context not sent: \(error)")
        }
    }

    /// Lets the watch offer to continue a workout that just started here.
    func announceStart(of snapshot: WatchWorkoutSnapshot, createdAt: Date) {
        let defaults = UserDefaults.standard
        guard Date().timeIntervalSince(createdAt) < 120,
              defaults.string(forKey: Self.announcedSessionKey) != snapshot.sessionUUID.uuidString,
              canReachWatchApp else { return }
        let notice = WatchWorkoutStarted(
            sessionUUID: snapshot.sessionUUID,
            templateName: snapshot.templateName,
            languageCode: snapshot.languageCode
        )
        guard let data = WatchPayload.encode(notice) else { return }
        WCSession.default.transferUserInfo([WatchPayload.workoutStartedKey: data])
        defaults.set(snapshot.sessionUUID.uuidString, forKey: Self.announcedSessionKey)
    }

    private var canReachWatchApp: Bool {
        let session = WCSession.default
        return WCSession.isSupported()
            && session.activationState == .activated
            && session.isPaired
            && session.isWatchAppInstalled
    }

    // MARK: - Commands

    private func handle(_ command: WatchCommand) -> WatchWorkoutSnapshot? {
        guard let context = container?.mainContext else { return nil }
        switch command {
        case let .complete(setUUID, kg, reps):
            if let set = fetchSet(setUUID, in: context), !set.isCompleted {
                set.kg = kg
                set.reps = reps
                SessionActions.complete(set, context: context)
            }
        case let .skip(setUUID):
            if let set = fetchSet(setUUID, in: context) {
                SessionActions.skip(set)
            }
        case let .undo(setUUID):
            if let set = fetchSet(setUUID, in: context) {
                SessionActions.undo(set, context: context)
            }
        case let .delete(setUUID):
            if let set = fetchSet(setUUID, in: context) {
                SessionActions.delete(set, context: context)
            }
        case let .finish(sessionUUID):
            if let session = fetchSession(sessionUUID, in: context), session.endedAt == nil {
                SessionActions.finish(session)
            }
        case let .metrics(metrics):
            store(metrics, in: context)
            // Live readings only update the screen; nothing to save or resend.
            guard metrics.isFinal else { return nil }
        case .refresh:
            break
        }
        try? context.save()

        let session = Self.runningSession(in: context)
        let snapshot = session?.watchSnapshot(languageCode: Self.languageCode, accent: Self.accent)
        lastSentSnapshot = nil
        send(snapshot)
        // In the foreground LiveActivitySync notices the change by itself.
        if UIApplication.shared.applicationState != .active {
            let enabled = UserDefaults.standard.object(forKey: LiveActivityService.enabledKey) as? Bool ?? true
            let activity = enabled ? session?.liveActivitySnapshot(languageCode: Self.languageCode, accent: Self.accent) : nil
            Task { await LiveActivityService.sync(activity) }
        }
        return snapshot
    }

    private func store(_ metrics: WatchMetrics, in context: ModelContext) {
        if metrics.isFinal {
            liveMetrics = nil
            guard let session = fetchSession(metrics.sessionUUID, in: context) else { return }
            if let value = metrics.averageHeartRate { session.averageHeartRate = value }
            if let value = metrics.maxHeartRate { session.maxHeartRate = value }
            if let value = metrics.activeEnergyKcal { session.activeEnergyKcal = value }
        } else {
            liveMetrics = metrics
        }
    }

    private func fetchSet(_ uuid: UUID, in context: ModelContext) -> SetSession? {
        var descriptor = FetchDescriptor<SetSession>(predicate: #Predicate { $0.uuid == uuid })
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }

    private func fetchSession(_ uuid: UUID, in context: ModelContext) -> WorkoutSession? {
        var descriptor = FetchDescriptor<WorkoutSession>(predicate: #Predicate { $0.uuid == uuid })
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }

    /// Same choice as LiveActivitySync: the newest workout still running today.
    static func runningSession(in context: ModelContext) -> WorkoutSession? {
        let descriptor = FetchDescriptor<WorkoutSession>(predicate: #Predicate { $0.endedAt == nil })
        return ((try? context.fetch(descriptor)) ?? [])
            .filter(\.isRunning)
            .max { $0.createdAt < $1.createdAt }
    }

    private static var languageCode: String {
        LocalizationManager.resolve(UserDefaults.standard.string(forKey: "appLanguage") ?? "system")
    }

    private static var accent: AppAccent {
        UserDefaults.standard.string(forKey: AppAccent.storageKey).flatMap(AppAccent.init(rawValue:)) ?? .defaultValue
    }

    /// Brings a watch that missed changes (or was just installed) up to date.
    /// Also announces a workout that started before the session was ready.
    private func resendCurrentSnapshot() {
        guard let context = container?.mainContext else { return }
        lastSentSnapshot = nil
        let session = Self.runningSession(in: context)
        let snapshot = session?.watchSnapshot(languageCode: Self.languageCode, accent: Self.accent)
        send(snapshot)
        if let session, let snapshot {
            announceStart(of: snapshot, createdAt: session.createdAt)
        }
    }

    private func reply(_ snapshot: WatchWorkoutSnapshot?) -> [String: Any] {
        WatchPayload.context(for: snapshot)
    }

    // MARK: - WCSessionDelegate

    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            self.resendCurrentSnapshot()
        }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        // The user switched to another watch; talk to that one from now on.
        WCSession.default.activate()
    }

    /// Fires when the watch app is installed or removed.
    nonisolated func sessionWatchStateDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.resendCurrentSnapshot()
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        let command = WatchPayload.decode(WatchCommand.self, from: message, key: WatchPayload.commandKey)
        Task { @MainActor in
            guard let command else {
                replyHandler([:])
                return
            }
            replyHandler(self.reply(self.handle(command)))
        }
    }

    /// Live heart rate, sent without waiting for a reply.
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        guard let command = WatchPayload.decode(WatchCommand.self, from: message, key: WatchPayload.commandKey) else { return }
        Task { @MainActor in
            _ = self.handle(command)
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        guard let command = WatchPayload.decode(WatchCommand.self, from: userInfo, key: WatchPayload.commandKey) else { return }
        Task { @MainActor in
            _ = self.handle(command)
        }
    }
}
