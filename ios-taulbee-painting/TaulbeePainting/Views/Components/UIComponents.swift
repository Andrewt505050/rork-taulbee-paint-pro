//
//  UIComponents.swift
//  TaulbeePainting
//
//  Small reusable building blocks: buttons, gauge, confidence bar, chips.
//

import SwiftUI

// MARK: - Press feedback

/// Shared springy press-scale feedback for tappable cards and buttons.
struct ScaleButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.97

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Primary button

struct PrimaryButton: View {
    let title: String
    let systemImage: String
    var fill: Bool = true
    let action: () -> Void

    @State private var pressed = false

    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.system(size: 17, weight: .semibold))
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .foregroundStyle(fill ? Color.white : Theme.brand)
            .background {
                if fill {
                    Theme.brandGradient
                } else {
                    Theme.brand.opacity(0.10)
                }
            }
            .clipShape(.rect(cornerRadius: 16))
            .shadow(color: fill ? Theme.brand.opacity(0.30) : .clear, radius: 12, x: 0, y: 6)
        }
        .buttonStyle(.plain)
        .scaleEffect(pressed ? 0.97 : 1)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: pressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in pressed = true }
                .onEnded { _ in pressed = false }
        )
    }
}

// MARK: - Severity gauge

struct SeverityGauge: View {
    let severity: Severity
    var animate: Bool = true

    @State private var progress: CGFloat = 0

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .stroke(Theme.canvasDeep, lineWidth: 12)
                Circle()
                    .trim(from: 0, to: progress * CGFloat(severity.gaugeFraction))
                    .stroke(
                        AngularGradient(
                            colors: [severity.color.opacity(0.7), severity.color],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 2) {
                    Image(systemName: severity.systemImage)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(severity.color)
                    Text(severity.label)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Theme.ink)
                }
            }
            .frame(width: 104, height: 104)

            Text(severity.blurb)
                .font(.system(size: 12.5, weight: .medium))
                .foregroundStyle(Theme.inkSecondary)
                .multilineTextAlignment(.center)
        }
        .onAppear {
            if animate {
                withAnimation(.spring(response: 0.9, dampingFraction: 0.8).delay(0.1)) {
                    progress = 1
                }
            } else {
                progress = 1
            }
        }
    }
}

// MARK: - Confidence bar

struct ConfidenceBar: View {
    let value: Double // 0...1
    @State private var fill: CGFloat = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Confidence")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.inkSecondary)
                Spacer()
                Text("\(Int((value * 100).rounded()))%")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Theme.brand)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.canvasDeep)
                    Capsule()
                        .fill(Theme.brandGradient)
                        .frame(width: geo.size.width * fill)
                }
            }
            .frame(height: 9)
        }
        .onAppear {
            withAnimation(.spring(response: 0.9, dampingFraction: 0.85).delay(0.2)) {
                fill = CGFloat(max(0, min(1, value)))
            }
        }
    }
}

// MARK: - Section header

struct SectionLabel: View {
    let icon: String
    let title: String
    var tint: Color = Theme.brand

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(tint)
            Text(title)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Theme.ink)
        }
    }
}

// MARK: - Paint chip dots (decorative)

struct PaintChips: View {
    var colors: [Color] = [Theme.brand, Theme.accent, Severity.minor.color, Severity.moderate.color]
    var size: CGFloat = 12

    var body: some View {
        HStack(spacing: 6) {
            ForEach(Array(colors.enumerated()), id: \.offset) { _, color in
                RoundedRectangle(cornerRadius: 4)
                    .fill(color)
                    .frame(width: size, height: size)
            }
        }
    }
}
