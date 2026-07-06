//
//  VisionProject.swift
//  TaulbeePainting
//
//  A saved color-visualization project: an original photo, the AI-repainted
//  result, the chosen color, and optional notes. Persisted on-device.
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
        notes: String = ""
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
    }

    /// e.g. "BM HC-154 · Hale Navy"
    var colorLabel: String { "\(colorBrand) \(colorCode) · \(colorName)" }
}
