//
//  RoomEditorView.swift
//  TaulbeePainting
//
//  Create or edit a Paint Vault room profile: name, type, photos with
//  before/after tags, current color and sheen, surfaces, dates, and notes.
//

import SwiftUI
import SwiftData
import PhotosUI

struct RoomEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    /// Existing room to edit, or nil to create a new one.
    let existing: PaintRoom?
    /// Called after a successful save (used for the pricing prompt).
    var onSaved: ((PaintRoom) -> Void)?

    @State private var name: String
    @State private var roomType: RoomType
    @State private var draftPhotos: [DraftRoomPhoto]
    @State private var currentColor: ColorSelection?
    @State private var sheen: SheenType?
    @State private var surfaces: Set<RoomSurface>
    @State private var hasLastPainted: Bool
    @State private var lastPainted: Date
    @State private var conditionNotes: String
    @State private var notes: String
    @State private var touchUpInstructions: String
    @State private var contractorNotes: String
    @State private var careNotes: String

    @State private var photoItems: [PhotosPickerItem] = []
    @State private var photoTrigger = false
    @State private var showSourceDialog = false
    @State private var showCamera = false
    @State private var cameraUnavailable = false
    @State private var showColorPicker = false

    private let initialPhotoCount: Int

    init(existing: PaintRoom? = nil, onSaved: ((PaintRoom) -> Void)? = nil) {
        self.existing = existing
        self.onSaved = onSaved
        _name = State(initialValue: existing?.name ?? "")
        _roomType = State(initialValue: existing?.roomType ?? .livingRoom)
        let drafts = (existing?.orderedPhotos ?? []).map {
            DraftRoomPhoto(kind: $0.kind, data: $0.data)
        }
        _draftPhotos = State(initialValue: drafts)
        initialPhotoCount = drafts.count
        if let existing, existing.hasCurrentColor {
            _currentColor = State(initialValue: ColorSelection(
                name: existing.currentColorName,
                brand: existing.currentColorBrand,
                code: existing.currentColorCode,
                hex: existing.currentColorHex
            ))
        } else {
            _currentColor = State(initialValue: nil)
        }
        _sheen = State(initialValue: existing?.sheen)
        _surfaces = State(initialValue: Set(existing?.surfaces ?? [.walls]))
        _hasLastPainted = State(initialValue: existing?.lastPaintedDate != nil)
        _lastPainted = State(initialValue: existing?.lastPaintedDate ?? .now)
        _conditionNotes = State(initialValue: existing?.conditionNotes ?? "")
        _notes = State(initialValue: existing?.notes ?? "")
        _touchUpInstructions = State(initialValue: existing?.touchUpInstructions ?? "")
        _contractorNotes = State(initialValue: existing?.contractorNotes ?? "")
        _careNotes = State(initialValue: existing?.careNotes ?? "")
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    nameField
                    typeSection
                    photosSection
                    currentColorSection
                    sheenSection
                    surfacesSection
                    lastPaintedSection
                    notesSection
                    Color.clear.frame(height: 8)
                }
                .padding(16)
            }
            .background(Theme.canvas.ignoresSafeArea())
            .navigationTitle(existing == nil ? "Add Room" : "Edit Room")
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
            .confirmationDialog("Add photo", isPresented: $showSourceDialog, titleVisibility: .visible) {
                Button("Take Photo") {
                    if CameraPicker.isAvailable { showCamera = true } else { cameraUnavailable = true }
                }
                Button("Choose Photos") { photoTrigger = true }
                Button("Cancel", role: .cancel) { }
            }
            .photosPicker(isPresented: $photoTrigger, selection: $photoItems, maxSelectionCount: 6, matching: .images)
            .sheet(isPresented: $showCamera) {
                CameraPicker { image in addImage(image) }
                    .ignoresSafeArea()
            }
            .sheet(isPresented: $showColorPicker) {
                ColorPickerSheet(title: "Current Color") { selection in
                    currentColor = selection
                }
            }
            .alert("Camera unavailable", isPresented: $cameraUnavailable) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Install this app on your device via the Rork App to use the camera. You can still choose photos from your library.")
            }
            .onChange(of: photoItems) { _, items in
                guard !items.isEmpty else { return }
                Task { await loadPhotos(items) }
            }
        }
    }

    // MARK: Sections

    private var nameField: some View {
        VStack(alignment: .leading, spacing: 8) {
            fieldLabel("Room name")
            TextField("e.g. Living Room, Front Exterior", text: $name)
                .font(.system(size: 16))
                .padding(14)
                .background(Theme.surface, in: .rect(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.hairline, lineWidth: 1))
        }
    }

    private var typeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            fieldLabel("Room type")
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 104), spacing: 8)], spacing: 8) {
                ForEach(RoomType.allCases) { type in
                    Button {
                        Haptics.tap()
                        withAnimation(.snappy(duration: 0.2)) { roomType = type }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: type.systemImage)
                                .font(.system(size: 12, weight: .bold))
                            Text(type.label)
                                .font(.system(size: 12.5, weight: .semibold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.85)
                        }
                        .foregroundStyle(roomType == type ? .white : Theme.brand)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(
                            roomType == type ? AnyShapeStyle(Theme.brandGradient) : AnyShapeStyle(Theme.lavender),
                            in: .rect(cornerRadius: 12)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var photosSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            fieldLabel("Photos")
            Text("Long-press a photo to tag it Before or After.")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Theme.inkSecondary)
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

                    ForEach(draftPhotos) { draft in
                        photoThumb(draft)
                    }
                }
                .padding(.horizontal, 2)
            }
            .scrollClipDisabled()
        }
    }

    private func photoThumb(_ draft: DraftRoomPhoto) -> some View {
        ZStack(alignment: .topTrailing) {
            Color(.secondarySystemBackground)
                .frame(width: 84, height: 84)
                .overlay {
                    if let image = UIImage(data: draft.data) {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .allowsHitTesting(false)
                    }
                }
                .clipShape(.rect(cornerRadius: 14))
                .overlay(alignment: .bottomLeading) {
                    if draft.kind != .general {
                        Text(draft.kind.label.uppercased())
                            .font(.system(size: 9, weight: .heavy))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Theme.brand, in: .capsule)
                            .padding(5)
                    }
                }
                .contextMenu {
                    ForEach(RoomPhotoKind.allCases) { kind in
                        Button {
                            setKind(kind, for: draft)
                        } label: {
                            Label("Tag as \(kind.label)", systemImage: draft.kind == kind ? "checkmark" : "tag")
                        }
                    }
                    Button(role: .destructive) {
                        draftPhotos.removeAll { $0.id == draft.id }
                    } label: {
                        Label("Remove", systemImage: "trash")
                    }
                }

            Button {
                Haptics.tap()
                draftPhotos.removeAll { $0.id == draft.id }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.white, .black.opacity(0.5))
            }
            .buttonStyle(.plain)
            .padding(4)
        }
    }

    private var currentColorSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            fieldLabel("Current color")
            Button {
                Haptics.tap()
                showColorPicker = true
            } label: {
                HStack(spacing: 13) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(currentColor.map { Color(hex: $0.hex.isEmpty ? "CCCCCC" : $0.hex) } ?? Theme.canvasDeep)
                        .frame(width: 44, height: 44)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.hairline, lineWidth: 1))
                        .overlay {
                            if currentColor == nil {
                                Image(systemName: "paintpalette")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(Theme.inkSecondary)
                            }
                        }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(currentColor?.name ?? "What color is on the walls?")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(Theme.ink)
                        Text(currentColor.map { selection in
                            [selection.brand, selection.code].filter { !$0.isEmpty }.joined(separator: " ")
                        } .flatMap { $0.isEmpty ? nil : $0 } ?? "Choose from the library or enter manually")
                            .font(.system(size: 12.5, weight: .medium))
                            .foregroundStyle(Theme.inkSecondary)
                    }
                    Spacer(minLength: 6)
                    if currentColor != nil {
                        Button {
                            Haptics.tap()
                            currentColor = nil
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(Theme.inkSecondary.opacity(0.6))
                        }
                        .buttonStyle(.plain)
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Theme.inkSecondary.opacity(0.5))
                    }
                }
                .padding(12)
                .background(Theme.surface, in: .rect(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.hairline, lineWidth: 1))
                .contentShape(.rect(cornerRadius: 14))
            }
            .buttonStyle(.plain)
        }
    }

    private var sheenSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            fieldLabel("Sheen")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(SheenType.allCases) { option in
                        Button {
                            Haptics.tap()
                            sheen = sheen == option ? nil : option
                        } label: {
                            Text(option.label)
                                .font(.system(size: 13.5, weight: .semibold))
                                .foregroundStyle(sheen == option ? .white : Theme.inkSecondary)
                                .padding(.horizontal, 14)
                                .frame(height: 36)
                                .background(
                                    sheen == option ? AnyShapeStyle(Theme.brand) : AnyShapeStyle(Theme.surface),
                                    in: .capsule
                                )
                                .overlay(Capsule().stroke(Theme.hairline, lineWidth: sheen == option ? 0 : 1))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 2)
            }
            .scrollClipDisabled()
        }
    }

    private var surfacesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            fieldLabel("Surfaces in scope")
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 8)], spacing: 8) {
                ForEach(RoomSurface.allCases) { surface in
                    Button {
                        Haptics.tap()
                        if surfaces.contains(surface) {
                            surfaces.remove(surface)
                        } else {
                            surfaces.insert(surface)
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: surfaces.contains(surface) ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 13, weight: .bold))
                            Text(surface.label)
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundStyle(surfaces.contains(surface) ? Theme.brand : Theme.inkSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background(
                            surfaces.contains(surface) ? AnyShapeStyle(Theme.lavender) : AnyShapeStyle(Theme.surface),
                            in: .rect(cornerRadius: 12)
                        )
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(surfaces.contains(surface) ? Theme.brand.opacity(0.35) : Theme.hairline, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var lastPaintedSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            fieldLabel("Last painted")
            VStack(spacing: 0) {
                Toggle(isOn: $hasLastPainted.animation()) {
                    Text("I know when it was last painted")
                        .font(.system(size: 15, weight: .medium))
                }
                .tint(Theme.brand)
                if hasLastPainted {
                    DatePicker("", selection: $lastPainted, in: ...Date.now, displayedComponents: .date)
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
        VStack(alignment: .leading, spacing: 16) {
            notesField("Condition notes", text: $conditionNotes, prompt: "e.g. hairline cracks above the window, scuffs near the door…")
            notesField("Touch-up instructions", text: $touchUpInstructions, prompt: "e.g. leftover paint in garage, feather edges with a small roller…")
            notesField("Contractor notes", text: $contractorNotes, prompt: "e.g. painted by Taulbee in 2024, two coats over primer…")
            notesField("Warranty / care notes", text: $careNotes, prompt: "e.g. wash with mild soap only, 2-year workmanship warranty…")
            notesField("Other notes", text: $notes, prompt: "Anything else worth remembering about this room…")
        }
    }

    private func notesField(_ label: String, text: Binding<String>, prompt: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            fieldLabel(label)
            TextField(prompt, text: text, axis: .vertical)
                .font(.system(size: 15))
                .lineLimit(2...6)
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

    private func setKind(_ kind: RoomPhotoKind, for draft: DraftRoomPhoto) {
        guard let index = draftPhotos.firstIndex(where: { $0.id == draft.id }) else { return }
        draftPhotos[index].kind = kind
        Haptics.tap()
    }

    private func addImage(_ image: UIImage) {
        guard let data = image.jpegData(compressionQuality: 0.85) else { return }
        draftPhotos.append(DraftRoomPhoto(kind: .general, data: data))
        Haptics.tap()
    }

    private func loadPhotos(_ items: [PhotosPickerItem]) async {
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data),
               let jpeg = image.jpegData(compressionQuality: 0.85) {
                draftPhotos.append(DraftRoomPhoto(kind: .general, data: jpeg))
            }
        }
        photoItems = []
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        Haptics.success()

        let room: PaintRoom
        let isNew = existing == nil
        if let existing {
            room = existing
            for photo in existing.photos {
                modelContext.delete(photo)
            }
            room.photos = []
        } else {
            room = PaintRoom(name: trimmed, roomType: roomType)
            modelContext.insert(room)
        }

        room.name = trimmed
        room.roomType = roomType
        room.currentColorName = currentColor?.name ?? ""
        room.currentColorBrand = currentColor?.brand ?? ""
        room.currentColorCode = currentColor?.code ?? ""
        room.currentColorHex = currentColor?.hex ?? ""
        room.sheen = sheen
        room.surfaces = RoomSurface.allCases.filter { surfaces.contains($0) }
        room.lastPaintedDate = hasLastPainted ? lastPainted : nil
        room.conditionNotes = conditionNotes
        room.notes = notes
        room.touchUpInstructions = touchUpInstructions
        room.contractorNotes = contractorNotes
        room.careNotes = careNotes
        room.updatedAt = .now

        let photos = draftPhotos.map { RoomPhoto(kind: $0.kind, data: $0.data) }
        for photo in photos {
            photo.room = room
            modelContext.insert(photo)
        }
        room.photos = photos

        if isNew {
            ActivityEvent.log(.roomCreated, title: "\(trimmed) added to Paint Vault", in: modelContext)
        }
        if draftPhotos.count > initialPhotoCount {
            ActivityEvent.log(.photoAdded, title: "Photos added to \(trimmed)", in: modelContext)
        }

        try? modelContext.save()
        dismiss()
        onSaved?(room)
    }
}

/// In-memory staging type for room photos before they're persisted.
struct DraftRoomPhoto: Identifiable {
    let id = UUID()
    var kind: RoomPhotoKind
    let data: Data
}
