import Foundation
import UserNotifications

enum NotificationService {
    static let reminderId = "clarity_daily_reminder"

    static func requestAuthorizationIfNeeded(completion: ((Bool) -> Void)? = nil) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async {
                completion?(granted)
            }
        }
    }

    static func scheduleDailyReminder(hour: Int, minute: Int, enabled: Bool) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [reminderId])
        guard enabled else { return }

        requestAuthorizationIfNeeded { granted in
            guard granted else { return }
            var components = DateComponents()
            components.hour = hour
            components.minute = minute

            let content = UNMutableNotificationContent()
            content.title = "Time to study"
            content.body = "Hit your daily flashcard goal and keep your streak alive."
            content.sound = .default

            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let request = UNNotificationRequest(identifier: reminderId, content: content, trigger: trigger)
            center.add(request)
        }
    }
}
