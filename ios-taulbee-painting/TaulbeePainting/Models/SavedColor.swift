//
//  SavedColor.swift
//  TaulbeePainting
//
//  A paint color a homeowner has saved for a room — from the built-in
//  brand library or entered manually.
//

import SwiftUI
import SwiftData

@Model
final class SavedColor {
    var id: UUID
    var createdAt: Date
    var name: String
    var brand: String
    var code: String
    /// Six-digit hex string without the leading '#'.
    var hex: String
    var sheenRaw: String
    /// Optional surface label, e.g. "Walls" or "Trim".
    var surfaceLabel: String
    var notes: String
    var room: PaintRoom?

    init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        name: String,
        brand: String = "",
        code: String = "",
        hex: String = "",
        sheenRaw: String = "",
        surfaceLabel: String = "",
        notes: String = ""
    ) {
        self.id = id
        self.createdAt = createdAt
        self.name = name
        self.brand = brand
        self.code = code
        self.hex = hex
        self.sheenRaw = sheenRaw
        self.surfaceLabel = surfaceLabel
        self.notes = notes
    }

    var swatch: Color {
        Color(hex: hex.isEmpty ? "CCCCCC" : hex)
    }

    /// e.g. "SW 7008" (empty when both parts are unknown).
    var detailLine: String {
        [brand, code].filter { !$0.isEmpty }.joined(separator: " ")
    }
}
