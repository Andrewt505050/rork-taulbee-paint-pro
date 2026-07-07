//
//  SavedProjectView.swift
//  TaulbeePainting
//
//  Detail view for a saved Vision project with before/after, the full color
//  scheme (one card per painted surface), re-share, and delete.
//

import SwiftUI
import SwiftData

struct SavedProjectView: View {
    let project: VisionProject

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(AppRouter.self) private var router

    @State private var showShare = false
    @State private var confirmDelete = false
    @State private var savedToVault = false

    private var original: UIImage? { UIImage(data: project.originalImageData) }
    private var result: UIImage? { UIImage(data: project.resultImageData) }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let original, let result {
                    BeforeAfterSlider(before: original, after: result)
                        .frame(height: 300)
                        .clipShape(.rect(cornerRadius: Theme.cardRadius))
                        .overlay(RoundedRectangle(cornerRadius: Theme.cardRadius).stroke(Theme.hairline, lineWidth: 1))
                        .shadow(color: .black.opacity(0.08), radius: 16, y: 8)
                } else if let result {
                    Image(uiImage: result)
                        .resizable()
                        .scaledToFit()
                        .clipShape(.rect(cornerRadius: Theme.cardRadius))
                }

                schemeSection
                if !project.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    notesCard
                }
                PrimaryButton(title: "Send to Taulbee", systemImage: "paperplane.fill") {
                    showShare = true
                }
                PrimaryButton(
                    title: savedToVault
                        ? "Saved to Vault"
                        : (project.scheme.count > 1 ? "Save Colors to Vault" : "Save Color to Vault"),
                    systemImage: savedToVault ? "checkmark.circle.fill" : "lock.shield.fill",
                    fill: false
                ) {
                    saveColorToVault()
                }
                .disabled(savedToVault)
                if savedToVault {
                    expertPrompt
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
                PrimaryButton(title: "Delete Project", systemImage: "trash", fill: false) {
                    confirmDelete = true
                }
                Color.clear.frame(height: 12)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .background(Theme.canvas.ignoresSafeArea())
        .navigationTitle(project.colorName)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showShare) {
            ShareSheet(items: shareItems)
        }
        .confirmationDialog("Delete this project?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                modelContext.delete(project)
                dismiss()
            }
            Button("Cancel", role: .cancel) { }
        }
    }

    private var schemeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if project.scheme.count > 1 {
                SectionLabel(icon: "paintpalette.fill", title: "Color Scheme")
            }
            VStack(spacing: 12) {
                ForEach(project.scheme, id: \.self) { paint in
                    schemeCard(paint)
                }
            }
        }
    }

    private func schemeCard(_ paint: SavedSurfacePaint) -> some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: paint.colorHex.isEmpty ? "CCCCCC" : paint.colorHex))
                .frame(width: 52, height: 52)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.hairline, lineWidth: 1))
            VStack(alignment: .leading, spacing: 3) {
                Text(paint.colorName)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Theme.ink)
                Text(detailLine(for: paint))
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(Theme.inkSecondary)
            }
            Spacer()
        }
        .paintCard()
    }

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionLabel(icon: "square.and.pencil", title: "Notes")
            Text(project.notes)
                .font(.system(size: 15))
                .foregroundStyle(Theme.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .paintCard()
    }

    private var expertPrompt: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "bubble.left.and.text.bubble.right.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.brand)
                .frame(width: 40, height: 40)
                .background(Theme.lavender, in: .circle)
            VStack(alignment: .leading, spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Need help choosing the final color?")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Theme.ink)
                    Text("Our Paint Expert can compare options and finishes for your space.")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Theme.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Button {
                    Haptics.tap()
                    askExpert()
                } label: {
                    Text("Ask a Paint Expert")
                        .font(.system(size: 13.5, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .frame(height: 36)
                        .background(Theme.brandGradient, in: .capsule)
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .paintCard(padding: 16)
    }

    private func askExpert() {
        let scheme = project.scheme
        let described = scheme.map { paint in
            var label = paint.colorName
            if !paint.colorBrand.isEmpty {
                label += " (\(paint.colorBrand) \(paint.colorCode))"
            }
            return "\(label) for my \(paint.surfaceLabel.lowercased())"
        }.joined(separator: ", ")
        let question = scheme.count > 1
            ? "Is this a good combination, and what should I compare it with?"
            : "Is it a good choice, and what should I compare it with?"
        router.askExpert("I'm considering \(described). \(question)")
    }

    /// Stores every color in this project's scheme as paint-color records in
    /// the Vault.
    private func saveColorToVault() {
        guard !savedToVault else { return }
        let scheme = project.scheme
        for paint in scheme {
            var notes = "From a Vision project on \(paint.surfaceLabel.lowercased())."
            if !project.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                notes += "\n\n\(project.notes)"
            }
            let record = HomeRecord(
                title: paint.colorName,
                category: .paintColor,
                notes: notes,
                colorHex: paint.colorHex,
                colorCode: paint.colorCode,
                colorBrand: paint.colorBrand
            )
            modelContext.insert(record)
        }
        let eventTitle = scheme.count > 1
            ? "\(scheme.count) colors saved to Vault"
            : "\(project.colorName) saved to Vault"
        ActivityEvent.log(.colorSaved, title: eventTitle, in: modelContext)
        try? modelContext.save()
        Haptics.success()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            savedToVault = true
        }
    }

    private func detailLine(for paint: SavedSurfacePaint) -> String {
        var parts: [String] = []
        if !paint.colorBrand.isEmpty { parts.append(paint.colorBrand) }
        if !paint.colorCode.isEmpty { parts.append(paint.colorCode) }
        if !paint.surfaceLabel.isEmpty { parts.append(paint.surfaceLabel) }
        return parts.joined(separator: " · ")
    }

    private var shareItems: [Any] {
        var text = "Taulbee Painting — Vision Tool project\n"
        let scheme = project.scheme
        if scheme.count == 1, let paint = scheme.first {
            text += "Color: \(paint.colorName)"
            if !paint.colorBrand.isEmpty { text += " (\(paint.colorBrand) \(paint.colorCode))" }
            text += "\nSurface: \(paint.surfaceLabel)\n"
        } else {
            text += "Color scheme:\n"
            for paint in scheme {
                text += "• \(paint.surfaceLabel): \(paint.colorName)"
                if !paint.colorBrand.isEmpty { text += " (\(paint.colorBrand) \(paint.colorCode))" }
                text += "\n"
            }
        }
        if !project.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            text += "Notes: \(project.notes)\n"
        }
        text += "\nPlease send me a quote — \(BusinessInfo.website)"
        if let result { return [result, text] }
        return [text]
    }
}
