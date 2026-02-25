import Foundation
import UserNotifications

nonisolated enum NotificationCategoryID: String, Sendable {
    case medication = "MEDICATION_ALERT"
    case reminder = "CARE_REMINDER"
}

nonisolated enum NotificationActionID: String, Sendable {
    case logged = "ACTION_LOGGED"
    case startTimer = "ACTION_START_TIMER"
    case snooze = "ACTION_SNOOZE"
}

nonisolated final class NotificationService: Sendable {
    static let shared = NotificationService()

    private init() {}

    func requestAuthorization() async {
        _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
    }

    func registerCategories() {
        let logged = UNNotificationAction(identifier: NotificationActionID.logged.rawValue, title: "Logged", options: [])
        let startTimer = UNNotificationAction(identifier: NotificationActionID.startTimer.rawValue, title: "Start Timer", options: [.foreground])
        let snooze = UNNotificationAction(identifier: NotificationActionID.snooze.rawValue, title: "Snooze 30 min", options: [])

        let medication = UNNotificationCategory(
            identifier: NotificationCategoryID.medication.rawValue,
            actions: [logged, snooze],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        let reminder = UNNotificationCategory(
            identifier: NotificationCategoryID.reminder.rawValue,
            actions: [logged, startTimer, snooze],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        UNUserNotificationCenter.current().setNotificationCategories([medication, reminder])
    }

    func scheduleFeedingReminder(after interval: TimeInterval = 3 * 60 * 60) {
        let content = UNMutableNotificationContent()
        content.title = "Feeding Reminder"
        content.body = "It's been 3h since the last feed."
        content.sound = nil
        content.categoryIdentifier = NotificationCategoryID.reminder.rawValue

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(60, interval), repeats: false)
        let request = UNNotificationRequest(identifier: "feeding-reminder", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func scheduleMedicationReminder(title: String, body: String, date: Date) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = NotificationCategoryID.medication.rawValue

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: "medication-\(UUID().uuidString)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func scheduleDailySummaryNotification(at hour: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Daily Summary Ready"
        content.body = "Your daily care summary is ready."
        content.sound = nil

        var components = DateComponents()
        components.hour = hour
        components.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "daily-summary", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func scheduleCelebrationNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "celebration-\(UUID().uuidString)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}
