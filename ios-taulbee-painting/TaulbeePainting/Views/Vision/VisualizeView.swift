//
//  VisualizeView.swift
//  TaulbeePainting
//
//  Pick a target surface and color for a chosen photo, then generate a
//  photorealistic repaint preview.
//

import SwiftUI

struct VisualizeView: View {
    let image: UIImage

    @State private var target: PaintTarget = .interiorWalls
    @State private var selectedColor: PaintColor?
    @State private var showLibrary = false
    @State private var isGenerating = false
    @State private var result: UIImage?
    @State private var errorMessage: String?

    private let service = ColorVisualizerService()

    var body: some View {
        ZStack {
            Theme.canvas.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    photoCard
                    targetSection
                    colorSection
                    Color.clear.frame(height: 90)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }

            VStack {
                Spacer()
                generateBar
            }

            if isGenerating {
                PaintingOverlay(color: selectedColor?.color ?? Theme.brand)
                    .transition(.opacity)
            }
        }
        .navigationTitle("Visualize")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showLibrary) {
            ColorLibraryView { color in selectedColor = color }
        }
        .navigationDestination(item: $result) { rendered in
            VisionResultView(
                original: image,
                result: rendered,
                color: selectedColor,
                target: target
            )
        }
        .alert("Couldn't render preview", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        .animation(.easeInOut(duration: 0.25), value: isGenerating)
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

    private var colorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel(icon: "paintpalette.fill", title: "Choose a color")
            Button {
                Haptics.tap()
                showLibrary = true
            } label: {
                HStack(spacing: 14) {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(selectedColor?.color ?? Theme.canvasDeep)
                        .frame(width: 54, height: 54)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.hairline, lineWidth: 1))
                        .overlay {
                            if selectedColor == nil {
                                Image(systemName: "plus")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundStyle(Theme.brand)
                            }
                        }
                    VStack(alignment: .leading, spacing: 3) {
                        Text(selectedColor?.name ?? "Browse paint library")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Theme.ink)
                        Text(selectedColor.map { "\($0.brand.displayName) · \($0.code)" } ?? "Sherwin-Williams, Benjamin Moore & PPG")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Theme.inkSecondary)
                            .lineLimit(1)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.inkSecondary.opacity(0.5))
                }
                .paintCard()
            }
            .buttonStyle(.plain)
        }
    }

    private var generateBar: some View {
        PrimaryButton(title: isGenerating ? "Painting…" : "Generate Preview", systemImage: "wand.and.stars") {
            generate()
        }
        .disabled(selectedColor == nil || isGenerating)
        .opacity(selectedColor == nil ? 0.55 : 1)
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(
            LinearGradient(colors: [Theme.canvas.opacity(0), Theme.canvas], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        )
    }

    private func generate() {
        guard let color = selectedColor, !isGenerating else { return }
        isGenerating = true
        Task {
            do {
                let rendered = try await service.repaint(image: image, color: color, target: target)
                Haptics.success()
                isGenerating = false
                result = rendered
            } catch {
                isGenerating = false
                errorMessage = (error as? LocalizedError)?.errorDescription ?? "Please try again."
            }
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
                Text("Painting your preview…")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Theme.ink)
                Text("This usually takes a few seconds")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.inkSecondary)
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
