//
//  PaintScan.swift
//  TaulbeePainting
//

import Foundation
import SwiftData

/// A saved paint-defect scan, persisted on-device.
@Model
final class PaintScan {
    var id: UUID
    var createdAt: Date
    @Attribute(.externalStorage) var imageData: Data
    var defectName: String
    var summary: String
    var surface: String
    var severityRaw: String
    var confidence: Double
    var causes: [String]
    var solutions: [String]
    var whenToCallPro: String

    init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        imageData: Data,
        defectName: String,
        summary: String,
        surface: String,
        severityRaw: String,
        confidence: Double,
        causes: [String],
        solutions: [String],
        whenToCallPro: String
    ) {
        self.id = id
        self.createdAt = createdAt
        self.imageData = imageData
        self.defectName = defectName
        self.summary = summary
        self.surface = surface
        self.severityRaw = severityRaw
        self.confidence = confidence
        self.causes = causes
        self.solutions = solutions
        self.whenToCallPro = whenToCallPro
    }

    var severity: Severity { Severity.parse(severityRaw) }

    convenience init(imageData: Data, analysis: DefectAnalysis) {
        self.init(
            imageData: imageData,
            defectName: analysis.defectName,
            summary: analysis.summary,
            surface: analysis.surface,
            severityRaw: analysis.severity,
            confidence: analysis.clampedConfidence,
            causes: analysis.causes,
            solutions: analysis.solutions,
            whenToCallPro: analysis.whenToCallPro
        )
    }
}
