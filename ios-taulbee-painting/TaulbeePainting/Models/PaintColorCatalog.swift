//
//  PaintColorCatalog.swift
//  TaulbeePainting
//
//  The complete Sherwin-Williams, Benjamin Moore, and PPG color books
//  (7,700+ real colors) decoded once from bundled JSON resources, with
//  search, brand/family filtering, and a curated "Popular" shelf.
//

import Foundation

/// Full manufacturer color books. Seeded with the curated library so the UI
/// always has data, then swapped for the complete books after a one-time
/// background decode.
@Observable
@MainActor
final class PaintColorCatalog {
    static let shared = PaintColorCatalog()

    /// Every available color across the three brands.
    private(set) var all: [PaintColor] = PaintColorLibrary.all
    /// True once the full bundled books have been decoded.
    private(set) var isLoaded = false

    private var index: [String: PaintColor] = [:]
    private var loadTask: Task<Void, Never>?

    private init() {
        rebuildIndex()
    }

    /// Decodes the bundled color books once; safe to call from multiple places.
    func loadIfNeeded() async {
        if isLoaded { return }
        if let loadTask {
            await loadTask.value
            return
        }
        let task = Task {
            let decoded = await Task.detached(priority: .userInitiated) {
                decodeBundledColorBooks()
            }.value
            guard !decoded.isEmpty else { return }
            self.all = decoded
            self.rebuildIndex()
            self.isLoaded = true
        }
        loadTask = task
        await task.value
    }

    /// Filtered view over the whole catalog.
    func colors(brand: PaintBrand?, family: ColorFamily?, query: String) -> [PaintColor] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return all.filter { color in
            (brand == nil || color.brand == brand)
                && (family == nil || color.family == family)
                && (trimmed.isEmpty
                    || color.name.localizedCaseInsensitiveContains(trimmed)
                    || color.code.localizedCaseInsensitiveContains(trimmed))
        }
    }

    /// Exact lookup by brand + product code.
    func color(brand: PaintBrand, code: String) -> PaintColor? {
        index["\(brand.rawValue)|\(code.uppercased())"]
    }

    /// Designer bestsellers, resolved against the loaded books.
    var popular: [PaintColor] {
        Self.popularPicks.compactMap { color(brand: $0.brand, code: $0.code) }
    }

    private func rebuildIndex() {
        var rebuilt: [String: PaintColor] = [:]
        rebuilt.reserveCapacity(all.count)
        for color in all {
            rebuilt["\(color.brand.rawValue)|\(color.code.uppercased())"] = color
        }
        index = rebuilt
    }

    /// The most-requested colors homeowners actually buy, across brands.
    private static let popularPicks: [(brand: PaintBrand, code: String)] = [
        (.sherwinWilliams, "7008"),   // Alabaster
        (.sherwinWilliams, "7029"),   // Agreeable Gray
        (.benjaminMoore, "OC-117"),   // Simply White
        (.benjaminMoore, "OC-17"),    // White Dove
        (.sherwinWilliams, "7015"),   // Repose Gray
        (.benjaminMoore, "HC-172"),   // Revere Pewter
        (.sherwinWilliams, "6204"),   // Sea Salt
        (.sherwinWilliams, "7036"),   // Accessible Beige
        (.benjaminMoore, "HC-173"),   // Edgecomb Gray
        (.sherwinWilliams, "9130"),   // Evergreen Fog
        (.benjaminMoore, "HC-144"),   // Palladian Blue
        (.sherwinWilliams, "6244"),   // Naval
        (.benjaminMoore, "HC-154"),   // Hale Navy
        (.sherwinWilliams, "7069"),   // Iron Ore
        (.benjaminMoore, "HC-166"),   // Kendall Charcoal
        (.sherwinWilliams, "7048"),   // Urbane Bronze
        (.sherwinWilliams, "6258"),   // Tricorn Black
        (.benjaminMoore, "2124-10"),  // Wrought Iron
        (.ppg, "PPG1001-1"),          // Delicate White
        (.ppg, "PPG1011-3"),          // Whirlwind
        (.ppg, "PPG1043-7"),          // Dark Night
        (.sherwinWilliams, "7701"),   // Cavern Clay
        (.benjaminMoore, "AF-290"),   // Caliente
        (.ppg, "CW-615"),             // Penniman Blue
    ]
}

// MARK: - Bundled book decoding

private nonisolated struct ColorBookFile: Decodable {
    /// Compact triplets: [name, code, hex].
    let colors: [[String]]
}

/// Decodes all three bundled brand books off the main thread. Falls back to
/// the curated seed per brand if a resource is missing or unreadable.
private nonisolated func decodeBundledColorBooks() -> [PaintColor] {
    let books: [(brand: PaintBrand, resource: String)] = [
        (.sherwinWilliams, "sherwin_williams"),
        (.benjaminMoore, "benjamin_moore"),
        (.ppg, "ppg"),
    ]
    var result: [PaintColor] = []
    result.reserveCapacity(8000)

    for book in books {
        var brandColors: [PaintColor] = []
        if let url = Bundle.main.url(forResource: book.resource, withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let file = try? JSONDecoder().decode(ColorBookFile.self, from: data) {
            brandColors.reserveCapacity(file.colors.count)
            for entry in file.colors where entry.count >= 3 {
                brandColors.append(PaintColor(
                    brand: book.brand,
                    name: entry[0],
                    code: entry[1],
                    hex: entry[2],
                    family: classifyFamily(hex: entry[2])
                ))
            }
        }
        if brandColors.isEmpty {
            brandColors = PaintColorLibrary.all.filter { $0.brand == book.brand }
        }
        result.append(contentsOf: brandColors)
    }
    return result
}

/// Approximates a browsing family for a swatch from hue, saturation, and
/// perceived lightness. Used for the whole-book filter chips.
private nonisolated func classifyFamily(hex: String) -> ColorFamily {
    let rgb = PaintColor.rgb(from: hex)
    let maxValue = max(rgb.r, max(rgb.g, rgb.b))
    let minValue = min(rgb.r, min(rgb.g, rgb.b))
    let delta = maxValue - minValue
    let saturation = maxValue == 0 ? 0 : delta / maxValue
    let luma = 0.299 * rgb.r + 0.587 * rgb.g + 0.114 * rgb.b

    var hue: Double = 0
    if delta > 0 {
        if maxValue == rgb.r {
            hue = ((rgb.g - rgb.b) / delta).truncatingRemainder(dividingBy: 6)
        } else if maxValue == rgb.g {
            hue = (rgb.b - rgb.r) / delta + 2
        } else {
            hue = (rgb.r - rgb.g) / delta + 4
        }
        hue *= 60
        if hue < 0 { hue += 360 }
    }

    if luma < 0.14 { return .darks }
    if saturation < 0.07 {
        if luma > 0.84 { return .whites }
        if luma < 0.24 { return .darks }
        return .grays
    }
    if luma > 0.86 && saturation < 0.16 { return .whites }
    if saturation < 0.17 {
        return (hue >= 20 && hue <= 100) ? .neutrals : .grays
    }

    switch hue {
    case ..<15:
        return luma < 0.38 ? .earth : .warm
    case 15..<48:
        if luma < 0.42 { return .earth }
        return saturation < 0.32 && luma > 0.62 ? .neutrals : .warm
    case 48..<75:
        return .warm
    case 75..<165:
        return .greens
    case 165..<260:
        return .blues
    default:
        return luma < 0.30 ? .darks : .warm
    }
}
