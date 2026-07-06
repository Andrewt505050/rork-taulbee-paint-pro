//
//  ReminderTypes.swift
//  TaulbeePainting
//
//  Supporting types for maintenance reminders: categories, recurrence,
//  priority, status, and the one-tap recommended care templates.
//

import SwiftUI

/// The kinds of paint-care tasks Taulbee recommends homeowners keep up with.
enum ReminderCategory: String, CaseIterable, Identifiable, Codable {
    case interiorTouchUp
    case exteriorInspection
    case caulkInspection
    case woodRot
    case deckStain
    case fenceStain
    case cabinetCare
    case frontDoor
    case pressureWashing
    case trimTouchUp
    case moistureCheck
    case springInspection
    case fallInspection
    case custom

    var id: String { rawValue }

    var label: String {
        switch self {
        case .interiorTouchUp: return "Interior Touch-Up"
        case .exteriorInspection: return "Exterior Inspection"
        case .caulkInspection: return "Caulk Inspection"
        case .woodRot: return "Wood Rot Check"
        case .deckStain: return "Deck Stain / Sealer"
        case .fenceStain: return "Fence Stain / Sealer"
        case .cabinetCare: return "Cabinet Finish Care"
        case .frontDoor: return "Front Door Repaint"
        case .pressureWashing: return "Pressure Washing"
        case .trimTouchUp: return "Trim & Baseboards"
        case .moistureCheck: return "Moisture / Water Stains"
        case .springInspection: return "Spring Inspection"
        case .fallInspection: return "Fall Inspection"
        case .custom: return "Custom"
        }
    }

    var systemImage: String {
        switch self {
        case .interiorTouchUp: return "paintbrush.pointed.fill"
        case .exteriorInspection: return "house.fill"
        case .caulkInspection: return "window.vertical.closed"
        case .woodRot: return "tree.fill"
        case .deckStain: return "rectangle.split.3x1.fill"
        case .fenceStain: return "fence"
        case .cabinetCare: return "cabinet.fill"
        case .frontDoor: return "door.left.hand.closed"
        case .pressureWashing: return "sprinkler.and.droplets.fill"
        case .trimTouchUp: return "ruler.fill"
        case .moistureCheck: return "drop.fill"
        case .springInspection: return "leaf.fill"
        case .fallInspection: return "wind"
        case .custom: return "bell.fill"
        }
    }

    var tint: Color {
        switch self {
        case .interiorTouchUp, .trimTouchUp: return Theme.brand
        case .exteriorInspection, .springInspection: return Color(hex: "2E9E6B")
        case .caulkInspection, .fallInspection: return Color(hex: "C2773F")
        case .woodRot, .deckStain, .fenceStain: return Color(hex: "8A6D3B")
        case .cabinetCare, .frontDoor: return Color(hex: "5B5BD6")
        case .pressureWashing, .moistureCheck: return Color(hex: "3B82A0")
        case .custom: return Theme.lavenderAccent
        }
    }
}

/// How often a reminder repeats after completion.
enum ReminderRecurrence: String, CaseIterable, Identifiable, Codable {
    case none
    case monthly
    case everyThreeMonths
    case everySixMonths
    case yearly
    case everyTwoYears
    case everyThreeYears
    case custom

    var id: String { rawValue }

    var label: String {
        switch self {
        case .none: return "Doesn't repeat"
        case .monthly: return "Monthly"
        case .everyThreeMonths: return "Every 3 months"
        case .everySixMonths: return "Every 6 months"
        case .yearly: return "Yearly"
        case .everyTwoYears: return "Every 2 years"
        case .everyThreeYears: return "Every 3 years"
        case .custom: return "Custom interval"
        }
    }

    /// Short badge label, e.g. "Yearly".
    var short: String {
        switch self {
        case .none: return "Once"
        case .monthly: return "Monthly"
        case .everyThreeMonths: return "3 mo"
        case .everySixMonths: return "6 mo"
        case .yearly: return "Yearly"
        case .everyTwoYears: return "2 yr"
        case .everyThreeYears: return "3 yr"
        case .custom: return "Custom"
        }
    }

    /// The next occurrence after `date`, or nil when the reminder doesn't repeat.
    func nextDate(after date: Date, customDays: Int) -> Date? {
        let calendar = Calendar.current
        switch self {
        case .none:
            return nil
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: date)
        case .everyThreeMonths:
            return calendar.date(byAdding: .month, value: 3, to: date)
        case .everySixMonths:
            return calendar.date(byAdding: .month, value: 6, to: date)
        case .yearly:
            return calendar.date(byAdding: .year, value: 1, to: date)
        case .everyTwoYears:
            return calendar.date(byAdding: .year, value: 2, to: date)
        case .everyThreeYears:
            return calendar.date(byAdding: .year, value: 3, to: date)
        case .custom:
            return calendar.date(byAdding: .day, value: max(1, customDays), to: date)
        }
    }
}

enum ReminderPriority: String, CaseIterable, Identifiable, Codable {
    case low
    case normal
    case high

    var id: String { rawValue }

    var label: String {
        switch self {
        case .low: return "Low"
        case .normal: return "Normal"
        case .high: return "High"
        }
    }

    var tint: Color {
        switch self {
        case .low: return Theme.inkSecondary
        case .normal: return Theme.brand
        case .high: return Color(hex: "C13A2E")
        }
    }
}

/// Derived state of a reminder based on its due date and completion.
enum ReminderStatus {
    case upcoming
    case dueSoon
    case overdue
    case completed

    var label: String {
        switch self {
        case .upcoming: return "Upcoming"
        case .dueSoon: return "Due Soon"
        case .overdue: return "Overdue"
        case .completed: return "Completed"
        }
    }

    var systemImage: String {
        switch self {
        case .upcoming: return "calendar"
        case .dueSoon: return "clock.fill"
        case .overdue: return "exclamationmark.circle.fill"
        case .completed: return "checkmark.circle.fill"
        }
    }

    var tint: Color {
        switch self {
        case .upcoming: return Theme.brand
        case .dueSoon: return Theme.accent
        case .overdue: return Color(hex: "C13A2E")
        case .completed: return Color(hex: "2E9E6B")
        }
    }
}

// MARK: - Recommended care templates

/// A one-tap reminder homeowners can add from the Recommended Care Schedule.
struct CareTemplate: Identifiable {
    let id: String
    let title: String
    let detail: String
    let category: ReminderCategory
    let recurrence: ReminderRecurrence

    /// A sensible first due date for this kind of check.
    var suggestedDueDate: Date {
        switch category {
        case .springInspection: return CareTemplate.next(month: 4, day: 1)
        case .fallInspection, .caulkInspection: return CareTemplate.next(month: 10, day: 1)
        case .deckStain, .fenceStain: return CareTemplate.next(month: 5, day: 15)
        default:
            return Calendar.current.date(byAdding: .month, value: 6, to: .now) ?? .now
        }
    }

    /// The next calendar date matching the given month/day.
    static func next(month: Int, day: Int) -> Date {
        let components = DateComponents(month: month, day: day)
        return Calendar.current.nextDate(after: .now, matching: components, matchingPolicy: .nextTime) ?? .now
    }

    static let all: [CareTemplate] = [
        CareTemplate(
            id: "spring",
            title: "Spring exterior paint inspection",
            detail: "Check peeling paint, failed caulk, exposed wood, mildew, and fading.",
            category: .springInspection,
            recurrence: .yearly
        ),
        CareTemplate(
            id: "fall-caulk",
            title: "Fall caulk inspection",
            detail: "Look around windows, doors, trim joints, and exterior seams before winter.",
            category: .caulkInspection,
            recurrence: .yearly
        ),
        CareTemplate(
            id: "interior-touchup",
            title: "Interior touch-up check",
            detail: "Check high-traffic areas, baseboards, doors, and corners for scuffs.",
            category: .interiorTouchUp,
            recurrence: .everySixMonths
        ),
        CareTemplate(
            id: "deck-fence",
            title: "Deck or fence stain check",
            detail: "Check for fading, water absorption, peeling, or dry wood.",
            category: .deckStain,
            recurrence: .yearly
        ),
        CareTemplate(
            id: "cabinets",
            title: "Cabinet finish care",
            detail: "Check cabinet doors, handles, edges, and cleaning wear.",
            category: .cabinetCare,
            recurrence: .everySixMonths
        ),
    ]
}
