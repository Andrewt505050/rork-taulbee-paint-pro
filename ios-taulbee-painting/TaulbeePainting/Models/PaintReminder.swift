//
//  PaintReminder.swift
//  TaulbeePainting
//
//  A maintenance reminder that helps homeowners inspect, touch up, and care
//  for painted surfaces. Optionally linked to a Paint Vault room and backed
//  by a local notification.
//

import Foundation
import SwiftData

@Model
final class PaintReminder {
    var id: UUID
    var createdAt: Date
    var title: String
    var detail: String
    var categoryRaw: String
    /// Optional free-text surface label, e.g. "Exterior" or "Front Door".
    var surfaceLabel: String
    var dueDate: Date
    var recurrenceRaw: String
    /// Interval in days, used only when recurrence is `.custom`.
    var customIntervalDays: Int
    var priorityRaw: String
    var notes: String
    var completedAt: Date?
    /// Identifier of the scheduled local notification.
    var notificationId: String
    var room: PaintRoom?

    init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        title: String,
        detail: String = "",
        category: ReminderCategory = .custom,
        surfaceLabel: String = "",
        dueDate: Date,
        recurrence: ReminderRecurrence = .none,
        customIntervalDays: Int = 180,
        priority: ReminderPriority = .normal,
        notes: String = "",
        completedAt: Date? = nil,
        room: PaintRoom? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.title = title
        self.detail = detail
        self.categoryRaw = category.rawValue
        self.surfaceLabel = surfaceLabel
        self.dueDate = dueDate
        self.recurrenceRaw = recurrence.rawValue
        self.customIntervalDays = customIntervalDays
        self.priorityRaw = priority.rawValue
        self.notes = notes
        self.completedAt = completedAt
        self.notificationId = UUID().uuidString
        self.room = room
    }

    var category: ReminderCategory {
        get { ReminderCategory(rawValue: categoryRaw) ?? .custom }
        set { categoryRaw = newValue.rawValue }
    }

    var recurrence: ReminderRecurrence {
        get { ReminderRecurrence(rawValue: recurrenceRaw) ?? .none }
        set { recurrenceRaw = newValue.rawValue }
    }

    var priority: ReminderPriority {
        get { ReminderPriority(rawValue: priorityRaw) ?? .normal }
        set { priorityRaw = newValue.rawValue }
    }

    var status: ReminderStatus {
        if completedAt != nil { return .completed }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let due = calendar.startOfDay(for: dueDate)
        if due < today { return .overdue }
        let days = calendar.dateComponents([.day], from: today, to: due).day ?? 0
        return days <= 7 ? .dueSoon : .upcoming
    }

    /// Friendly due text, e.g. "Due today", "Due in 3 days", "Due May 12".
    var dueText: String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let due = calendar.startOfDay(for: dueDate)
        let days = calendar.dateComponents([.day], from: today, to: due).day ?? 0
        if days == 0 { return "Due today" }
        if days == 1 { return "Due tomorrow" }
        if days == -1 { return "Due yesterday" }
        if days < 0 { return "Overdue by \(-days) days" }
        if days <= 14 { return "Due in \(days) days" }
        return "Due \(dueDate.formatted(.dateTime.month(.abbreviated).day()))"
    }

    /// Short context line combining room and surface where available.
    var whereText: String {
        var parts: [String] = []
        if let room { parts.append(room.name) }
        if !surfaceLabel.isEmpty { parts.append(surfaceLabel) }
        return parts.joined(separator: " · ")
    }

    /// The due date of the next occurrence, or nil when it doesn't repeat.
    var nextOccurrenceDate: Date? {
        recurrence.nextDate(after: max(dueDate, .now), customDays: customIntervalDays)
    }

    /// Marks the reminder complete, cancels its notification, logs the moment,
    /// and — when recurring — schedules the next occurrence automatically.
    func complete(in context: ModelContext) {
        guard completedAt == nil else { return }
        completedAt = .now
        ReminderNotificationService.cancel(notificationId)
        ActivityEvent.log(.reminderCompleted, title: title, detail: whereText, in: context)

        if let next = nextOccurrenceDate {
            let nextReminder = PaintReminder(
                title: title,
                detail: detail,
                category: category,
                surfaceLabel: surfaceLabel,
                dueDate: next,
                recurrence: recurrence,
                customIntervalDays: customIntervalDays,
                priority: priority,
                notes: notes,
                room: room
            )
            context.insert(nextReminder)
            Task { await ReminderNotificationService.schedule(for: nextReminder) }
        }
        try? context.save()
    }
}
