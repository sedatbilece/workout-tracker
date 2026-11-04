import SwiftUI
import UserNotifications
import WatchKit

@main
struct WorkoutWatchApp: App {
    @WKApplicationDelegateAdaptor(WatchAppDelegate.self) private var delegate

    var body: some Scene {
        WindowGroup {
            WatchRootView()
                .environment(WatchStore.shared)
        }
    }
}

final class WatchAppDelegate: NSObject, WKApplicationDelegate, UNUserNotificationCenterDelegate {
    func applicationDidFinishLaunching() {
        WatchStore.shared.activate()
        UNUserNotificationCenter.current().delegate = self
        Task { await WatchNotifications.requestAuthorization() }
    }

    func handleActiveWorkoutRecovery() {
        WatchStore.shared.metrics.recoverActiveSession()
    }

    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        for task in backgroundTasks {
            if let task = task as? WKWatchConnectivityRefreshBackgroundTask {
                WatchStore.shared.handle(task)
            } else {
                task.setTaskCompletedWithSnapshot(false)
            }
        }
    }

    // MARK: - UNUserNotificationCenterDelegate

    /// The app is already showing the workout, so no banner on top of it.
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        []
    }

    /// Continue (or a tap on the notification) opens the exercise list.
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        await MainActor.run {
            WatchStore.shared.path = []
        }
    }
}
