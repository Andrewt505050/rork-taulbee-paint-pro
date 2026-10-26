//
//  MaskValidator.swift
//  TaulbeePainting
//
//  Sanity checks for AI surface masks. The image model occasionally outlines
//  the wrong plane (a pale ceiling instead of the walls, a floor instead of
//  baseboards). Before a mask is accepted, its coverage, vertical placement,
//  and agreement with the spot the customer tapped are measured, so a wrong
//  outline is retried instead of silently painted.
//

import UIKit

/// Compact statistics about where a mask's white pixels sit in the frame.
nonisolated struct MaskAnalysis {
    /// Fraction of the whole image the mask covers (0...1).
    let coverage: Double
    /// Mean vertical position of the masked pixels: 0 = top edge, 1 = bottom.
    let verticalCentroid: Double
    /// Share of the masked pixels in the top 30% of the frame.
    let topShare: Double
    /// Share of the masked pixels in the bottom 30% of the frame.
    let bottomShare: Double

    private let width: Int
    private let height: Int
    private let pixels: [UInt8]

    /// Downsamples the mask to a small grayscale grid and gathers statistics.
    /// Returns nil when the mask can't be read.
    init?(mask: UIImage, gridWidth: Int = 96) {
        guard let cgImage = mask.cgImage, cgImage.width > 0, cgImage.height > 0 else { return nil }
        let aspect = Double(cgImage.height) / Double(cgImage.width)
        let width = gridWidth
        let height = max(8, Int((Double(gridWidth) * aspect).rounded()))

        var buffer = [UInt8](repeating: 0, count: width * height)
        let drawn = buffer.withUnsafeMutableBytes { raw -> Bool in
            guard let base = raw.baseAddress,
                  let context = CGContext(
                    data: base,
                    width: width,
                    height: height,
                    bitsPerComponent: 8,
                    bytesPerRow: width,
                    space: CGColorSpaceCreateDeviceGray(),
                    bitmapInfo: CGImageAlphaInfo.none.rawValue
                  ) else { return false }
            context.interpolationQuality = .medium
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        guard drawn else { return nil }

        var total = 0
        var weightedRows = 0.0
        var top = 0
        var bottom = 0
        let topLimit = Int(Double(height) * 0.30)
        let bottomStart = height - topLimit
        for row in 0..<height {
            for column in 0..<width where buffer[row * width + column] >= 128 {
                total += 1
                weightedRows += (Double(row) + 0.5) / Double(height)
                if row < topLimit { top += 1 }
                if row >= bottomStart { bottom += 1 }
            }
        }

        self.width = width
        self.height = height
        self.pixels = buffer
        self.coverage = Double(total) / Double(width * height)
        self.verticalCentroid = total > 0 ? weightedRows / Double(total) : 0.5
        self.topShare = total > 0 ? Double(top) / Double(total) : 0
        self.bottomShare = total > 0 ? Double(bottom) / Double(total) : 0
    }

    /// Fraction of masked pixels in a small neighborhood around a normalized
    /// point (0...1 on both axes, origin top-left).
    func coverage(around point: CGPoint, radius: Double = 0.035) -> Double {
        let centerX = Double(point.x) * Double(width)
        let centerY = Double(point.y) * Double(height)
        let radiusPixels = max(1.5, radius * Double(max(width, height)))
        var inside = 0
        var hit = 0
        let minRow = max(0, Int(centerY - radiusPixels))
        let maxRow = min(height - 1, Int(centerY + radiusPixels))
        let minColumn = max(0, Int(centerX - radiusPixels))
        let maxColumn = min(width - 1, Int(centerX + radiusPixels))
        guard minRow <= maxRow, minColumn <= maxColumn else { return 0 }
        for row in minRow...maxRow {
            for column in minColumn...maxColumn {
                let dx = Double(column) + 0.5 - centerX
                let dy = Double(row) + 0.5 - centerY
                guard dx * dx + dy * dy <= radiusPixels * radiusPixels else { continue }
                inside += 1
                if pixels[row * width + column] >= 128 { hit += 1 }
            }
        }
        return inside > 0 ? Double(hit) / Double(inside) : 0
    }
}

/// Why a mask was rejected; drives the stricter retry prompt.
nonisolated enum MaskRejection: Equatable {
    case empty
    case everything
    case missedTap
    case looksLikeCeiling
    case looksLikeFloor
    case tooLow
    case tooHigh
    case tooBroad

    /// Extra instruction for the retry, phrased for the image model.
    var retryInstruction: String {
        switch self {
        case .empty:
            "The previous attempt returned almost no white pixels. The target surface IS present in this photo; find it and mark the whole surface white."
        case .everything:
            "The previous attempt marked nearly the whole photo white. Only the target surface may be white; everything else must be black."
        case .missedTap:
            "The previous attempt did not include the point the user tapped. That point is definitely on the target surface and MUST be white."
        case .looksLikeCeiling:
            "The previous attempt wrongly selected the CEILING — the overhead surface across the top of the photo. The ceiling must be pure black. Select only the vertical wall surfaces that run from the ceiling line down to the floor."
        case .looksLikeFloor:
            "The previous attempt wrongly selected the FLOOR across the bottom of the photo. The floor, carpet and rugs must be pure black."
        case .tooLow:
            "The previous attempt selected a surface in the lower part of the photo. The target is in the UPPER part of the photo; everything below it must be black."
        case .tooHigh:
            "The previous attempt selected a surface in the upper part of the photo. The target runs along the LOWER part of the photo; everything above it must be black."
        case .tooBroad:
            "The previous attempt selected a broad area. The target is made of narrow bands and edges; broad wall, ceiling and floor planes must be pure black."
        }
    }
}

nonisolated enum MaskValidator {
    /// Checks a detected mask against what the target surface should look
    /// like in a typical photo. `hint` is the normalized point the customer
    /// tapped (origin top-left), when available.
    static func validate(_ analysis: MaskAnalysis, target: PaintTarget, hint: CGPoint?) -> MaskRejection? {
        if analysis.coverage < 0.015 { return .empty }
        if analysis.coverage > 0.96 { return .everything }

        if let hint, analysis.coverage(around: hint) < 0.25 {
            return .missedTap
        }

        switch target {
        case .interiorWalls, .accentWall, .exteriorSiding:
            if analysis.topShare > 0.80 && analysis.verticalCentroid < 0.22 { return .looksLikeCeiling }
            if analysis.bottomShare > 0.80 && analysis.verticalCentroid > 0.80 { return .looksLikeFloor }
        case .ceiling:
            if analysis.verticalCentroid > 0.58 { return .tooLow }
        case .baseboards, .deck:
            if analysis.verticalCentroid < 0.42 { return .tooHigh }
        case .trim, .windowTrim:
            if analysis.coverage > 0.45 { return .tooBroad }
        case .porchRailings, .shutters, .garageDoor, .frontDoor, .interiorDoors, .cabinets, .kitchenIsland, .fence:
            if analysis.coverage > 0.85 { return .everything }
        }
        return nil
    }
}
