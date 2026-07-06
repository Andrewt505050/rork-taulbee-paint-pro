//
//  ProductCatalog.swift
//  TaulbeePainting
//
//  Curated list of recommended products Taulbee Painting stands behind,
//  grouped by use. Used by the Expert tab's product library and to ground
//  the AI advisor's recommendations.
//

import Foundation

enum ProductCatalog {
    static let all: [PaintProduct] = [
        // MARK: Interior walls
        PaintProduct(
            id: "sw-emerald-interior",
            name: "Emerald Interior Acrylic Latex",
            brand: "Sherwin-Williams",
            category: .interiorWalls,
            finish: "Matte / Satin",
            bestFor: "Premium washable finish for high-traffic living spaces.",
            features: [
                "Excellent scrubbability and stain resistance",
                "Superb hide — often one coat over similar colors",
                "Anti-microbial agents resist mold & mildew",
                "Low odor, low-VOC"
            ]
        ),
        PaintProduct(
            id: "bm-regal-select",
            name: "Regal Select Interior",
            brand: "Benjamin Moore",
            category: .interiorWalls,
            finish: "Matte / Eggshell",
            bestFor: "Smooth, durable walls in bedrooms and hallways.",
            features: [
                "Self-priming on most surfaces",
                "Easy touch-up that blends seamlessly",
                "Stain-release technology",
                "Great flow and leveling"
            ]
        ),
        PaintProduct(
            id: "ppg-diamond",
            name: "Diamond Interior",
            brand: "PPG",
            category: .interiorWalls,
            finish: "Eggshell",
            bestFor: "Budget-friendly durability for busy households.",
            features: [
                "Scuff & stain resistant",
                "Paint + primer in one",
                "Mildew-resistant finish",
                "Strong value for the performance"
            ]
        ),
        PaintProduct(
            id: "sw-duration-home",
            name: "Duration Home Interior",
            brand: "Sherwin-Williams",
            category: .interiorWalls,
            finish: "Matte / Satin",
            bestFor: "Kitchens & bathrooms that need moisture resistance.",
            features: [
                "Moisture & humidity resistant",
                "Washable smooth finish",
                "Resists peeling in damp rooms",
                "Low-VOC"
            ]
        ),

        // MARK: Trim & doors
        PaintProduct(
            id: "bm-advance",
            name: "Advance Interior Alkyd",
            brand: "Benjamin Moore",
            category: .trim,
            finish: "Semi-Gloss / Satin",
            bestFor: "Furniture-smooth trim, doors and millwork.",
            features: [
                "Waterborne alkyd — hard, durable cure",
                "Levels out brush marks beautifully",
                "Soap-and-water cleanup",
                "Excellent for high-touch surfaces"
            ]
        ),
        PaintProduct(
            id: "sw-emerald-urethane",
            name: "Emerald Urethane Trim Enamel",
            brand: "Sherwin-Williams",
            category: .trim,
            finish: "Semi-Gloss / Gloss",
            bestFor: "A glass-like, ultra-hard finish on trim and doors.",
            features: [
                "Urethane toughness resists chips",
                "Outstanding leveling and flow",
                "Blocks stains and yellowing",
                "Holds up to repeated cleaning"
            ]
        ),

        // MARK: Cabinets
        PaintProduct(
            id: "bm-advance-cabinets",
            name: "Advance (Cabinet System)",
            brand: "Benjamin Moore",
            category: .cabinets,
            finish: "Satin / Semi-Gloss",
            bestFor: "A factory-smooth, durable finish on kitchen cabinets.",
            features: [
                "Hard enamel cure for daily wear",
                "Self-leveling to hide brush strokes",
                "Pairs with a bonding primer",
                "Wide custom color range"
            ]
        ),
        PaintProduct(
            id: "sw-emerald-cabinet",
            name: "Emerald Urethane (Cabinets)",
            brand: "Sherwin-Williams",
            category: .cabinets,
            finish: "Satin / Semi-Gloss",
            bestFor: "Tough, washable cabinet color that resists blocking.",
            features: [
                "Resists sticking on closed doors",
                "Premium leveling for a sprayed look",
                "Excellent adhesion over primer",
                "Stain & moisture resistant"
            ]
        ),

        // MARK: Exterior
        PaintProduct(
            id: "sw-duration-exterior",
            name: "Duration Exterior Acrylic",
            brand: "Sherwin-Williams",
            category: .exterior,
            finish: "Satin / Flat",
            bestFor: "Long-lasting protection on siding and stucco.",
            features: [
                "Self-priming, thick coat build",
                "Resists peeling, blistering and fading",
                "PermaLast technology for flexibility",
                "Mildew-resistant coating"
            ]
        ),
        PaintProduct(
            id: "bm-aura-exterior",
            name: "Aura Exterior",
            brand: "Benjamin Moore",
            category: .exterior,
            finish: "Satin / Low-Lustre",
            bestFor: "Rich, fade-resistant color that lasts for years.",
            features: [
                "Color Lock technology for vibrancy",
                "Applies in cooler temperatures",
                "Mildew & moisture resistant",
                "Exceptional coverage"
            ]
        ),
        PaintProduct(
            id: "ppg-timeless-exterior",
            name: "Timeless Exterior",
            brand: "PPG",
            category: .exterior,
            finish: "Flat / Satin",
            bestFor: "Dependable exterior protection at great value.",
            features: [
                "Paint + primer in one",
                "Resists dirt, fading and mildew",
                "Strong hide in fewer coats",
                "Weather-tough acrylic"
            ]
        ),

        // MARK: Ceilings
        PaintProduct(
            id: "sw-eminence-ceiling",
            name: "Eminence High-Performance Ceiling",
            brand: "Sherwin-Williams",
            category: .ceilings,
            finish: "Flat",
            bestFor: "Bright, uniform ceilings that hide imperfections.",
            features: [
                "Ultra-flat to mask surface flaws",
                "Spatter-resistant application",
                "Goes on pink, dries bright white",
                "Great for new drywall"
            ]
        ),

        // MARK: Primers
        PaintProduct(
            id: "zinsser-bin",
            name: "B-I-N Shellac Primer",
            brand: "Zinsser",
            category: .primers,
            finish: "Primer",
            bestFor: "Blocking stubborn stains, knots and odors.",
            features: [
                "Seals water, smoke and tannin stains",
                "Superb adhesion on glossy surfaces",
                "Fast drying — recoat in under an hour",
                "Locks in odors"
            ]
        ),
        PaintProduct(
            id: "sw-extreme-bond",
            name: "Extreme Bond Primer",
            brand: "Sherwin-Williams",
            category: .primers,
            finish: "Primer",
            bestFor: "Gripping tricky surfaces like tile, PVC and laminate.",
            features: [
                "Bonds to slick, hard-to-paint surfaces",
                "Interior & exterior use",
                "Great base for cabinet projects",
                "Low-VOC waterborne formula"
            ]
        ),
        PaintProduct(
            id: "kilz-original",
            name: "KILZ Original Multi-Surface",
            brand: "KILZ",
            category: .primers,
            finish: "Primer",
            bestFor: "Heavy-duty stain blocking before a fresh coat.",
            features: [
                "Blocks severe water & smoke stains",
                "Seals porous surfaces",
                "Strong adhesion base",
                "Trusted general-purpose primer"
            ]
        ),

        // MARK: Specialty
        PaintProduct(
            id: "sw-loxon",
            name: "Loxon Masonry Coating",
            brand: "Sherwin-Williams",
            category: .specialty,
            finish: "Flat / Satin",
            bestFor: "Sealing and protecting concrete, brick and stucco.",
            features: [
                "Breathable, alkali-resistant film",
                "Resists wind-driven rain",
                "Bridges fine hairline cracks",
                "Built for masonry substrates"
            ]
        ),
        PaintProduct(
            id: "bm-aura-bath-spa",
            name: "Aura Bath & Spa",
            brand: "Benjamin Moore",
            category: .specialty,
            finish: "Matte",
            bestFor: "A flat look that survives high-humidity bathrooms.",
            features: [
                "Mildew-resistant in steamy rooms",
                "Beautiful matte without sacrificing durability",
                "Easy to clean",
                "Color Lock vibrancy"
            ]
        ),
        PaintProduct(
            id: "sw-porch-floor",
            name: "Porch & Floor Enamel",
            brand: "Sherwin-Williams",
            category: .specialty,
            finish: "Satin / Gloss",
            bestFor: "Foot-traffic-tough color on porches, decks and steps.",
            features: [
                "Abrasion and scuff resistant",
                "For wood and concrete floors",
                "Interior & exterior",
                "Slip-resistant additive compatible"
            ]
        ),
    ]

    /// Products belonging to a given category.
    static func products(in category: ProductCategory) -> [PaintProduct] {
        all.filter { $0.category == category }
    }

    /// A compact reference list used to ground the AI advisor's answers.
    static var promptReference: String {
        all.map { "- \($0.brand) \($0.name) (\($0.category.label), \($0.finish)): \($0.bestFor)" }
            .joined(separator: "\n")
    }
}
