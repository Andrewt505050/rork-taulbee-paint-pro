//
//  VisionProject.swift
//  TaulbeePainting
//
//  A saved color-visualization project: an original photo, the AI-repainted
//  result, the chosen color scheme (one or more painted surfaces), and
//  optional notes. Persisted on-device.
//

import Foundation
import SwiftData

@Model
final class VisionProject {
    var id: UUID
    var createdAt: Date
    @Attribute(.externalStorage) var originalImageData: Data
    @Attribute(.externalStorage) var resultImageData: Data
    var colorName: String
    var colorCode: String
    var colorBrand: String
    var colorHex: String
    var surfaceLabel: String
    var notes: String
    /// JSON-encoded `[SavedSurfacePaint]` for multi-surface schemes.
    /// Nil on legacy single-surface projects — `scheme` falls back to the
    /// single-color fields above.
    var schemeData: Data?

    init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        originalImageData: Data,
        resultImageData: Data,
        colorName: String,
        colorCode: String,
        colorBrand: String,
        colorHex: String,
        surfaceLabel: String,
        notes: String = "",
        schemeData: Data? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.originalImageData = originalImageData
        self.resultImageData = resultImageData
        self.colorName = colorName
        self.colorCode = colorCode
        self.colorBrand = colorBrand
        self.colorHex = colorHex
        self.surfaceLabel = surfaceLabel
        self.notes = notes
        self.schemeData = schemeData
    }

    /// e.g. "BM HC-154 · Hale Navy"
    var colorLabel: String { "\(colorBrand) \(colorCode) · \(colorName)" }

    /// The full painted scheme, oldest surface first. Falls back to the
    /// legacy single-color fields for projects saved before schemes existed.
    var scheme: [SavedSurfacePaint] {
        if let schemeData,
           let decoded = try? JSONDecoder().decode([SavedSurfacePaint].self, from: schemeData),
           !decoded.isEmpty {
            return decoded
        }
        return [SavedSurfacePaint(
            surfaceLabel: surfaceLabel,
            colorName: colorName,
            colorCode: colorCode,
            colorBrand: colorBrand,
            colorHex: colorHex
        )]
    }
}

/// One painted surface in a saved color scheme.
nonisolated struct SavedSurfacePaint: Codable, Hashable {
    let surfaceLabel: String
    let colorName: String
    let colorCode: String
    let colorBrand: String
    let colorHex: String
}
