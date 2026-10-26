//
//  VisualizeView.swift
//  TaulbeePainting
//
//  Pick the surface to repaint, tap it in the photo so detection knows
//  exactly which plane you mean, run the one-time AI surface detection, then
//  jump into the live painting canvas. If detection can't find the surface,
//  you can re-tap or continue with classic AI renders.
//

import SwiftUI

struct VisualizeView: View {
    let image: UIImage

    @State private var target: PaintTarget = .interiorWalls
    @State private var isDetecting = false
    @State private var session: LivePaintSession?
    /// Where the customer tapped the surface, normalized to the upright photo.
    @State private var hint: CGPoint?
    @State private var nudgePhoto = false
    @State private var notFoundMessage: String?

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
        .alert("Couldn't find that surface", isPresented: .constant(notFoundMessage != nil)) {
            Button("Tap Again") {
                notFoundMessage = nil
                hint = nil
            }
            Button("Continue with AI Renders") {
                notFoundMessage = nil
                session = LivePaintSession(base: ImageResizer.normalizedUpright(image), target: target, engine: nil)
            }
        } message: {
            Text(notFoundMessage ?? "")
        }
        .animation(.easeInOut(duration: 0.25), value: isDetecting)
        .task { await PaintColorCatalog.shared.loadIfNeeded() }
    }

    // MARK: Sections

    private var photoCard: some View {
        VStack(spacing: 10) {
            // The image is sized by the fixed-height container below, so every
            // overlay here matches the displayed photo bounds exactly.
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .overlay {
                    SurfaceTapCatcher { point in
                        Haptics.tap()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            hint = point
                        }
                    }
                }
                .overlay {
                    if let hint {
                        SurfacePin(point: hint)
                    }
                }
                .overlay(alignment: .top) {
                    if hint == nil {
                        TapPromptBanner(text: "Tap the \(target.shortLabel.lowercased()) in your photo")
                            .padding(.top, 12)
                            .padding(.horizontal, 12)
                            .scaleEffect(nudgePhoto ? 1.06 : 1)
                            .transition(.opacity.combined(with: .scale(scale: 0.9)))
                    }
                }
                .clipShape(.rect(cornerRadius: Theme.cardRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.cardRadius)
                        .stroke(nudgePhoto ? Theme.brandBright : Theme.hairline, lineWidth: nudgePhoto ? 2.5 : 1)
                )
                .animation(.easeInOut(duration: 0.2), value: hint == nil)
                .frame(maxWidth: .infinity)
                .frame(height: 320)

            HStack(spacing: 6) {
                Image(systemName: hint == nil ? "hand.tap" : "checkmark.circle.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(hint == nil ? Theme.inkSecondary : Theme.brand)
                Text(hint == nil
                     ? "Tap the middle of the \(target.shortLabel.lowercased()) so we outline the right surface."
                     : "Got it — we'll find the \(target.shortLabel.lowercased()) under your pin. Tap elsewhere to move it.")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)
        }
    }

    private var targetSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel(icon: "scope", title: "What should we repaint?")
            targetRow(title: "Interior", targets: PaintTarget.interiorCases)
            targetRow(title: "Exterior", targets: PaintTarget.exteriorCases)
            Text("You can add more surfaces once you start painting.")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Theme.inkSecondary)
        }
    }

    private func targetRow(title: String, targets: [PaintTarget]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .bold))
                .tracking(1.2)
                .foregroundStyle(Theme.inkSecondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(targets) { t in
                        TargetChip(target: t, isOn: target == t) {
                            Haptics.tap()
                            if target != t {
                                target = t
                                withAnimation(.easeInOut(duration: 0.2)) { hint = nil }
                            }
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
                text: "We find \(target.promptPhrase) in your photo, anchored to the spot you tap, and double-check the outline before painting."
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
        PrimaryButton(
            title: hint == nil ? "Tap the \(target.shortLabel) First" : "Start Painting",
            systemImage: hint == nil ? "hand.tap.fill" : "paintbrush.pointed.fill"
        ) {
            startPainting()
        }
        .opacity(hint == nil ? 0.7 : 1)
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
        guard let hint else {
            Haptics.warning()
            withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) { nudgePhoto = true }
            Task {
                try? await Task.sleep(for: .seconds(0.9))
                withAnimation(.easeOut(duration: 0.3)) { nudgePhoto = false }
            }
            return
        }
        isDetecting = true
        Task {
            let base = ImageResizer.normalizedUpright(image)
            var engine: RecolorEngine?
            do {
                let built = try RecolorEngine(photo: base)
                let mask = try await maskService.detectSurface(in: base, target: target, hint: hint)
                try await built.addSurface(target, mask: mask)
                engine = built
                Haptics.success()
            } catch VisualizerError.surfaceNotFound(let missing) {
                isDetecting = false
                Haptics.warning()
                notFoundMessage = VisualizerError.surfaceNotFound(missing).errorDescription
                return
            } catch {
                // Quiet fallback: the canvas will use classic AI renders instead.
                engine = nil
            }
            isDetecting = false
            session = LivePaintSession(base: base, target: target, engine: engine, hint: hint)
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
