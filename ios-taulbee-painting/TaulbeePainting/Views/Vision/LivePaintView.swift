//
//  LivePaintView.swift
//  TaulbeePainting
//
//  The live painting canvas: photo up top, a swipeable color strip along the
//  bottom, instant on-device recolors on every tap, hold-to-compare, surface
//  switching, and an on-demand HD photorealistic render.
//

import SwiftUI

/// Hand-off from the detection step into the live canvas.
struct LivePaintSession: Identifiable, Hashable {
    let id = UUID()
    let base: UIImage
    let target: PaintTarget
    /// Prepared instant-recolor engine, or nil to use classic AI renders.
    let engine: RecolorEngine?

    static func == (lhs: LivePaintSession, rhs: LivePaintSession) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

/// A finished preview headed to the result screen.
struct PaintPreviewResult: Identifiable, Hashable {
    let id = UUID()
    let image: UIImage
    let color: PaintColor?
    let target: PaintTarget

    static func == (lhs: PaintPreviewResult, rhs: PaintPreviewResult) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

struct LivePaintView: View {
    let session: LivePaintSession

    @State private var target: PaintTarget
    @State private var engines: [PaintTarget: RecolorEngine]
    @State private var classicTargets: Set<PaintTarget>
    @State private var selectedColor: PaintColor?
    @State private var preview: UIImage?
    @State private var isHDPreview = false
    @State private var hdCache: [String: UIImage] = [:]
    @State private var showOriginal = false
    @State private var isRenderingHD = false
    @State private var isDetecting = false
    @State private var showLibrary = false
    @State private var recentPicks: [PaintColor] = []
    @State private var finalResult: PaintPreviewResult?
    @State private var errorMessage: String?
    @State private var renderTask: Task<Void, Never>?

    private let maskService = SurfaceMaskService()
    private let hdService = ColorVisualizerService()

    init(session: LivePaintSession) {
        self.session = session
        _target = State(initialValue: session.target)
        var engines: [PaintTarget: RecolorEngine] = [:]
        var classic: Set<PaintTarget> = []
        if let engine = session.engine {
            engines[session.target] = engine
        } else {
            classic.insert(session.target)
        }
        _engines = State(initialValue: engines)
        _classicTargets = State(initialValue: classic)
    }

    /// True when the current surface has a prepared instant engine.
    private var isInstant: Bool { engines[target] != nil }

    var body: some View {
        ZStack {
            Theme.canvas.ignoresSafeArea()
            VStack(spacing: 0) {
                photoStage
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .frame(maxHeight: .infinity)
                bottomPanel
            }

            if isRenderingHD {
                PaintingOverlay(color: selectedColor?.color ?? Theme.brand)
                    .transition(.opacity)
            }
            if isDetecting {
                PaintingOverlay(
                    color: Theme.brand,
                    title: "Detecting \(target.label.lowercased())…",
                    subtitle: "One-time setup for this surface"
                )
                .transition(.opacity)
            }
        }
        .navigationTitle("Live Paint")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { surfaceMenu }
        .sheet(isPresented: $showLibrary) {
            ColorLibraryView { color in
                remember(color)
                apply(color)
            }
        }
        .navigationDestination(item: $finalResult) { result in
            VisionResultView(
                original: session.base,
                result: result.image,
                color: result.color,
                target: result.target
            )
        }
        .alert("Couldn't render preview", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        .animation(.easeInOut(duration: 0.25), value: isRenderingHD)
        .animation(.easeInOut(duration: 0.25), value: isDetecting)
        .task { await PaintColorCatalog.shared.loadIfNeeded() }
    }

    // MARK: Photo stage

    private var imageAspect: CGFloat {
        let size = session.base.size
        return size.height > 0 ? size.width / size.height : 1
    }

    private var photoStage: some View {
        ZStack {
            Image(uiImage: session.base)
                .resizable()
            if let preview, !showOriginal {
                Image(uiImage: preview)
                    .resizable()
                    .transition(.opacity)
            }
        }
        .aspectRatio(imageAspect, contentMode: .fit)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.easeInOut(duration: 0.18), value: preview)
        .animation(.easeInOut(duration: 0.12), value: showOriginal)
        .clipShape(.rect(cornerRadius: 24))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Theme.hairline, lineWidth: 1))
        .shadow(color: .black.opacity(0.10), radius: 18, y: 10)
        .overlay(alignment: .topLeading) { colorChip.padding(10) }
        .overlay(alignment: .bottomTrailing) { compareBadge.padding(10) }
        .onLongPressGesture(minimumDuration: .infinity) {
        } onPressingChanged: { pressing in
            guard preview != nil else { return }
            showOriginal = pressing
        }
    }

    @ViewBuilder
    private var colorChip: some View {
        if let color = selectedColor {
            HStack(spacing: 9) {
                Circle()
                    .fill(color.color)
                    .frame(width: 24, height: 24)
                    .overlay(Circle().stroke(.white.opacity(0.85), lineWidth: 1.5))
                VStack(alignment: .leading, spacing: 1) {
                    Text(color.name)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Theme.ink)
                        .lineLimit(1)
                    Text(color.displayCode)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Theme.inkSecondary)
                }
                if isHDPreview {
                    Text("HD")
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Theme.brand, in: .capsule)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.thinMaterial, in: .rect(cornerRadius: 14))
            .transition(.opacity.combined(with: .scale(scale: 0.9, anchor: .topLeading)))
        }
    }

    @ViewBuilder
    private var compareBadge: some View {
        if preview != nil {
            Label(showOriginal ? "Original" : "Hold to compare", systemImage: "eye")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Theme.ink)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.thinMaterial, in: .capsule)
        }
    }

    // MARK: Bottom panel

    private var bottomPanel: some View {
        VStack(spacing: 12) {
            hintRow
            colorStrip
            actionRow
        }
        .padding(.top, 14)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity)
        .background {
            UnevenRoundedRectangle(topLeadingRadius: 26, topTrailingRadius: 26)
                .fill(Theme.surface)
                .ignoresSafeArea(edges: .bottom)
                .shadow(color: .black.opacity(0.08), radius: 16, y: -6)
        }
        .padding(.top, 12)
    }

    private var hintRow: some View {
        Group {
            if selectedColor == nil {
                Label(
                    isInstant
                        ? "Tap any color — your \(target.label.lowercased()) repaint instantly"
                        : "Pick a color, then tap Render Preview",
                    systemImage: isInstant ? "sparkles" : "wand.and.stars"
                )
            } else if !isInstant && !isHDPreview {
                Label("Instant preview unavailable here — tap Render Preview", systemImage: "info.circle")
            } else {
                Label(
                    "\(PaintColorCatalog.shared.all.count.formatted()) real colors — swipe or open the library",
                    systemImage: "paintpalette.fill"
                )
            }
        }
        .font(.system(size: 12, weight: .semibold))
        .foregroundStyle(Theme.inkSecondary)
        .lineLimit(1)
        .minimumScaleFactor(0.8)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
    }

    private var stripColors: [PaintColor] {
        var seen = Set<String>()
        var colors: [PaintColor] = []
        for color in recentPicks + PaintColorCatalog.shared.popular {
            if seen.insert(color.id).inserted {
                colors.append(color)
            }
        }
        return colors
    }

    private var colorStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                libraryTile
                ForEach(stripColors) { color in
                    StripSwatch(
                        color: color,
                        isSelected: selectedColor?.id == color.id
                    ) {
                        apply(color)
                    }
                }
            }
            .padding(.vertical, 2)
        }
        .contentMargins(.horizontal, 16)
    }

    private var libraryTile: some View {
        Button {
            Haptics.tap()
            showLibrary = true
        } label: {
            VStack(spacing: 6) {
                Image(systemName: "square.grid.3x3.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Theme.brand)
                    .frame(width: 54, height: 54)
                    .background(Theme.lavender, in: .circle)
                    .overlay(Circle().stroke(Theme.brand.opacity(0.35), lineWidth: 1.5))
                    .frame(width: 62, height: 62)
                Text("All Colors")
                    .font(.system(size: 10.5, weight: .semibold))
                    .foregroundStyle(Theme.inkSecondary)
                    .lineLimit(1)
            }
            .frame(width: 66)
        }
        .buttonStyle(ScaleButtonStyle(scale: 0.92))
    }

    private var hdDisabled: Bool {
        selectedColor == nil || isRenderingHD || isHDPreview
    }

    private var actionRow: some View {
        HStack(spacing: 12) {
            Button {
                Haptics.tap()
                continueToResult()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 15, weight: .semibold))
                    Text("Use This Color")
                        .font(.system(size: 15.5, weight: .bold))
                }
                .foregroundStyle(Theme.brand)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Theme.brand.opacity(0.10), in: .rect(cornerRadius: 15))
            }
            .buttonStyle(.plain)
            .disabled(preview == nil)
            .opacity(preview == nil ? 0.45 : 1)

            Button {
                Haptics.tap()
                renderHD()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 15, weight: .semibold))
                    Text(isInstant ? "HD Render" : "Render Preview")
                        .font(.system(size: 15.5, weight: .bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Theme.brandGradient, in: .rect(cornerRadius: 15))
                .shadow(color: Theme.brand.opacity(0.30), radius: 10, y: 5)
            }
            .buttonStyle(.plain)
            .disabled(hdDisabled)
            .opacity(hdDisabled ? 0.45 : 1)
        }
        .padding(.horizontal, 16)
    }

    // MARK: Toolbar

    @ToolbarContentBuilder
    private var surfaceMenu: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                ForEach(PaintTarget.allCases) { option in
                    Button {
                        switchTarget(option)
                    } label: {
                        if option == target {
                            Label(option.label, systemImage: "checkmark")
                        } else {
                            Label(option.label, systemImage: option.systemImage)
                        }
                    }
                }
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: target.systemImage)
                        .font(.system(size: 12, weight: .semibold))
                    Text(target.label)
                        .font(.system(size: 13, weight: .semibold))
                }
            }
        }
    }

    // MARK: Actions

    private func cacheKey(for color: PaintColor) -> String {
        "\(target.rawValue)|\(color.id)"
    }

    /// Applies a color: instant GPU recolor when the engine is ready,
    /// otherwise selects it for a classic AI render.
    private func apply(_ color: PaintColor) {
        Haptics.tap()
        selectedColor = color

        if let cached = hdCache[cacheKey(for: color)] {
            preview = cached
            isHDPreview = true
            return
        }
        isHDPreview = false

        guard let engine = engines[target] else {
            preview = nil
            return
        }
        renderTask?.cancel()
        let requestedID = color.id
        renderTask = Task {
            guard let rendered = await engine.render(hex: color.hex) else { return }
            guard !Task.isCancelled, selectedColor?.id == requestedID else { return }
            preview = rendered
        }
    }

    private func renderHD() {
        guard let color = selectedColor, !isRenderingHD else { return }
        isRenderingHD = true
        Task {
            do {
                let rendered = try await hdService.repaint(image: session.base, color: color, target: target)
                hdCache[cacheKey(for: color)] = rendered
                if selectedColor?.id == color.id {
                    preview = rendered
                    isHDPreview = true
                }
                Haptics.success()
            } catch {
                errorMessage = (error as? LocalizedError)?.errorDescription ?? "Please try again."
            }
            isRenderingHD = false
        }
    }

    private func continueToResult() {
        guard let color = selectedColor, let preview else { return }
        finalResult = PaintPreviewResult(image: preview, color: color, target: target)
    }

    /// Switches the paintable surface, detecting it once if needed.
    private func switchTarget(_ newTarget: PaintTarget) {
        guard newTarget != target, !isDetecting, !isRenderingHD else { return }
        Haptics.tap()
        target = newTarget
        isHDPreview = false
        preview = nil

        if engines[newTarget] != nil || classicTargets.contains(newTarget) {
            reapplySelection()
            return
        }
        isDetecting = true
        Task {
            do {
                let mask = try await maskService.detectSurface(in: session.base, target: newTarget)
                let engine = try await Task.detached(priority: .userInitiated) { [base = session.base] in
                    try RecolorEngine(photo: base, mask: mask)
                }.value
                engines[newTarget] = engine
                Haptics.success()
            } catch {
                classicTargets.insert(newTarget)
            }
            isDetecting = false
            reapplySelection()
        }
    }

    private func reapplySelection() {
        if let color = selectedColor {
            apply(color)
        }
    }

    /// Keeps library picks at the front of the strip.
    private func remember(_ color: PaintColor) {
        recentPicks.removeAll { $0.id == color.id }
        recentPicks.insert(color, at: 0)
        if recentPicks.count > 12 {
            recentPicks.removeLast()
        }
    }
}

// MARK: - Strip swatch

struct StripSwatch: View {
    let color: PaintColor
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(color.color)
                        .frame(width: 54, height: 54)
                        .overlay(Circle().stroke(Theme.hairline, lineWidth: 1))
                    if isSelected {
                        Circle()
                            .stroke(Theme.brand, lineWidth: 3)
                            .frame(width: 61, height: 61)
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .heavy))
                            .foregroundStyle(color.prefersDarkText ? .black.opacity(0.65) : .white)
                    }
                }
                .frame(width: 64, height: 64)
                Text(color.name)
                    .font(.system(size: 10.5, weight: .semibold))
                    .foregroundStyle(isSelected ? Theme.ink : Theme.inkSecondary)
                    .lineLimit(1)
            }
            .frame(width: 66)
        }
        .buttonStyle(ScaleButtonStyle(scale: 0.9))
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}
