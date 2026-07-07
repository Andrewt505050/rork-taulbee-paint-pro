//
//  LivePaintView.swift
//  TaulbeePainting
//
//  The live painting canvas: photo up top, surface chips and a swipeable
//  color strip along the bottom. Paint several surfaces at once — each chip
//  holds its own color — with instant on-device recolors on every tap,
//  hold-to-compare, and an on-demand HD photorealistic render of the whole
//  scheme.
//

import SwiftUI

/// Hand-off from the detection step into the live canvas.
struct LivePaintSession: Identifiable, Hashable {
    let id = UUID()
    let base: UIImage
    let target: PaintTarget
    /// Shared instant-recolor engine with the first surface prepared, or nil
    /// when detection failed and the canvas starts with classic AI renders.
    let engine: RecolorEngine?

    static func == (lhs: LivePaintSession, rhs: LivePaintSession) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

/// A finished preview headed to the result screen.
struct PaintPreviewResult: Identifiable, Hashable {
    let id = UUID()
    let image: UIImage
    let paints: [SurfacePaint]

    static func == (lhs: PaintPreviewResult, rhs: PaintPreviewResult) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

struct LivePaintView: View {
    let session: LivePaintSession

    @State private var engine: RecolorEngine?
    @State private var surfaces: [PaintTarget]
    @State private var selectedTarget: PaintTarget
    /// Surfaces with a prepared instant-recolor layer in the engine.
    @State private var instantTargets: Set<PaintTarget>
    /// The color assigned to each painted surface.
    @State private var assignments: [PaintTarget: PaintColor] = [:]
    @State private var preview: UIImage?
    @State private var isHDPreview = false
    @State private var hdCache: [String: UIImage] = [:]
    @State private var showOriginal = false
    @State private var isRenderingHD = false
    @State private var detectingTarget: PaintTarget?
    @State private var showLibrary = false
    @State private var recentPicks: [PaintColor] = []
    @State private var finalResult: PaintPreviewResult?
    @State private var errorMessage: String?
    @State private var renderTask: Task<Void, Never>?
    @State private var renderGeneration = 0

    private let maskService = SurfaceMaskService()
    private let hdService = ColorVisualizerService()

    init(session: LivePaintSession) {
        self.session = session
        _engine = State(initialValue: session.engine)
        _surfaces = State(initialValue: [session.target])
        _selectedTarget = State(initialValue: session.target)
        _instantTargets = State(initialValue: session.engine != nil ? [session.target] : [])
    }

    // MARK: Derived state

    private var selectedColor: PaintColor? { assignments[selectedTarget] }

    /// True when the selected surface repaints instantly on-device.
    private var selectedIsInstant: Bool { instantTargets.contains(selectedTarget) }

    private var remainingTargets: [PaintTarget] {
        PaintTarget.allCases.filter { !surfaces.contains($0) }
    }

    /// All painted surfaces in chip order, ready for HD renders and results.
    private var orderedPaints: [SurfacePaint] {
        surfaces.compactMap { target in
            assignments[target].map { SurfacePaint(target: target, color: $0) }
        }
    }

    /// Stable key for the current color scheme, used for the HD cache.
    private var assignmentSignature: String {
        assignments
            .sorted { $0.key.zOrder < $1.key.zOrder }
            .map { "\($0.key.rawValue)=\($0.value.id)" }
            .joined(separator: "|")
    }

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
            if let detectingTarget {
                PaintingOverlay(
                    color: Theme.brand,
                    title: "Detecting \(detectingTarget.label.lowercased())…",
                    subtitle: "One-time setup for this surface"
                )
                .transition(.opacity)
            }
        }
        .navigationTitle("Live Paint")
        .navigationBarTitleDisplayMode(.inline)
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
                paints: result.paints
            )
        }
        .alert("Heads up", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        .animation(.easeInOut(duration: 0.25), value: isRenderingHD)
        .animation(.easeInOut(duration: 0.25), value: detectingTarget)
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
        .overlay(alignment: .topLeading) { schemeChip.padding(10) }
        .overlay(alignment: .bottomTrailing) { compareBadge.padding(10) }
        .onLongPressGesture(minimumDuration: .infinity) {
        } onPressingChanged: { pressing in
            guard preview != nil else { return }
            showOriginal = pressing
        }
    }

    /// Floating legend of every painted surface and its color.
    @ViewBuilder
    private var schemeChip: some View {
        if !orderedPaints.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                ForEach(orderedPaints) { paint in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(paint.color.color)
                            .frame(width: 17, height: 17)
                            .overlay(Circle().stroke(.white.opacity(0.85), lineWidth: 1.3))
                        Text(paint.target.shortLabel)
                            .font(.system(size: 10, weight: .heavy))
                            .foregroundStyle(Theme.inkSecondary)
                            .textCase(.uppercase)
                        Text(paint.color.name)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Theme.ink)
                            .lineLimit(1)
                    }
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
            .padding(.vertical, 9)
            .background(.thinMaterial, in: .rect(cornerRadius: 14))
            .frame(maxWidth: 230, alignment: .leading)
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
        VStack(spacing: 11) {
            hintRow
            surfaceChips
            colorStrip
            actionRow
        }
        .padding(.top, 13)
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
            if assignments.isEmpty {
                Label(
                    selectedIsInstant
                        ? "Tap any color to paint the \(selectedTarget.shortLabel.lowercased()) instantly"
                        : "Pick a color, then tap Render Preview",
                    systemImage: selectedIsInstant ? "sparkles" : "wand.and.stars"
                )
            } else if !selectedIsInstant, selectedColor != nil, !isHDPreview {
                Label("\(selectedTarget.shortLabel) previews with the HD render", systemImage: "info.circle")
            } else if !remainingTargets.isEmpty {
                Label("Tap + to paint another surface in its own color", systemImage: "plus.circle.fill")
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

    // MARK: Surface chips

    private var surfaceChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(surfaces) { target in
                    SurfaceChip(
                        target: target,
                        color: assignments[target],
                        isSelected: target == selectedTarget
                    ) {
                        Haptics.tap()
                        selectedTarget = target
                    }
                    .contextMenu {
                        if assignments[target] != nil {
                            Button {
                                clearColor(for: target)
                            } label: {
                                Label("Clear Color", systemImage: "slash.circle")
                            }
                        }
                        if surfaces.count > 1 {
                            Button(role: .destructive) {
                                removeSurface(target)
                            } label: {
                                Label("Remove Surface", systemImage: "trash")
                            }
                        }
                    }
                }
                if !remainingTargets.isEmpty {
                    addSurfaceChip
                }
            }
            .padding(.vertical, 2)
        }
        .contentMargins(.horizontal, 16)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: surfaces)
    }

    private var addSurfaceChip: some View {
        Menu {
            ForEach(remainingTargets) { target in
                Button {
                    addSurface(target)
                } label: {
                    Label(target.label, systemImage: target.systemImage)
                }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .bold))
                Text("Add Surface")
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(Theme.brand)
            .padding(.horizontal, 13)
            .frame(height: 44)
            .background(Theme.brand.opacity(0.10), in: .capsule)
            .overlay(
                Capsule()
                    .stroke(Theme.brand.opacity(0.35), style: StrokeStyle(lineWidth: 1.2, dash: [4, 3]))
            )
        }
        .disabled(detectingTarget != nil || isRenderingHD)
    }

    // MARK: Color strip

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
                if selectedColor != nil {
                    clearTile
                }
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
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: selectedColor == nil)
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

    /// Returns the selected surface to its original, unpainted state.
    private var clearTile: some View {
        Button {
            clearColor(for: selectedTarget)
        } label: {
            VStack(spacing: 6) {
                Image(systemName: "slash.circle")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Theme.inkSecondary)
                    .frame(width: 54, height: 54)
                    .background(Theme.canvasDeep, in: .circle)
                    .overlay(Circle().stroke(Theme.hairline, lineWidth: 1.5))
                    .frame(width: 62, height: 62)
                Text("Clear")
                    .font(.system(size: 10.5, weight: .semibold))
                    .foregroundStyle(Theme.inkSecondary)
                    .lineLimit(1)
            }
            .frame(width: 66)
        }
        .buttonStyle(ScaleButtonStyle(scale: 0.92))
        .transition(.opacity.combined(with: .scale(scale: 0.8)))
    }

    // MARK: Action row

    private var hdDisabled: Bool {
        orderedPaints.isEmpty || isRenderingHD || isHDPreview
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
                    Text(orderedPaints.count > 1 ? "Use This Scheme" : "Use This Color")
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
                    Text(instantTargets.isEmpty ? "Render Preview" : "HD Render")
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

    // MARK: Actions

    /// Assigns a color to the selected surface and refreshes the composite.
    private func apply(_ color: PaintColor) {
        Haptics.tap()
        assignments[selectedTarget] = color
        refreshPreview()
    }

    private func clearColor(for target: PaintTarget) {
        Haptics.tap()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            _ = assignments.removeValue(forKey: target)
        }
        refreshPreview()
    }

    private func removeSurface(_ target: PaintTarget) {
        guard surfaces.count > 1 else { return }
        Haptics.tap()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            surfaces.removeAll { $0 == target }
            _ = assignments.removeValue(forKey: target)
            if selectedTarget == target, let first = surfaces.first {
                selectedTarget = first
            }
        }
        refreshPreview()
    }

    /// Adds a surface to the canvas, running its one-time detection if the
    /// engine hasn't prepared it before. Detected layers are kept, so
    /// re-adding a removed surface is instant.
    private func addSurface(_ target: PaintTarget) {
        guard !surfaces.contains(target), detectingTarget == nil, !isRenderingHD else { return }
        Haptics.tap()

        if instantTargets.contains(target) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                surfaces.append(target)
                selectedTarget = target
            }
            return
        }

        detectingTarget = target
        Task {
            do {
                let engine = try ensureEngine()
                let mask = try await maskService.detectSurface(in: session.base, target: target)
                try await engine.addSurface(target, mask: mask)
                instantTargets.insert(target)
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    surfaces.append(target)
                    selectedTarget = target
                }
                Haptics.success()
            } catch {
                errorMessage = "We couldn't find \(target.label.lowercased()) in this photo, so it wasn't added. Try a photo where it's clearly visible."
            }
            detectingTarget = nil
        }
    }

    private func ensureEngine() throws -> RecolorEngine {
        if let engine { return engine }
        let built = try RecolorEngine(photo: session.base)
        engine = built
        return built
    }

    /// Re-composites the preview from the current assignments: cached HD if
    /// the exact scheme was rendered before, otherwise an instant GPU pass.
    private func refreshPreview() {
        renderTask?.cancel()

        if let cached = hdCache[assignmentSignature] {
            preview = cached
            isHDPreview = true
            return
        }
        isHDPreview = false

        let instant = assignments.filter { instantTargets.contains($0.key) }
        guard let engine, !instant.isEmpty else {
            preview = nil
            return
        }

        renderGeneration += 1
        let generation = renderGeneration
        let hexes = instant.mapValues { $0.hex }
        renderTask = Task {
            guard let rendered = await engine.render(hexes) else { return }
            guard !Task.isCancelled, generation == renderGeneration else { return }
            preview = rendered
        }
    }

    /// One photorealistic AI pass covering every painted surface.
    private func renderHD() {
        let plan = orderedPaints
        guard !plan.isEmpty, !isRenderingHD else { return }
        let signature = assignmentSignature
        isRenderingHD = true
        Task {
            do {
                let rendered = try await hdService.repaint(image: session.base, plan: plan)
                hdCache[signature] = rendered
                if assignmentSignature == signature {
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
        guard let preview, !orderedPaints.isEmpty else { return }
        finalResult = PaintPreviewResult(image: preview, paints: orderedPaints)
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

// MARK: - Surface chip

/// One paintable surface on the canvas: name, icon, and a dot showing its
/// assigned color (dashed when unpainted).
struct SurfaceChip: View {
    let target: PaintTarget
    let color: PaintColor?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 7) {
                Image(systemName: target.systemImage)
                    .font(.system(size: 12, weight: .semibold))
                Text(target.shortLabel)
                    .font(.system(size: 13.5, weight: .bold))
                if let color {
                    Circle()
                        .fill(color.color)
                        .frame(width: 15, height: 15)
                        .overlay(
                            Circle().stroke(
                                isSelected ? .white.opacity(0.9) : Theme.hairline,
                                lineWidth: 1.3
                            )
                        )
                } else {
                    Circle()
                        .stroke(
                            isSelected ? Color.white.opacity(0.65) : Theme.inkSecondary.opacity(0.45),
                            style: StrokeStyle(lineWidth: 1.3, dash: [2.5, 2.2])
                        )
                        .frame(width: 15, height: 15)
                }
            }
            .foregroundStyle(isSelected ? .white : Theme.ink)
            .padding(.horizontal, 13)
            .frame(height: 44)
            .background {
                if isSelected { Theme.brandGradient } else { Theme.canvasDeep }
            }
            .clipShape(.capsule)
            .overlay(Capsule().stroke(isSelected ? Color.clear : Theme.hairline, lineWidth: 1))
        }
        .buttonStyle(ScaleButtonStyle(scale: 0.94))
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
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
