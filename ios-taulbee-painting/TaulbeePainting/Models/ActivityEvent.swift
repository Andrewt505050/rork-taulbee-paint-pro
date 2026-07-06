//
//  ActivityEvent.swift
//  TaulbeePainting
//
//  A recorded moment in the homeowner's journey — room created, color saved,
//  reminder completed, estimate requested, and so on. Scans, visualizations,
//  and expert questions are derived from their own models, so only events
//  without a dedicated model are logged here.
//

import Foundation
import SwiftData

enum ActivityEventType: String, CaseIterable, Codable {
    case roomCreated
    case colorSaved
    case reminderCreated
    case reminderCompleted
    case estimateRequested
    case photoAdded
}

@Model
final class ActivityEvent {
    var id: UUID
    var createdAt: Date
    var typeRaw: String
    var title: String
    var detail: String

    init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        type: ActivityEventType,
        title: String,
        detail: String = ""
    ) {
        self.id = id
        self.createdAt = createdAt
        self.typeRaw = type.rawValue
        self.title = title
        self.detail = detail
    }

    var type: ActivityEventType {
        ActivityEventType(rawValue: typeRaw) ?? .photoAdded
    }

    /// Convenience logger used across the app.
    static func log(_ type: ActivityEventType, title: String, detail: String = "", in context: ModelContext) {
        context.insert(ActivityEvent(type: type, title: title, detail: detail))
    }
}
