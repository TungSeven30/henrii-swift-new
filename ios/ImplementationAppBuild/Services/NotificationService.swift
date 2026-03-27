import Foundation
import UIKit
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
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["feeding-reminder"])

        let hours = Int(interval / 3600)
        let content = UNMutableNotificationContent()
        content.title = "Feeding Reminder"
        content.body = "It's been \(hours)h since the last feed."
        content.sound = nil
        content.categoryIdentifier = NotificationCategoryID.reminder.rawValue

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(60, interval), repeats: false)
        let request = UNNotificationRequest(identifier: "feeding-reminder", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func scheduleMedicationReminder(title: String, body: String, date: Date, preAlertMinutes: Int = 15) {
        let preAlertDate = Calendar.current.date(byAdding: .minute, value: -preAlertMinutes, to: date) ?? date
        if preAlertDate > Date() {
            let preContent = UNMutableNotificationContent()
            preContent.title = "Medication Coming Up"
            preContent.body = "\(title.replacingOccurrences(of: "Medication Follow-up", with: body)) due in \(preAlertMinutes) minutes."
            preContent.sound = nil
            preContent.categoryIdentifier = NotificationCategoryID.medication.rawValue

            let preComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: preAlertDate)
            let preTrigger = UNCalendarNotificationTrigger(dateMatching: preComponents, repeats: false)
            let preRequest = UNNotificationRequest(identifier: "medication-pre-\(UUID().uuidString)", content: preContent, trigger: preTrigger)
            UNUserNotificationCenter.current().add(preRequest)
        }

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
        content.title = "\u{1F389} \(title)"
        content.body = body
        content.sound = .default

        if let imageURL = createCelebrationImage() {
            if let attachment = try? UNNotificationAttachment(identifier: "celebration-img", url: imageURL, options: nil) {
                content.attachments = [attachment]
            }
        }

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "celebration-\(UUID().uuidString)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    private func createCelebrationImage() -> URL? {
        let size = CGSize(width: 100, height: 100)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            let rect = CGRect(origin: .zero, size: size)
            UIColor.systemYellow.withAlphaComponent(0.2).setFill()
            ctx.fill(rect)
            let text = "\u{2B50}" as NSString
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 48)
            ]
            let textSize = text.size(withAttributes: attrs)
            let textRect = CGRect(
                x: (size.width - textSize.width) / 2,
                y: (size.height - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )
            text.draw(in: textRect, withAttributes: attrs)
        }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("celebration_\(UUID().uuidString).png")
        guard let data = image.pngData() else { return nil }
        try? data.write(to: url)
        return url
    }
}
