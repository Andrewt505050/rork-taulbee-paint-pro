//
//  SavedProjectView.swift
//  TaulbeePainting
//
//  Detail view for a saved Vision project with before/after, color details,
//  re-share, and delete.
//

import SwiftUI
import SwiftData

struct SavedProjectView: View {
    let project: VisionProject

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

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

                colorCard
                if !project.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    notesCard
                }
                PrimaryButton(title: "Send to Taulbee", systemImage: "paperplane.fill") {
                    showShare = true
                }
                PrimaryButton(
                    title: savedToVault ? "Saved to Vault" : "Save Color to Vault",
                    systemImage: savedToVault ? "checkmark.circle.fill" : "lock.shield.fill",
                    fill: false
                ) {
                    saveColorToVault()
                }
                .disabled(savedToVault)
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

    private var colorCard: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: project.colorHex.isEmpty ? "CCCCCC" : project.colorHex))
                .frame(width: 52, height: 52)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.hairline, lineWidth: 1))
            VStack(alignment: .leading, spacing: 3) {
                Text(project.colorName)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Theme.ink)
                Text(detailLine)
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

    /// Stores this project's color as a paint-color record in the Vault.
    private func saveColorToVault() {
        guard !savedToVault else { return }
        var notes = "From a Vision project on \(project.surfaceLabel.lowercased())."
        if !project.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            notes += "\n\n\(project.notes)"
        }
        let record = HomeRecord(
            title: project.colorName,
            category: .paintColor,
            notes: notes,
            colorHex: project.colorHex,
            colorCode: project.colorCode,
            colorBrand: project.colorBrand
        )
        modelContext.insert(record)
        Haptics.success()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            savedToVault = true
        }
    }

    private var detailLine: String {
        var parts: [String] = []
        if !project.colorBrand.isEmpty { parts.append(project.colorBrand) }
        if !project.colorCode.isEmpty { parts.append(project.colorCode) }
        parts.append(project.surfaceLabel)
        return parts.joined(separator: " · ")
    }

    private var shareItems: [Any] {
        var text = "Taulbee Painting — Vision Tool project\n"
        text += "Color: \(project.colorName)"
        if !project.colorBrand.isEmpty { text += " (\(project.colorBrand) \(project.colorCode))" }
        text += "\nSurface: \(project.surfaceLabel)\n"
        if !project.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            text += "Notes: \(project.notes)\n"
        }
        text += "\nPlease send me a quote — \(BusinessInfo.website)"
        if let result { return [result, text] }
        return [text]
    }
}
