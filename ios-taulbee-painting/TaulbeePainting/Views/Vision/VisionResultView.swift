//
//  VisionResultView.swift
//  TaulbeePainting
//
//  Shows the before/after reveal, color details, and lets the customer save
//  the project and send it to Taulbee Painting.
//

import SwiftUI
import SwiftData

struct VisionResultView: View {
    let original: UIImage
    let result: UIImage
    let color: PaintColor?
    let target: PaintTarget

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
                if let color { colorCard(color) }
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

    private func colorCard(_ color: PaintColor) -> some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 12)
                .fill(color.color)
                .frame(width: 52, height: 52)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.hairline, lineWidth: 1))
            VStack(alignment: .leading, spacing: 3) {
                Text(color.name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Theme.ink)
                Text("\(color.brand.displayName) · \(color.code) · #\(color.hex)")
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(Theme.inkSecondary)
            }
            Spacer()
            VStack(spacing: 4) {
                Image(systemName: target.systemImage)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.brand)
                Text(target.label)
                    .font(.system(size: 10.5, weight: .semibold))
                    .foregroundStyle(Theme.inkSecondary)
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
        if let color {
            text += "Color: \(color.name) (\(color.brand.displayName) \(color.code), #\(color.hex))\n"
        }
        text += "Surface: \(target.label)\n"
        if !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            text += "Notes: \(notes)\n"
        }
        text += "\nPlease send me a quote — \(BusinessInfo.website)"
        return [result, text]
    }

    private func save() {
        guard !saved else { return }
        let project = VisionProject(
            originalImageData: ImageResizer.storageJPEG(original),
            resultImageData: ImageResizer.storageJPEG(result),
            colorName: color?.name ?? "Custom",
            colorCode: color?.code ?? "",
            colorBrand: color?.brand.displayName ?? "",
            colorHex: color?.hex ?? "",
            surfaceLabel: target.label,
            notes: notes
        )
        modelContext.insert(project)
        Haptics.success()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { saved = true }
    }
}
