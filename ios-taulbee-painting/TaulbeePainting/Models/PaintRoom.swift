//
//  PaintRoom.swift
//  TaulbeePainting
//
//  A room profile in the Paint Vault: what color is on the walls today,
//  colors the homeowner is considering, photos, surfaces, and care notes.
//  Persisted on-device for privacy.
//

import SwiftUI
import SwiftData

/// The kinds of spaces a homeowner can profile in the Paint Vault.
enum RoomType: String, CaseIterable, Identifiable, Codable {
    case livingRoom
    case kitchen
    case bedroom
    case bathroom
    case diningRoom
    case basement
    case exterior
    case cabinets
    case deckFence
    case other

    var id: String { rawValue }

    var label: String {
        switch self {
        case .livingRoom: return "Living Room"
        case .kitchen: return "Kitchen"
        case .bedroom: return "Bedroom"
        case .bathroom: return "Bathroom"
        case .diningRoom: return "Dining Room"
        case .basement: return "Basement"
        case .exterior: return "Exterior"
        case .cabinets: return "Cabinets"
        case .deckFence: return "Deck / Fence"
        case .other: return "Other"
        }
    }

    var systemImage: String {
        switch self {
        case .livingRoom: return "sofa.fill"
        case .kitchen: return "fork.knife"
        case .bedroom: return "bed.double.fill"
        case .bathroom: return "shower.fill"
        case .diningRoom: return "table.furniture.fill"
        case .basement: return "stairs"
        case .exterior: return "house.fill"
        case .cabinets: return "cabinet.fill"
        case .deckFence: return "fence"
        case .other: return "square.grid.2x2.fill"
        }
    }
}

/// Paintable surfaces tracked on a room's checklist.
enum RoomSurface: String, CaseIterable, Identifiable, Codable {
    case walls
    case ceiling
    case trim
    case doors
    case cabinets

    var id: String { rawValue }

    var label: String {
        switch self {
        case .walls: return "Walls"
        case .ceiling: return "Ceiling"
        case .trim: return "Trim"
        case .doors: return "Doors"
        case .cabinets: return "Cabinets"
        }
    }
}

/// Paint sheen levels, from flattest to shiniest.
enum SheenType: String, CaseIterable, Identifiable, Codable {
    case flat
    case matte
    case eggshell
    case satin
    case semiGloss
    case gloss

    var id: String { rawValue }

    var label: String {
        switch self {
        case .flat: return "Flat"
        case .matte: return "Matte"
        case .eggshell: return "Eggshell"
        case .satin: return "Satin"
        case .semiGloss: return "Semi-Gloss"
        case .gloss: return "Gloss"
        }
    }
}

@Model
final class PaintRoom {
    var id: UUID
    var createdAt: Date
    var updatedAt: Date
    var name: String
    var roomTypeRaw: String

    /// The color currently on the walls (empty strings when unknown).
    var currentColorName: String
    var currentColorBrand: String
    var currentColorCode: String
    var currentColorHex: String
    var sheenRaw: String

    /// Surfaces included in this room's paint scope.
    var surfacesRaw: [String]
    var lastPaintedDate: Date?

    var notes: String
    var conditionNotes: String
    var contractorNotes: String
    var touchUpInstructions: String
    var careNotes: String

    @Relationship(deleteRule: .cascade, inverse: \RoomPhoto.room)
    var photos: [RoomPhoto]

    @Relationship(deleteRule: .cascade, inverse: \SavedColor.room)
    var savedColors: [SavedColor]

    @Relationship(deleteRule: .nullify, inverse: \PaintReminder.room)
    var reminders: [PaintReminder]

    init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        updatedAt: Date = .now,
        name: String,
        roomType: RoomType,
        currentColorName: String = "",
        currentColorBrand: String = "",
        currentColorCode: String = "",
        currentColorHex: String = "",
        sheenRaw: String = "",
        surfacesRaw: [String] = [],
        lastPaintedDate: Date? = nil,
        notes: String = "",
        conditionNotes: String = "",
        contractorNotes: String = "",
        touchUpInstructions: String = "",
        careNotes: String = "",
        photos: [RoomPhoto] = [],
        savedColors: [SavedColor] = [],
        reminders: [PaintReminder] = []
    ) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.name = name
        self.roomTypeRaw = roomType.rawValue
        self.currentColorName = currentColorName
        self.currentColorBrand = currentColorBrand
        self.currentColorCode = currentColorCode
        self.currentColorHex = currentColorHex
        self.sheenRaw = sheenRaw
        self.surfacesRaw = surfacesRaw
        self.lastPaintedDate = lastPaintedDate
        self.notes = notes
        self.conditionNotes = conditionNotes
        self.contractorNotes = contractorNotes
        self.touchUpInstructions = touchUpInstructions
        self.careNotes = careNotes
        self.photos = photos
        self.savedColors = savedColors
        self.reminders = reminders
    }

    var roomType: RoomType {
        get { RoomType(rawValue: roomTypeRaw) ?? .other }
        set { roomTypeRaw = newValue.rawValue }
    }

    var sheen: SheenType? {
        get { SheenType(rawValue: sheenRaw) }
        set { sheenRaw = newValue?.rawValue ?? "" }
    }

    var surfaces: [RoomSurface] {
        get { RoomSurface.allCases.filter { surfacesRaw.contains($0.rawValue) } }
        set { surfacesRaw = newValue.map(\.rawValue) }
    }

    var hasCurrentColor: Bool {
        !currentColorName.isEmpty || !currentColorHex.isEmpty
    }

    /// e.g. "SW 7008 · Alabaster" (parts omitted when unknown).
    var currentColorLabel: String {
        var parts: [String] = []
        if !currentColorBrand.isEmpty { parts.append(currentColorBrand) }
        if !currentColorCode.isEmpty { parts.append(currentColorCode) }
        let lead = parts.joined(separator: " ")
        if lead.isEmpty { return currentColorName }
        return currentColorName.isEmpty ? lead : "\(lead) · \(currentColorName)"
    }

    var orderedPhotos: [RoomPhoto] {
        photos.sorted { $0.createdAt < $1.createdAt }
    }

    var orderedSavedColors: [SavedColor] {
        savedColors.sorted { $0.createdAt < $1.createdAt }
    }

    /// Next active (not completed) reminder attached to this room.
    var nextReminder: PaintReminder? {
        reminders
            .filter { $0.completedAt == nil }
            .min { $0.dueDate < $1.dueDate }
    }

    var lastPaintedText: String {
        guard let lastPaintedDate else { return "Unknown" }
        return lastPaintedDate.formatted(.dateTime.month(.abbreviated).year())
    }
}
