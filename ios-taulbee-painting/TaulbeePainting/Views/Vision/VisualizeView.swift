//
//  VisualizeView.swift
//  TaulbeePainting
//
//  Pick the surface to repaint, run the one-time AI surface detection, then
//  jump into the live painting canvas. If detection can't find the surface,
//  the canvas quietly falls back to classic AI renders.
//

import SwiftUI

struct VisualizeView: View {
    let image: UIImage

    @State private var target: PaintTarget = .interiorWalls
    @State private var isDetecting = false
    @State private var session: LivePaintSession?

    private let maskService = SurfaceMaskService()

    var body: some View {
        ZStack {
            Theme.canvas.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    photoCard
                    targetSection
                    howItWorks
                    Color.clear.frame(height: 90)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }

            VStack {
                Spacer()
                startBar
            }

            if isDetecting {
                PaintingOverlay(
                    color: Theme.brand,
                    title: "Detecting \(target.label.lowercased())…",
                    subtitle: "One-time setup — after this, colors apply instantly"
                )
                .transition(.opacity)
            }
        }
        .navigationTitle("Visualize")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $session) { session in
            LivePaintView(session: session)
        }
        .animation(.easeInOut(duration: 0.25), value: isDetecting)
        .task { await PaintColorCatalog.shared.loadIfNeeded() }
    }

    // MARK: Sections

    private var photoCard: some View {
        Color(.secondarySystemBackground)
            .frame(height: 230)
            .overlay {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .allowsHitTesting(false)
            }
            .clipShape(.rect(cornerRadius: Theme.cardRadius))
            .overlay(RoundedRectangle(cornerRadius: Theme.cardRadius).stroke(Theme.hairline, lineWidth: 1))
    }

    private var targetSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel(icon: "scope", title: "What should we repaint?")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(PaintTarget.allCases) { t in
                        TargetChip(target: t, isOn: target == t) {
                            Haptics.tap()
                            target = t
                        }
                    }
                }
            }
            .scrollClipDisabled()
        }
    }

    private var howItWorks: some View {
        VStack(alignment: .leading, spacing: 14) {
            stepRow(
                number: 1,
                icon: "viewfinder",
                title: "One-time detection",
                text: "We find \(target.promptPhrase) in your photo."
            )
            stepRow(
                number: 2,
                icon: "paintpalette.fill",
                title: "Instant color try-ons",
                text: "Tap any of 7,700+ real Sherwin-Williams, Benjamin Moore & PPG colors — the photo repaints immediately."
            )
            stepRow(
                number: 3,
                icon: "sparkles",
                title: "HD render when you're ready",
                text: "Love one? Get a photorealistic AI version to save and share."
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .paintCard()
    }

    private func stepRow(number: Int, icon: String, title: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Theme.lavender)
                    .frame(width: 38, height: 38)
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.brand)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14.5, weight: .bold))
                    .foregroundStyle(Theme.ink)
                Text(text)
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(Theme.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var startBar: some View {
        PrimaryButton(title: "Start Painting", systemImage: "paintbrush.pointed.fill") {
            startPainting()
        }
        .disabled(isDetecting)
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(
            LinearGradient(colors: [Theme.canvas.opacity(0), Theme.canvas], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        )
    }

    // MARK: Detection

    private func startPainting() {
        guard !isDetecting else { return }
        isDetecting = true
        Task {
            let base = ImageResizer.normalizedUpright(image)
            var engine: RecolorEngine?
            do {
                let mask = try await maskService.detectSurface(in: base, target: target)
                engine = try await Task.detached(priority: .userInitiated) {
                    try RecolorEngine(photo: base, mask: mask)
                }.value
                Haptics.success()
            } catch {
                // Quiet fallback: the canvas will use classic AI renders instead.
                engine = nil
            }
            isDetecting = false
            session = LivePaintSession(base: base, target: target, engine: engine)
        }
    }
}

// MARK: - Target chip

struct TargetChip: View {
    let target: PaintTarget
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: target.systemImage)
                    .font(.system(size: 14, weight: .semibold))
                Text(target.label)
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundStyle(isOn ? .white : Theme.ink)
            .padding(.horizontal, 14)
            .frame(height: 44)
            .background {
                if isOn { Theme.brandGradient } else { Theme.surface }
            }
            .clipShape(.capsule)
            .overlay(Capsule().stroke(isOn ? Color.clear : Theme.hairline, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Painting overlay

struct PaintingOverlay: View {
    let color: Color
    var title: String = "Painting your preview…"
    var subtitle: String = "This usually takes a few seconds"

    @State private var sweep: CGFloat = -1
    @State private var pulse = false

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(color)
                        .frame(width: 96, height: 96)
                        .scaleEffect(pulse ? 1.05 : 0.92)
                        .shadow(color: color.opacity(0.5), radius: 20)
                    Image(systemName: "paintbrush.fill")
                        .font(.system(size: 38, weight: .bold))
                        .foregroundStyle(.white)
                        .rotationEffect(.degrees(sweep * 12))
                }
                Text(title)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Theme.ink)
                Text(subtitle)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.inkSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                pulse = true
            }
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                sweep = 1
            }
        }
    }
}
