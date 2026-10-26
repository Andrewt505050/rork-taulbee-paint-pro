//
//  SurfaceTapOverlay.swift
//  TaulbeePainting
//
//  Shared pieces for "tap the surface you mean": a tap catcher that reports
//  normalized photo coordinates, a pin marker, a prompt banner, and the brief
//  detected-area glow shown after detection.
//

import SwiftUI

/// Captures a tap over an aspect-fit photo and reports it as a normalized
/// point (0...1, origin top-left). Place it as an overlay on the photo view
/// so its bounds match the displayed image exactly.
struct SurfaceTapCatcher: View {
    let onTap: (CGPoint) -> Void

    var body: some View {
        GeometryReader { geo in
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { location in
                    guard geo.size.width > 0, geo.size.height > 0 else { return }
                    let point = CGPoint(
                        x: min(1, max(0, location.x / geo.size.width)),
                        y: min(1, max(0, location.y / geo.size.height))
                    )
                    onTap(point)
                }
        }
    }
}

/// A crosshair pin at a normalized point over the photo.
struct SurfacePin: View {
    let point: CGPoint
    var color: Color = Theme.brandBright

    @State private var appeared = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Circle()
                    .stroke(color.opacity(0.55), lineWidth: 2)
                    .frame(width: 38, height: 38)
                Circle()
                    .fill(.white)
                    .frame(width: 16, height: 16)
                    .shadow(color: .black.opacity(0.25), radius: 3, y: 1)
                Circle()
                    .fill(color)
                    .frame(width: 10, height: 10)
            }
            .scaleEffect(appeared ? 1 : 0.4)
            .position(x: point.x * geo.size.width, y: point.y * geo.size.height)
            .allowsHitTesting(false)
        }
        .onAppear {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) { appeared = true }
        }
    }
}

/// Floating instruction shown over the photo while a tap is expected.
struct TapPromptBanner: View {
    let text: String
    var onCancel: (() -> Void)? = nil

    @State private var pulse = false

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "hand.tap.fill")
                .font(.system(size: 13, weight: .bold))
                .scaleEffect(pulse ? 1.12 : 0.94)
            Text(text)
                .font(.system(size: 13, weight: .bold))
                .lineLimit(2)
                .minimumScaleFactor(0.8)
            if let onCancel {
                Button(action: onCancel) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white.opacity(0.75))
                }
                .buttonStyle(.plain)
            }
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Theme.brandGradient, in: .capsule)
        .shadow(color: Theme.brand.opacity(0.35), radius: 10, y: 4)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) { pulse = true }
        }
    }
}

/// The detected-area glow: a tinted overlay with a bright edge that fades
/// out after a moment.
struct DetectionGlow: View {
    let image: UIImage
    /// Changes whenever a new glow should play, even for the same image.
    let token: Int

    @State private var visible = false

    var body: some View {
        Image(uiImage: image)
            .resizable()
            .opacity(visible ? 1 : 0)
            .allowsHitTesting(false)
            .task(id: token) {
                visible = false
                withAnimation(.easeOut(duration: 0.18)) { visible = true }
                try? await Task.sleep(for: .seconds(1.3))
                withAnimation(.easeInOut(duration: 0.45)) { visible = false }
            }
    }
}
