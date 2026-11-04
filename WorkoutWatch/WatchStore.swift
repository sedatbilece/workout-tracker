import Foundation
import Observation
import WatchConnectivity
import WatchKit

// The watch side of WatchConnectivity. The iPhone owns the workout: this
// keeps the last snapshot it sent, applies the user's taps to it right away
// (so the screen doesn't wait for the round trip) and sends them as
// commands; the snapshot the iPhone sends back replaces the local guess.
@Observable
final class WatchStore: NSObject, WCSessionDelegate {
    static let shared = WatchStore()

    private(set) var snapshot: WatchWorkoutSnapshot?
    /// False until the iPhone's state is known, to show a spinner instead of "no workout".
    private(set) var hasLoaded = false
    /// Shown after the workout is finished from the watch, until dismissed.
    private(set) var finishedSummary: FinishedSummary?
    private(set) var strings: LocalizedStrings
    /// Exercise screens pushed on the list; emptied when a workout starts or ends.
    var path: [UUID] = []
    let metrics = WorkoutMetrics()

    @ObservationIgnored private var commandsInFlight = 0
    /// Notifications still being posted; the app must not be suspended before they are.
    @ObservationIgnored private var announcementsInFlight = 0
    @ObservationIgnored private var refreshTasks: [WKRefreshBackgroundTask] = []

    struct FinishedSummary: Hashable {
        var templateName: String
        var duration: TimeInterval
        var completedSets: Int
        var totalSets: Int
        var averageHeartRate: Double?
        var activeEnergyKcal: Double?
    }

    /// Language of the last snapshot, so the idle screen and notifications match the app.
    private static let languageKey = "watchLanguageCode"

    override init() {
        strings = LocalizedStrings(languageCode: UserDefaults.standard.string(forKey: Self.languageKey) ?? "tr")
        super.init()
        metrics.onUpdate = { [weak self] metrics in
            self?.sendMetrics(metrics)
        }
    }

    func activate() {
        guard WCSession.isSupported() else {
            hasLoaded = true
            return
        }
        WCSession.default.delegate = self
        WCSession.default.activate()
        // Activation can stall while the iPhone is unreachable; show the
        // last known state (or "no workout") instead of spinning forever.
        Task {
            try? await Task.sleep(for: .seconds(5))
            self.hasLoaded = true
        }
    }

    // MARK: - Commands

    func send(_ command: WatchCommand) {
        if let snapshot {
            if case .finish = command {
                finishedSummary = summary(of: snapshot)
            }
            apply(snapshot.applying(command))
        }
        deliver(command, expectsReply: true)
    }

    func finish() {
        guard let snapshot else { return }
        send(.finish(sessionUUID: snapshot.sessionUUID))
    }

    func dismissSummary() {
        finishedSummary = nil
    }

    private func sendMetrics(_ metrics: WatchMetrics) {
        // Final values must arrive even if the iPhone is out of reach now;
        // live ones are only worth sending while it is reachable.
        deliver(.metrics(metrics), expectsReply: false, queueIfUnreachable: metrics.isFinal)
    }

    /// Sends right away while the iPhone is reachable; otherwise (or if that
    /// fails) queues the command, which WatchConnectivity delivers later.
    private func deliver(_ command: WatchCommand, expectsReply: Bool, queueIfUnreachable: Bool = true) {
        guard let data = WatchPayload.encode(command) else { return }
        let message: [String: Any] = [WatchPayload.commandKey: data]
        let session = WCSession.default
        guard session.activationState == .activated else { return }
        // A queued refresh would be stale by the time it arrives.
        let queues: Bool
        if case .refresh = command { queues = false } else { queues = queueIfUnreachable }
        guard session.isReachable else {
            if queues { session.transferUserInfo(message) }
            return
        }
        guard expectsReply else {
            session.sendMessage(message, replyHandler: nil) { _ in
                if queues { session.transferUserInfo(message) }
            }
            return
        }
        commandsInFlight += 1
        session.sendMessage(message, replyHandler: { reply in
            Task { @MainActor in
                self.commandsInFlight -= 1
                // Each reply holds the state after its command; only the
                // last one is shown, so quick taps don't flicker back.
                if self.commandsInFlight == 0 {
                    self.receive(reply)
                }
            }
        }, errorHandler: { _ in
            Task { @MainActor in
                self.commandsInFlight -= 1
                // Commands are idempotent, so queueing a retry is safe.
                if queues { session.transferUserInfo(message) }
            }
        })
    }

    // MARK: - Receiving

    private func receive(_ payload: [String: Any]) {
        guard payload[WatchPayload.sentAtKey] != nil else { return }
        apply(WatchPayload.decode(WatchWorkoutSnapshot.self, from: payload, key: WatchPayload.snapshotKey))
    }

    private func apply(_ new: WatchWorkoutSnapshot?) {
        hasLoaded = true
        let old = snapshot
        if old?.sessionUUID != new?.sessionUUID {
            path = []
            if new != nil {
                finishedSummary = nil
            }
            if old != nil {
                Task { await metrics.stop() }
            }
        }
        if let new, new.languageCode != strings.languageCode {
            UserDefaults.standard.set(new.languageCode, forKey: Self.languageKey)
            strings = LocalizedStrings(languageCode: new.languageCode)
        }
        snapshot = new
    }

    private func summary(of snapshot: WatchWorkoutSnapshot) -> FinishedSummary {
        FinishedSummary(
            templateName: snapshot.templateName,
            duration: max(0, Date().timeIntervalSince(snapshot.timerStart)),
            completedSets: snapshot.completedSetCount,
            totalSets: snapshot.totalSetCount,
            averageHeartRate: metrics.averageHeartRate,
            activeEnergyKcal: metrics.activeEnergyKcal
        )
    }

    // MARK: - Background refresh

    /// Kept until WatchConnectivity has handed over everything it woke the app for.
    func handle(_ task: WKWatchConnectivityRefreshBackgroundTask) {
        refreshTasks.append(task)
        // The content arrives just after the task, so give it a moment
        // before deciding nothing is left; never hold a task for long.
        Task {
            try? await Task.sleep(for: .seconds(2))
            self.completeRefreshTasksIfIdle()
            try? await Task.sleep(for: .seconds(13))
            self.completeRefreshTasks()
        }
    }

    private func completeRefreshTasksIfIdle() {
        let session = WCSession.default
        guard session.activationState == .activated, !session.hasContentPending, announcementsInFlight == 0 else { return }
        completeRefreshTasks()
    }

    private func completeRefreshTasks() {
        refreshTasks.forEach { $0.setTaskCompletedWithSnapshot(false) }
        refreshTasks.removeAll()
    }

    // MARK: - WCSessionDelegate

    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        let context = session.receivedApplicationContext
        Task { @MainActor in
            self.receive(context)
            self.hasLoaded = true
            // Ask for the current state in case the stored context is old.
            if session.isReachable {
                self.deliver(.refresh, expectsReply: true)
            }
        }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        guard session.isReachable else { return }
        Task { @MainActor in
            self.deliver(.refresh, expectsReply: true)
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        Task { @MainActor in
            // A reply that is on its way supersedes this context.
            if self.commandsInFlight == 0 {
                self.receive(applicationContext)
            }
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        let started = WatchPayload.decode(WatchWorkoutStarted.self, from: userInfo, key: WatchPayload.workoutStartedKey)
        Task { @MainActor in
            if let started {
                self.announcementsInFlight += 1
                await WatchNotifications.announce(started)
                self.announcementsInFlight -= 1
            }
            self.completeRefreshTasksIfIdle()
        }
    }
}
