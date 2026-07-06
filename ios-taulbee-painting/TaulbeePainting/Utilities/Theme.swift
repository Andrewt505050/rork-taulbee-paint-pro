//
//  Theme.swift
//  TaulbeePainting
//
//  Central design system: colors, typography, spacing, and shadows.
//  Premium aesthetic with a rich purple brand and lavender accents,
//  with full light & dark mode support via dynamic colors.
//

import SwiftUI
import UIKit

/// App-wide design tokens for a premium, contractor-backed painting assistant.
enum Theme {
    /// Builds a color that automatically resolves for light and dark appearances.
    private static func dynamic(
        light: (CGFloat, CGFloat, CGFloat),
        dark: (CGFloat, CGFloat, CGFloat)
    ) -> Color {
        Color(uiColor: UIColor { traits in
            let c = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: c.0, green: c.1, blue: c.2, alpha: 1)
        })
    }

    // MARK: Surfaces
    /// App background — warm lavender paper in light, deep ink-purple in dark.
    static let canvas = dynamic(
        light: (0.975, 0.966, 0.974),
        dark: (0.063, 0.055, 0.090)
    )
    /// Slightly deeper background used for inset fields and grouped wells.
    static let canvasDeep = dynamic(
        light: (0.947, 0.937, 0.955),
        dark: (0.106, 0.094, 0.149)
    )
    /// Card surface.
    static let surface = dynamic(
        light: (1.0, 1.0, 1.0),
        dark: (0.118, 0.106, 0.165)
    )

    // MARK: Brand
    /// Taulbee brand rich royal purple (from logo).
    static let brand = dynamic(
        light: (0.388, 0.196, 0.553),
        dark: (0.612, 0.439, 0.851)
    )
    /// Deeper brand purple for gradients.
    static let brandDeep = Color(red: 0.227, green: 0.094, blue: 0.392)
    /// Brighter violet used as a third gradient stop for vivid heroes.
    static let brandBright = Color(red: 0.545, green: 0.290, blue: 0.769)
    /// Soft lavender tint for chips, icon wells, selected states.
    static let lavender = dynamic(
        light: (0.935, 0.918, 0.966),
        dark: (0.196, 0.157, 0.290)
    )
    /// Mid lavender accent for secondary highlights.
    static let lavenderAccent = dynamic(
        light: (0.690, 0.580, 0.871),
        dark: (0.741, 0.651, 0.918)
    )
    /// Warm amber accent reserved for warnings/expiry highlights.
    static let accent = dynamic(
        light: (0.878, 0.478, 0.247),
        dark: (0.929, 0.580, 0.357)
    )

    // MARK: Text
    /// Primary ink — near-charcoal in light, near-white in dark.
    static let ink = dynamic(
        light: (0.105, 0.090, 0.149),
        dark: (0.961, 0.953, 0.980)
    )
    /// Secondary text.
    static let inkSecondary = dynamic(
        light: (0.435, 0.420, 0.490),
        dark: (0.659, 0.639, 0.722)
    )
    /// Hairline separators.
    static let hairline = dynamic(
        light: (0.906, 0.898, 0.929),
        dark: (0.231, 0.216, 0.298)
    )

    // MARK: Layout
    static let cardRadius: CGFloat = 22
    static let heroRadius: CGFloat = 28
    static let chipRadius: CGFloat = 14

    /// Two-stop brand gradient (buttons, small accents).
    static let brandGradient = LinearGradient(
        colors: [brand, brandDeep],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Vivid three-stop gradient for hero cards.
    static let heroGradient = LinearGradient(
        colors: [brandBright, brand, brandDeep],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static func cardShadow(_ color: Color = Color.black.opacity(0.06)) -> Color { color }
}

/// User-selectable appearance: follow the system, or force light/dark.
enum AppearanceMode: String, CaseIterable, Identifiable {
    case system, light, dark

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    var systemImage: String {
        switch self {
        case .system: return "iphone"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }

    /// The SwiftUI color scheme to force, or `nil` to follow the system.
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

extension View {
    /// Standard floating card treatment used throughout the app.
    func paintCard(padding: CGFloat = 18, radius: CGFloat = Theme.cardRadius) -> some View {
        self
            .padding(padding)
            .background(Theme.surface, in: .rect(cornerRadius: radius))
            .overlay(
                RoundedRectangle(cornerRadius: radius)
                    .stroke(Theme.hairline, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.04), radius: 16, x: 0, y: 8)
    }
}

/// Reusable purple hero card background: vivid gradient, a warm top sheen,
/// and soft blurred lavender orbs for depth.
struct HeroBackground: View {
    var body: some View {
        ZStack {
            Theme.heroGradient
            LinearGradient(
                colors: [.white.opacity(0.14), .clear],
                startPoint: .top,
                endPoint: UnitPoint(x: 0.5, y: 0.55)
            )
            Circle()
                .fill(.white.opacity(0.10))
                .frame(width: 240, height: 240)
                .blur(radius: 2)
                .offset(x: 140, y: -110)
            Circle()
                .fill(Theme.brandBright.opacity(0.45))
                .frame(width: 170, height: 170)
                .blur(radius: 10)
                .offset(x: 120, y: 120)
            Circle()
                .fill(Color(red: 0.83, green: 0.74, blue: 0.97).opacity(0.28))
                .frame(width: 130, height: 130)
                .blur(radius: 12)
                .offset(x: -130, y: 95)
        }
    }
}
