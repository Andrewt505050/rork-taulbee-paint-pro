//
//  RoomPhoto.swift
//  TaulbeePainting
//
//  A photo attached to a Paint Vault room — general project photos plus
//  tagged before/after shots. Binary data lives in external storage so the
//  SwiftData store stays lean.
//

import Foundation
import SwiftData
import UIKit

enum RoomPhotoKind: String, CaseIterable, Identifiable, Codable {
    case general
    case before
    case after

    var id: String { rawValue }

    var label: String {
        switch self {
        case .general: return "Photo"
        case .before: return "Before"
        case .after: return "After"
        }
    }
}

@Model
final class RoomPhoto {
    var id: UUID
    var createdAt: Date
    var kindRaw: String
    var caption: String
    @Attribute(.externalStorage) var data: Data
    var room: PaintRoom?

    init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        kind: RoomPhotoKind = .general,
        caption: String = "",
        data: Data
    ) {
        self.id = id
        self.createdAt = createdAt
        self.kindRaw = kind.rawValue
        self.caption = caption
        self.data = data
    }

    var kind: RoomPhotoKind {
        get { RoomPhotoKind(rawValue: kindRaw) ?? .general }
        set { kindRaw = newValue.rawValue }
    }

    var image: UIImage? { UIImage(data: data) }
}
