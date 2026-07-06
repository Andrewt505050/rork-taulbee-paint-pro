//
//  Severity.swift
//  TaulbeePainting
//

import SwiftUI

/// How urgent a diagnosed paint defect is.
enum Severity: String, Codable, CaseIterable, Identifiable {
    case minor
    case moderate
    case serious

    var id: String { rawValue }

    /// Parses a free-form severity string returned by the model.
    static func parse(_ raw: String) -> Severity {
        let value = raw.lowercased()
        if value.contains("serious") || value.contains("severe") || value.contains("high") {
            return .serious
        }
        if value.contains("moderate") || value.contains("medium") {
            return .moderate
        }
        return .minor
    }

    var label: String {
        switch self {
        case .minor: "Minor"
        case .moderate: "Moderate"
        case .serious: "Serious"
        }
    }

    var color: Color {
        switch self {
        case .minor: Color(red: 0.180, green: 0.620, blue: 0.420)
        case .moderate: Color(red: 0.878, green: 0.635, blue: 0.247)
        case .serious: Color(red: 0.831, green: 0.314, blue: 0.243)
        }
    }

    var systemImage: String {
        switch self {
        case .minor: "checkmark.seal.fill"
        case .moderate: "exclamationmark.triangle.fill"
        case .serious: "exclamationmark.octagon.fill"
        }
    }

    /// Normalized 0...1 fill used by the severity gauge.
    var gaugeFraction: Double {
        switch self {
        case .minor: 0.34
        case .moderate: 0.67
        case .serious: 1.0
        }
    }

    var blurb: String {
        switch self {
        case .minor: "Cosmetic — easy to handle"
        case .moderate: "Worth addressing soon"
        case .serious: "Address promptly to prevent damage"
        }
    }
}
