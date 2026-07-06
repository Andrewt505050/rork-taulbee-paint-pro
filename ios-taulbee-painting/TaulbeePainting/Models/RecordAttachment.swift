//
//  RecordAttachment.swift
//  TaulbeePainting
//
//  A single file attached to a HomeRecord — either a photo or a document
//  (e.g. a PDF receipt or warranty). Binary data is kept in external storage
//  so the SwiftData store stays lean.
//

import Foundation
import SwiftData
import UIKit

enum AttachmentKind: String, Codable {
    case image
    case document
}

@Model
final class RecordAttachment {
    var id: UUID
    var createdAt: Date
    var kindRaw: String
    var filename: String
    /// For documents, the lowercased file extension (e.g. "pdf").
    var fileExtension: String
    @Attribute(.externalStorage) var data: Data
    var record: HomeRecord?

    init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        kind: AttachmentKind,
        filename: String,
        fileExtension: String = "",
        data: Data
    ) {
        self.id = id
        self.createdAt = createdAt
        self.kindRaw = kind.rawValue
        self.filename = filename
        self.fileExtension = fileExtension
        self.data = data
    }

    var kind: AttachmentKind { AttachmentKind(rawValue: kindRaw) ?? .document }

    var image: UIImage? {
        guard kind == .image else { return nil }
        return UIImage(data: data)
    }
}
