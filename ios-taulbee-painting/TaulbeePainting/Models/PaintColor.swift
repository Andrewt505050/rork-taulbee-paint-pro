//
//  PaintColor.swift
//  TaulbeePainting
//
//  A real paint color from a manufacturer library (Sherwin-Williams,
//  Benjamin Moore, PPG) used by the Vision color visualizer.
//

import SwiftUI

/// Paint manufacturer brands offered in the color library.
nonisolated enum PaintBrand: String, CaseIterable, Codable, Identifiable {
    case sherwinWilliams
    case benjaminMoore
    case ppg

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .sherwinWilliams: "Sherwin-Williams"
        case .benjaminMoore: "Benjamin Moore"
        case .ppg: "PPG"
        }
    }

    /// Short badge label.
    var short: String {
        switch self {
        case .sherwinWilliams: "SW"
        case .benjaminMoore: "BM"
        case .ppg: "PPG"
        }
    }
}

/// Broad color families for browsing and filtering.
nonisolated enum ColorFamily: String, CaseIterable, Codable, Identifiable {
    case whites = "Whites"
    case neutrals = "Neutrals"
    case grays = "Grays"
    case blues = "Blues"
    case greens = "Greens"
    case earth = "Earth"
    case warm = "Warm"
    case darks = "Darks"

    var id: String { rawValue }
}

/// A single named paint color with a real product code and swatch.
nonisolated struct PaintColor: Identifiable, Codable, Equatable, Hashable {
    let brand: PaintBrand
    let name: String
    let code: String
    /// Six-digit hex string without the leading '#'.
    let hex: String
    let family: ColorFamily

    var id: String { "\(brand.rawValue)-\(code)" }

    var color: Color { Color(hex: hex) }

    /// e.g. "SW 7008 · Alabaster"
    var label: String { "\(brand.short) \(code) · \(name)" }

    /// Approximate brightness 0...1 to choose readable foreground text.
    var luminance: Double {
        let rgb = PaintColor.rgb(from: hex)
        return 0.299 * rgb.r + 0.587 * rgb.g + 0.114 * rgb.b
    }

    var prefersDarkText: Bool { luminance > 0.6 }

    static func rgb(from hex: String) -> (r: Double, g: Double, b: Double) {
        var value: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&value)
        let r = Double((value & 0xFF0000) >> 16) / 255
        let g = Double((value & 0x00FF00) >> 8) / 255
        let b = Double(value & 0x0000FF) / 255
        return (r, g, b)
    }
}

extension Color {
    /// Initialize from a six-digit hex string (with or without '#').
    init(hex: String) {
        let cleaned = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        let rgb = PaintColor.rgb(from: cleaned)
        self.init(.sRGB, red: rgb.r, green: rgb.g, blue: rgb.b, opacity: 1)
    }
}
