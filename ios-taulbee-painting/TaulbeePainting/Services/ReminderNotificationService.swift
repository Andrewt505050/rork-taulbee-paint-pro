//
//  ReminderNotificationService.swift
//  TaulbeePainting
//
//  Local notifications for maintenance reminders. Permission is requested
//  only when the homeowner creates their first reminder, and each reminder
//  schedules exactly one friendly notification on its due date — no spam.
//

import Foundation
import UserNotifications

enum ReminderNotificationService {
    /// Asks for notification permission the first time it's needed.
    /// Returns whether notifications are currently allowed.
    @discardableResult
    static func ensurePermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        case .denied:
            return false
        default:
            return true
        }
    }

    /// Schedules a single 9 AM notification on the reminder's due date.
    static func schedule(for reminder: PaintReminder) async {
        guard reminder.completedAt == nil else { return }
        cancel(reminder.notificationId)
        guard reminder.dueDate > .now else { return }

        let content = UNMutableNotificationContent()
        content.title = reminder.title
        if let room = reminder.room {
            content.body = "Time to check \(room.name) — a few minutes now keeps your paint looking great."
        } else if !reminder.surfaceLabel.isEmpty {
            content.body = "Time to check your \(reminder.surfaceLabel.lowercased()) — a quick look now protects your home."
        } else {
            content.body = "Your \(reminder.category.label.lowercased()) is due. A quick check now protects your paint."
        }
        content.sound = .default

        var components = Calendar.current.dateComponents([.year, .month, .day], from: reminder.dueDate)
        components.hour = 9
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: reminder.notificationId, content: content, trigger: trigger)
        try? await UNUserNotificationCenter.current().add(request)
    }

    static func cancel(_ id: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }
}
