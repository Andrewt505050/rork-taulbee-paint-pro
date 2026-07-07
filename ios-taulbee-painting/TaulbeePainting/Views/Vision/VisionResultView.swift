//
//  VisionResultView.swift
//  TaulbeePainting
//
//  Shows the before/after reveal and the complete color scheme — one card per
//  painted surface — and lets the customer save the project and send it to
//  Taulbee Painting.
//

import SwiftUI
import SwiftData

struct VisionResultView: View {
    let original: UIImage
    let result: UIImage
    let paints: [SurfacePaint]

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var notes = ""
    @State private var saved = false
    @State private var showShare = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                BeforeAfterSlider(before: original, after: result)
                    .frame(height: 300)
                    .clipShape(.rect(cornerRadius: Theme.cardRadius))
                    .overlay(RoundedRectangle(cornerRadius: Theme.cardRadius).stroke(Theme.hairline, lineWidth: 1))
                    .shadow(color: .black.opacity(0.08), radius: 16, y: 8)

                hint
                if !paints.isEmpty { schemeSection }
                notesCard
                actions
                Color.clear.frame(height: 12)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .background(Theme.canvas.ignoresSafeArea())
        .navigationTitle("Your Preview")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showShare) {
            ShareSheet(items: shareItems)
        }
    }

    private var hint: some View {
        Label("Drag the slider to compare before & after", systemImage: "hand.draw.fill")
            .font(.system(size: 12.5, weight: .semibold))
            .foregroundStyle(Theme.inkSecondary)
            .frame(maxWidth: .infinity)
    }

    private var schemeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if paints.count > 1 {
                SectionLabel(icon: "paintpalette.fill", title: "Your Color Scheme")
            }
            VStack(spacing: 12) {
                ForEach(paints) { paint in
                    colorCard(paint)
                }
            }
        }
    }

    private func colorCard(_ paint: SurfacePaint) -> some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 12)
                .fill(paint.color.color)
                .frame(width: 52, height: 52)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.hairline, lineWidth: 1))
            VStack(alignment: .leading, spacing: 3) {
                Text(paint.color.name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Theme.ink)
                Text("\(paint.color.brand.displayName) · \(paint.color.code) · #\(paint.color.hex)")
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(Theme.inkSecondary)
            }
            Spacer()
            VStack(spacing: 4) {
                Image(systemName: paint.target.systemImage)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.brand)
                Text(paint.target.label)
                    .font(.system(size: 10.5, weight: .semibold))
                    .foregroundStyle(Theme.inkSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .paintCard()
    }

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionLabel(icon: "square.and.pencil", title: "Notes for Taulbee")
            TextField("e.g. front living room, 2 coats, satin finish…", text: $notes, axis: .vertical)
                .font(.system(size: 15))
                .lineLimit(2...4)
                .padding(12)
                .background(Theme.surface, in: .rect(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.hairline, lineWidth: 1))
        }
    }

    private var actions: some View {
        VStack(spacing: 12) {
            PrimaryButton(title: saved ? "Saved to Projects" : "Save Project", systemImage: saved ? "checkmark.circle.fill" : "tray.and.arrow.down.fill") {
                save()
            }
            .disabled(saved)
            PrimaryButton(title: "Send to Taulbee", systemImage: "paperplane.fill", fill: false) {
                if !saved { save() }
                showShare = true
            }
        }
    }

    private var shareItems: [Any] {
        var text = "Taulbee Painting — Vision Tool project\n"
        if paints.count == 1, let paint = paints.first {
            text += "Color: \(paint.color.name) (\(paint.color.brand.displayName) \(paint.color.code), #\(paint.color.hex))\n"
            text += "Surface: \(paint.target.label)\n"
        } else {
            text += "Color scheme:\n"
            for paint in paints {
                text += "• \(paint.target.label): \(paint.color.name) (\(paint.color.brand.displayName) \(paint.color.code), #\(paint.color.hex))\n"
            }
        }
        if !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            text += "Notes: \(notes)\n"
        }
        text += "\nPlease send me a quote — \(BusinessInfo.website)"
        return [result, text]
    }

    private func save() {
        guard !saved, let first = paints.first else { return }
        let scheme = paints.map { paint in
            SavedSurfacePaint(
                surfaceLabel: paint.target.label,
                colorName: paint.color.name,
                colorCode: paint.color.code,
                colorBrand: paint.color.brand.displayName,
                colorHex: paint.color.hex
            )
        }
        let project = VisionProject(
            originalImageData: ImageResizer.storageJPEG(original),
            resultImageData: ImageResizer.storageJPEG(result),
            colorName: first.color.name,
            colorCode: first.color.code,
            colorBrand: first.color.brand.displayName,
            colorHex: first.color.hex,
            surfaceLabel: paints.map { $0.target.label }.joined(separator: " + "),
            notes: notes,
            schemeData: try? JSONEncoder().encode(scheme)
        )
        modelContext.insert(project)
        Haptics.success()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { saved = true }
    }
}
