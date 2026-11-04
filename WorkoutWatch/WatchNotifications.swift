import Foundation
import UserNotifications

// "Workout started — continue on the watch?" When a workout starts on the
// iPhone, WatchSyncService sends a notice that wakes this app in the
// background; it posts a local notification whose Continue action (or a tap)
// opens the exercise list.
enum WatchNotifications {
    static let categoryID = "WORKOUT_STARTED"
    static let continueActionID = "CONTINUE"

    static func requestAuthorization() async {
        _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
    }

    static func announce(_ started: WatchWorkoutStarted) async {
        let strings = LocalizedStrings(languageCode: started.languageCode)
        let center = UNUserNotificationCenter.current()
        // Action titles are fixed when the category is registered, so
        // register it again in the workout's language.
        center.setNotificationCategories([
            UNNotificationCategory(
                identifier: categoryID,
                actions: [UNNotificationAction(identifier: continueActionID, title: strings["watch_notification_continue"], options: [.foreground])],
                intentIdentifiers: []
            ),
        ])

        let content = UNMutableNotificationContent()
        content.title = strings["watch_notification_title"]
        content.body = strings.format("watch_notification_body", started.templateName)
        content.categoryIdentifier = categoryID
        content.sound = .default
        let request = UNNotificationRequest(identifier: "workout-\(started.sessionUUID.uuidString)", content: content, trigger: nil)
        try? await center.add(request)
    }
}
