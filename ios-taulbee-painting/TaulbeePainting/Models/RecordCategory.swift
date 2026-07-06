//
//  RecordCategory.swift
//  TaulbeePainting
//
//  The kinds of home records a customer can store in the Vault. Stored as a
//  raw string on `HomeRecord` so the schema stays stable if cases change.
//

import SwiftUI

enum RecordCategory: String, CaseIterable, Identifiable, Codable {
    case receipt
    case contract
    case warranty
    case appliance
    case paintColor
    case manual
    case service
    case other

    var id: String { rawValue }

    var label: String {
        switch self {
        case .receipt: return "Receipt"
        case .contract: return "Contract"
        case .warranty: return "Warranty"
        case .appliance: return "Appliance"
        case .paintColor: return "Paint Color"
        case .manual: return "Manual"
        case .service: return "Service"
        case .other: return "Other"
        }
    }

    var systemImage: String {
        switch self {
        case .receipt: return "receipt.fill"
        case .contract: return "doc.text.fill"
        case .warranty: return "checkmark.shield.fill"
        case .appliance: return "washer.fill"
        case .paintColor: return "paintpalette.fill"
        case .manual: return "book.fill"
        case .service: return "wrench.and.screwdriver.fill"
        case .other: return "tray.full.fill"
        }
    }

    /// Accent color used for badges and chips.
    var tint: Color {
        switch self {
        case .receipt: return Color(hex: "3B82A0")
        case .contract: return Color(hex: "5B5BD6")
        case .warranty: return Color(hex: "2E9E6B")
        case .appliance: return Color(hex: "C2773F")
        case .paintColor: return Theme.brand
        case .manual: return Color(hex: "8A6D3B")
        case .service: return Color(hex: "B0552F")
        case .other: return Theme.inkSecondary
        }
    }

    /// Whether the editor should surface purchase / expiry date fields.
    var usesDates: Bool {
        switch self {
        case .warranty, .receipt, .appliance, .contract: return true
        default: return false
        }
    }
}
