//
//  PaintProduct.swift
//  TaulbeePainting
//
//  Curated, recommended paint & primer products surfaced in the Expert tab's
//  product library. Static reference data — kept lightweight and in-memory.
//

import SwiftUI

/// A product-library use category.
enum ProductCategory: String, CaseIterable, Identifiable, Codable {
    case interiorWalls
    case trim
    case cabinets
    case exterior
    case ceilings
    case primers
    case specialty

    var id: String { rawValue }

    var label: String {
        switch self {
        case .interiorWalls: return "Interior Walls"
        case .trim: return "Trim & Doors"
        case .cabinets: return "Cabinets"
        case .exterior: return "Exterior"
        case .ceilings: return "Ceilings"
        case .primers: return "Primers"
        case .specialty: return "Specialty"
        }
    }

    var systemImage: String {
        switch self {
        case .interiorWalls: return "square.split.bottomrightquarter.fill"
        case .trim: return "rectangle.portrait.fill"
        case .cabinets: return "cabinet.fill"
        case .exterior: return "house.fill"
        case .ceilings: return "rectangle.fill"
        case .primers: return "drop.fill"
        case .specialty: return "sparkles"
        }
    }

    var tint: Color {
        switch self {
        case .interiorWalls: return Theme.brand
        case .trim: return Color(hex: "5B5BD6")
        case .cabinets: return Color(hex: "C2773F")
        case .exterior: return Color(hex: "2E9E6B")
        case .ceilings: return Color(hex: "3B82A0")
        case .primers: return Color(hex: "8A6D3B")
        case .specialty: return Theme.accent
        }
    }
}

/// A single recommended product.
struct PaintProduct: Identifiable, Hashable {
    let id: String
    let name: String
    let brand: String
    let category: ProductCategory
    /// Sheen / finish, e.g. "Matte", "Satin", "Semi-Gloss".
    let finish: String
    /// One-line "best for" summary.
    let bestFor: String
    /// 3-5 short feature bullets.
    let features: [String]
}
