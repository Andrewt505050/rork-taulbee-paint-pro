//
//  RecordEditorView.swift
//  TaulbeePainting
//
//  Create or edit a HomeRecord: title, category, room, notes, dates and
//  photo/document attachments.
//

import SwiftUI
import SwiftData
import PhotosUI

struct RecordEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    /// Existing record to edit, or nil to create a new one.
    let existing: HomeRecord?

    @State private var title: String
    @State private var category: RecordCategory
    @State private var room: String
    @State private var notes: String
    @State private var hasPurchaseDate: Bool
    @State private var purchaseDate: Date
    @State private var hasExpiryDate: Bool
    @State private var expiryDate: Date

    /// Pending attachments staged before save.
    @State private var draftAttachments: [DraftAttachment]

    @State private var photoItems: [PhotosPickerItem] = []
    @State private var showSourceDialog = false
    @State private var showCamera = false
    @State private var showDocumentPicker = false
    @State private var cameraUnavailable = false

    private let rooms = ["Kitchen", "Living Room", "Bedroom", "Bathroom", "Garage", "Basement", "Exterior", "Office", "Dining Room", "Laundry"]

    init(existing: HomeRecord? = nil) {
        self.existing = existing
        _title = State(initialValue: existing?.title ?? "")
        _category = State(initialValue: existing?.category ?? .receipt)
        _room = State(initialValue: existing?.room ?? "")
        _notes = State(initialValue: existing?.notes ?? "")
        _hasPurchaseDate = State(initialValue: existing?.purchaseDate != nil)
        _purchaseDate = State(initialValue: existing?.purchaseDate ?? .now)
        _hasExpiryDate = State(initialValue: existing?.expiryDate != nil)
        _expiryDate = State(initialValue: existing?.expiryDate ?? Calendar.current.date(byAdding: .year, value: 1, to: .now) ?? .now)
        let drafts = (existing?.orderedAttachments ?? []).map {
            DraftAttachment(kind: $0.kind, filename: $0.filename, fileExtension: $0.fileExtension, data: $0.data)
        }
        _draftAttachments = State(initialValue: drafts)
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    titleField
                    categorySection
                    attachmentsSection
                    roomSection
                    if category.usesDates {
                        datesSection
                    }
                    notesSection
                    Color.clear.frame(height: 8)
                }
                .padding(16)
            }
            .background(Theme.canvas.ignoresSafeArea())
            .navigationTitle(existing == nil ? "Add Record" : "Edit Record")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.bold)
                        .disabled(!canSave)
                }
            }
            .confirmationDialog("Add attachment", isPresented: $showSourceDialog, titleVisibility: .visible) {
                Button("Take Photo") {
                    if CameraPicker.isAvailable { showCamera = true } else { cameraUnavailable = true }
                }
                Button("Choose Photo") { /* handled by PhotosPicker below */ photoTrigger = true }
                Button("Attach Document") { showDocumentPicker = true }
                Button("Cancel", role: .cancel) { }
            }
            .photosPicker(isPresented: $photoTrigger, selection: $photoItems, maxSelectionCount: 6, matching: .images)
            .sheet(isPresented: $showCamera) {
                CameraPicker { image in addImage(image) }
                    .ignoresSafeArea()
            }
            .sheet(isPresented: $showDocumentPicker) {
                DocumentPicker { doc in
                    draftAttachments.append(DraftAttachment(kind: .document, filename: doc.filename, fileExtension: doc.fileExtension, data: doc.data))
                    Haptics.tap()
                }
            }
            .alert("Camera unavailable", isPresented: $cameraUnavailable) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Install this app on your device via the Rork App to use the camera. You can still choose a photo from your library.")
            }
            .onChange(of: photoItems) { _, items in
                guard !items.isEmpty else { return }
                Task { await loadPhotos(items) }
            }
        }
    }

    @State private var photoTrigger = false

    // MARK: Sections

    private var titleField: some View {
        VStack(alignment: .leading, spacing: 8) {
            fieldLabel("Title")
            TextField("e.g. Fridge warranty, Living room paint", text: $title)
                .font(.system(size: 16))
                .padding(14)
                .background(Theme.surface, in: .rect(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.hairline, lineWidth: 1))
        }
    }

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            fieldLabel("Category")
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 104), spacing: 8)], spacing: 8) {
                ForEach(RecordCategory.allCases) { cat in
                    Button {
                        Haptics.tap()
                        withAnimation(.snappy(duration: 0.2)) { category = cat }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: cat.systemImage)
                                .font(.system(size: 12, weight: .bold))
                            Text(cat.label)
                                .font(.system(size: 13, weight: .semibold))
                                .lineLimit(1)
                        }
                        .foregroundStyle(category == cat ? .white : cat.tint)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(category == cat ? AnyShapeStyle(cat.tint) : AnyShapeStyle(cat.tint.opacity(0.12)), in: .rect(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var attachmentsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            fieldLabel("Photos & documents")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    Button {
                        Haptics.tap()
                        showSourceDialog = true
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: "plus")
                                .font(.system(size: 20, weight: .bold))
                            Text("Add")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundStyle(Theme.brand)
                        .frame(width: 84, height: 84)
                        .background(Theme.brand.opacity(0.10), in: .rect(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.brand.opacity(0.3), style: StrokeStyle(lineWidth: 1.5, dash: [5])))
                    }
                    .buttonStyle(.plain)

                    ForEach(draftAttachments) { draft in
                        attachmentThumb(draft)
                    }
                }
                .padding(.horizontal, 2)
            }
            .scrollClipDisabled()
        }
    }

    private func attachmentThumb(_ draft: DraftAttachment) -> some View {
        ZStack(alignment: .topTrailing) {
            Color(.secondarySystemBackground)
                .frame(width: 84, height: 84)
                .overlay {
                    if draft.kind == .image, let image = UIImage(data: draft.data) {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .allowsHitTesting(false)
                    } else {
                        VStack(spacing: 4) {
                            Image(systemName: "doc.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(Theme.brand)
                            Text(draft.fileExtension.uppercased())
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Theme.inkSecondary)
                        }
                    }
                }
                .clipShape(.rect(cornerRadius: 14))

            Button {
                Haptics.tap()
                draftAttachments.removeAll { $0.id == draft.id }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.white, .black.opacity(0.5))
            }
            .buttonStyle(.plain)
            .padding(4)
        }
    }

    private var roomSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            fieldLabel("Room (optional)")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(rooms, id: \.self) { r in
                        Button {
                            Haptics.tap()
                            room = room == r ? "" : r
                        } label: {
                            Text(r)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(room == r ? .white : Theme.inkSecondary)
                                .padding(.horizontal, 14)
                                .frame(height: 36)
                                .background(room == r ? AnyShapeStyle(Theme.brand) : AnyShapeStyle(Theme.surface), in: .capsule)
                                .overlay(Capsule().stroke(Theme.hairline, lineWidth: room == r ? 0 : 1))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 2)
            }
            .scrollClipDisabled()
        }
    }

    private var datesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            fieldLabel("Dates")
            VStack(spacing: 0) {
                Toggle(isOn: $hasPurchaseDate.animation()) {
                    Text("Purchase date").font(.system(size: 15, weight: .medium))
                }
                .tint(Theme.brand)
                if hasPurchaseDate {
                    DatePicker("", selection: $purchaseDate, displayedComponents: .date)
                        .labelsHidden()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 4)
                }
                Divider().padding(.vertical, 12)
                Toggle(isOn: $hasExpiryDate.animation()) {
                    Text("Expiry / warranty end").font(.system(size: 15, weight: .medium))
                }
                .tint(Theme.brand)
                if hasExpiryDate {
                    DatePicker("", selection: $expiryDate, displayedComponents: .date)
                        .labelsHidden()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 4)
                }
            }
            .padding(14)
            .background(Theme.surface, in: .rect(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.hairline, lineWidth: 1))
        }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            fieldLabel("Notes")
            TextField("Add any useful details — model numbers, contractor, cost, terms…", text: $notes, axis: .vertical)
                .font(.system(size: 16))
                .lineLimit(3...8)
                .padding(14)
                .background(Theme.surface, in: .rect(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.hairline, lineWidth: 1))
        }
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 12, weight: .heavy))
            .tracking(1)
            .foregroundStyle(Theme.inkSecondary)
    }

    // MARK: Actions

    private func addImage(_ image: UIImage) {
        guard let data = image.jpegData(compressionQuality: 0.85) else { return }
        draftAttachments.append(DraftAttachment(kind: .image, filename: "Photo.jpg", fileExtension: "jpg", data: data))
        Haptics.tap()
    }

    private func loadPhotos(_ items: [PhotosPickerItem]) async {
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data),
               let jpeg = image.jpegData(compressionQuality: 0.85) {
                draftAttachments.append(DraftAttachment(kind: .image, filename: "Photo.jpg", fileExtension: "jpg", data: jpeg))
            }
        }
        photoItems = []
    }

    private func save() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        guard !trimmedTitle.isEmpty else { return }
        Haptics.success()

        let record: HomeRecord
        if let existing {
            record = existing
            // Remove old attachments; we rebuild from drafts.
            for attachment in existing.attachments {
                modelContext.delete(attachment)
            }
            record.attachments = []
        } else {
            record = HomeRecord(title: trimmedTitle, category: category)
            modelContext.insert(record)
        }

        record.title = trimmedTitle
        record.category = category
        record.room = room
        record.notes = notes
        record.purchaseDate = (category.usesDates && hasPurchaseDate) ? purchaseDate : nil
        record.expiryDate = (category.usesDates && hasExpiryDate) ? expiryDate : nil
        record.updatedAt = .now

        let attachments = draftAttachments.map {
            RecordAttachment(kind: $0.kind, filename: $0.filename, fileExtension: $0.fileExtension, data: $0.data)
        }
        for attachment in attachments {
            attachment.record = record
            modelContext.insert(attachment)
        }
        record.attachments = attachments

        try? modelContext.save()
        dismiss()
    }
}

/// In-memory staging type for attachments before they're persisted.
struct DraftAttachment: Identifiable {
    let id = UUID()
    let kind: AttachmentKind
    let filename: String
    let fileExtension: String
    let data: Data
}
