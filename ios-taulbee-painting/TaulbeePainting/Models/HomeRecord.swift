//
//  HomeRecord.swift
//  TaulbeePainting
//
//  A single entry in the Vault: anything useful about a home — a receipt,
//  contract, appliance warranty, paint color, manual, and more. Persisted
//  on-device for privacy.
//

import Foundation
import SwiftData

@Model
final class HomeRecord {
    var id: UUID
    var createdAt: Date
    var updatedAt: Date
    var title: String
    var categoryRaw: String
    var room: String
    var notes: String
    var purchaseDate: Date?
    var expiryDate: Date?
    /// Optional paint-color metadata when this record represents a color.
    var colorHex: String
    var colorCode: String
    var colorBrand: String

    @Relationship(deleteRule: .cascade, inverse: \RecordAttachment.record)
    var attachments: [RecordAttachment]

    init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        updatedAt: Date = .now,
        title: String,
        category: RecordCategory,
        room: String = "",
        notes: String = "",
        purchaseDate: Date? = nil,
        expiryDate: Date? = nil,
        colorHex: String = "",
        colorCode: String = "",
        colorBrand: String = "",
        attachments: [RecordAttachment] = []
    ) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.title = title
        self.categoryRaw = category.rawValue
        self.room = room
        self.notes = notes
        self.purchaseDate = purchaseDate
        self.expiryDate = expiryDate
        self.colorHex = colorHex
        self.colorCode = colorCode
        self.colorBrand = colorBrand
        self.attachments = attachments
    }

    var category: RecordCategory {
        get { RecordCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }

    /// Attachments ordered oldest-first for stable viewer paging.
    var orderedAttachments: [RecordAttachment] {
        attachments.sorted { $0.createdAt < $1.createdAt }
    }

    /// First image attachment, used for the card thumbnail.
    var thumbnailData: Data? {
        orderedAttachments.first(where: { $0.kind == .image })?.data
    }

    /// Number of days until expiry (nil if no expiry date).
    var daysUntilExpiry: Int? {
        guard let expiryDate else { return nil }
        let start = Calendar.current.startOfDay(for: .now)
        let end = Calendar.current.startOfDay(for: expiryDate)
        return Calendar.current.dateComponents([.day], from: start, to: end).day
    }

    /// True when an expiry date is set and falls within the next 30 days.
    var isExpiringSoon: Bool {
        guard let days = daysUntilExpiry else { return false }
        return days >= 0 && days <= 30
    }

    var isExpired: Bool {
        guard let days = daysUntilExpiry else { return false }
        return days < 0
    }
}
