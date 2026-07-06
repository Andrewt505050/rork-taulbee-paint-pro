//
//  ScanResult.swift
//  TaulbeePainting
//
//  A unified presentation model so the Result screen can render both a fresh
//  analysis and a saved history record.
//

import UIKit

struct ScanResult: Identifiable {
    let id: UUID
    let image: UIImage?
    let defectName: String
    let summary: String
    let surface: String
    let severity: Severity
    let confidence: Double
    let causes: [String]
    let solutions: [String]
    let whenToCallPro: String
    let date: Date

    init(image: UIImage?, analysis: DefectAnalysis, date: Date = .now) {
        self.id = UUID()
        self.image = image
        self.defectName = analysis.defectName
        self.summary = analysis.summary
        self.surface = analysis.surface
        self.severity = Severity.parse(analysis.severity)
        self.confidence = analysis.clampedConfidence
        self.causes = analysis.causes
        self.solutions = analysis.solutions
        self.whenToCallPro = analysis.whenToCallPro
        self.date = date
    }

    init(scan: PaintScan) {
        self.id = scan.id
        self.image = UIImage(data: scan.imageData)
        self.defectName = scan.defectName
        self.summary = scan.summary
        self.surface = scan.surface
        self.severity = scan.severity
        self.confidence = scan.confidence
        self.causes = scan.causes
        self.solutions = scan.solutions
        self.whenToCallPro = scan.whenToCallPro
        self.date = scan.createdAt
    }

    /// Plain-text summary used by the share sheet.
    var shareText: String {
        var lines: [String] = []
        lines.append("Taulbee Painting — Defect Scan")
        lines.append("")
        lines.append("Issue: \(defectName)")
        lines.append("Surface: \(surface)")
        lines.append("Severity: \(severity.label)")
        lines.append("Confidence: \(Int((confidence * 100).rounded()))%")
        lines.append("")
        lines.append("Summary: \(summary)")
        if !causes.isEmpty {
            lines.append("")
            lines.append("Likely causes:")
            causes.forEach { lines.append("• \($0)") }
        }
        if !solutions.isEmpty {
            lines.append("")
            lines.append("Recommended solutions:")
            for (index, step) in solutions.enumerated() {
                lines.append("\(index + 1). \(step)")
            }
        }
        if !whenToCallPro.isEmpty {
            lines.append("")
            lines.append("When to call a pro: \(whenToCallPro)")
        }
        lines.append("")
        lines.append("Sent from the Taulbee Painting app — \(BusinessInfo.website)")
        return lines.joined(separator: "\n")
    }
}
