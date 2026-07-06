//
//  DefectAnalysis.swift
//  TaulbeePainting
//

import Foundation

/// Structured diagnosis returned by the AI vision model.
nonisolated struct DefectAnalysis: Codable, Equatable {
    let isPaintIssue: Bool
    let defectName: String
    let confidence: Double
    let severity: String
    let summary: String
    let surface: String
    let causes: [String]
    let solutions: [String]
    let whenToCallPro: String

    /// Confidence clamped to a friendly 0...1 range.
    var clampedConfidence: Double {
        max(0, min(1, confidence))
    }
}
