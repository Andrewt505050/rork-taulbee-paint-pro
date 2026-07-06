//
//  RecordDetailView.swift
//  TaulbeePainting
//
//  Full view of a single Vault record: attachments, all details, expiry
//  reminders, plus edit, share and delete.
//

import SwiftUI
import SwiftData

struct RecordDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var record: HomeRecord

    @State private var showEditor = false
    @State private var showShare = false
    @State private var fullScreenImage: UIImage?
    @State private var previewDoc: RecordAttachment?

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                if !record.orderedAttachments.isEmpty {
                    attachmentsCarousel
                }
                header
                if record.category.usesDates && (record.purchaseDate != nil || record.expiryDate != nil) {
                    datesCard
                }
                if !record.notes.isEmpty {
                    notesCard
                }
                if record.orderedAttachments.contains(where: { $0.kind == .document }) {
                    documentsList
                }
                Color.clear.frame(height: 12)
            }
            .padding(16)
        }
        .background(Theme.canvas.ignoresSafeArea())
        .navigationTitle("Record")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { showEditor = true } label: { Label("Edit", systemImage: "pencil") }
                    Button { showShare = true } label: { Label("Share", systemImage: "square.and.arrow.up") }
                    Button(role: .destructive) { delete() } label: { Label("Delete", systemImage: "trash") }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showEditor) {
            RecordEditorView(existing: record)
        }
        .sheet(isPresented: $showShare) {
            ShareSheet(items: shareItems)
        }
        .fullScreenCover(item: $fullScreenImage) { image in
            ImageViewer(image: image)
        }
        .sheet(item: $previewDoc) { doc in
            DocumentPreview(data: doc.data, filename: doc.filename)
                .ignoresSafeArea()
        }
    }

    // MARK: Attachments carousel

    private var attachmentsCarousel: some View {
        let images = record.orderedAttachments.filter { $0.kind == .image }
        return Group {
            if !images.isEmpty {
                TabView {
                    ForEach(images) { attachment in
                        if let image = attachment.image {
                            Color(.secondarySystemBackground)
                                .overlay {
                                    Image(uiImage: image)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .allowsHitTesting(false)
                                }
                                .clipShape(.rect(cornerRadius: 20))
                                .onTapGesture { fullScreenImage = image }
                        }
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: images.count > 1 ? .automatic : .never))
                .frame(height: 280)
            }
        }
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                ZStack {
                    Circle().fill(record.category.tint.opacity(0.14)).frame(width: 46, height: 46)
                    Image(systemName: record.category.systemImage)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(record.category.tint)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(record.category.label)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(record.category.tint)
                    if !record.room.isEmpty {
                        Text(record.room)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Theme.inkSecondary)
                    }
                }
                Spacer()
            }

            Text(record.title.isEmpty ? "Untitled" : record.title)
                .font(.system(size: 24, weight: .heavy))
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)

            if record.isExpiringSoon || record.isExpired {
                expiryBanner
            }

            if !record.colorHex.isEmpty {
                colorRow
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .paintCard()
    }

    private var expiryBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 16, weight: .bold))
            Text(expiryMessage)
                .font(.system(size: 14, weight: .semibold))
            Spacer(minLength: 0)
        }
        .foregroundStyle(Theme.accent)
        .padding(12)
        .background(Theme.accent.opacity(0.12), in: .rect(cornerRadius: 12))
    }

    private var expiryMessage: String {
        guard let days = record.daysUntilExpiry else { return "" }
        if days < 0 { return "This expired \(-days) day\(days == -1 ? "" : "s") ago." }
        if days == 0 { return "This expires today." }
        return "Expires in \(days) day\(days == 1 ? "" : "s")."
    }

    private var colorRow: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(hex: record.colorHex))
                .frame(width: 44, height: 44)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.hairline, lineWidth: 1))
            VStack(alignment: .leading, spacing: 2) {
                Text([record.colorBrand, record.colorCode].filter { !$0.isEmpty }.joined(separator: " "))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.inkSecondary)
                Text(record.colorHex.uppercased())
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Theme.ink)
            }
            Spacer()
        }
    }

    // MARK: Dates

    private var datesCard: some View {
        VStack(spacing: 0) {
            if let purchase = record.purchaseDate {
                dateRow(icon: "cart.fill", label: "Purchased", date: purchase)
            }
            if record.purchaseDate != nil && record.expiryDate != nil {
                Divider().padding(.vertical, 12)
            }
            if let expiry = record.expiryDate {
                dateRow(icon: "calendar.badge.exclamationmark", label: "Expires", date: expiry)
            }
        }
        .paintCard()
    }

    private func dateRow(icon: String, label: String, date: Date) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.brand)
                .frame(width: 22)
            Text(label)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Theme.inkSecondary)
            Spacer()
            Text(date.formatted(date: .abbreviated, time: .omitted))
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Theme.ink)
        }
    }

    // MARK: Notes

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionLabel(icon: "note.text", title: "Notes")
            Text(record.notes)
                .font(.system(size: 15))
                .foregroundStyle(Theme.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .paintCard()
    }

    // MARK: Documents

    private var documentsList: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(icon: "doc.fill", title: "Documents")
            ForEach(record.orderedAttachments.filter { $0.kind == .document }) { doc in
                Button {
                    Haptics.tap()
                    previewDoc = doc
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "doc.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(Theme.brand)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(doc.filename)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Theme.ink)
                                .lineLimit(1)
                            Text(doc.fileExtension.uppercased())
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(Theme.inkSecondary)
                        }
                        Spacer()
                        Image(systemName: "eye.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.inkSecondary)
                    }
                    .padding(12)
                    .background(Theme.surface, in: .rect(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.hairline, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Actions

    private var shareItems: [Any] {
        var items: [Any] = []
        var text = record.title
        if !record.room.isEmpty { text += "\nRoom: \(record.room)" }
        text += "\nCategory: \(record.category.label)"
        if !record.notes.isEmpty { text += "\n\n\(record.notes)" }
        items.append(text)
        for attachment in record.orderedAttachments where attachment.kind == .image {
            if let image = attachment.image { items.append(image) }
        }
        return items
    }

    private func delete() {
        Haptics.warning()
        modelContext.delete(record)
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Full-screen image viewer

struct ImageViewer: View {
    let image: UIImage
    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 1

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .scaleEffect(scale)
                .gesture(
                    MagnifyGesture()
                        .onChanged { value in scale = max(1, value.magnification) }
                        .onEnded { _ in withAnimation(.spring) { scale = 1 } }
                )
            VStack {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundStyle(.white, .white.opacity(0.25))
                    }
                    .padding()
                }
                Spacer()
            }
        }
    }
}
