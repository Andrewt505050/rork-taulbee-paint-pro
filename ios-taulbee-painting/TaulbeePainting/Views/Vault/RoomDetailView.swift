//
//  RoomDetailView.swift
//  TaulbeePainting
//
//  Everything about one room: photos, the current color, saved color ideas,
//  surfaces, care notes, attached reminders, and a room-specific estimate CTA.
//

import SwiftUI
import SwiftData

struct RoomDetailView: View {
    let room: PaintRoom

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(AppRouter.self) private var router

    @State private var showEditor = false
    @State private var showColorPicker = false
    @State private var showReminderEditor = false
    @State private var showEstimate = false
    @State private var confirmDelete = false

    private var activeReminders: [PaintReminder] {
        room.reminders
            .filter { $0.completedAt == nil }
            .sorted { $0.dueDate < $1.dueDate }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                headerCard
                if !room.orderedPhotos.isEmpty { photosSection }
                currentColorCard
                savedColorsSection
                if !room.surfaces.isEmpty { surfacesCard }
                notesCards
                remindersSection
                estimateCTA
                Color.clear.frame(height: 12)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .background(Theme.canvas.ignoresSafeArea())
        .navigationTitle(room.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showEditor = true
                    } label: {
                        Label("Edit Room", systemImage: "pencil")
                    }
                    Button(role: .destructive) {
                        confirmDelete = true
                    } label: {
                        Label("Delete Room", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(Theme.brand)
                }
            }
        }
        .sheet(isPresented: $showEditor) {
            RoomEditorView(existing: room)
        }
        .sheet(isPresented: $showColorPicker) {
            ColorPickerSheet(title: "Save a Color Idea") { selection in
                addColor(selection)
            }
        }
        .sheet(isPresented: $showReminderEditor) {
            ReminderEditorView(room: room)
        }
        .sheet(isPresented: $showEstimate) {
            RequestEstimateView(prefilledRoomName: room.name)
        }
        .confirmationDialog("Delete this room?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                Haptics.warning()
                modelContext.delete(room)
                try? modelContext.save()
                dismiss()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Photos, saved colors, and notes for this room will be removed. Reminders will be kept.")
        }
    }

    // MARK: Header

    private var headerCard: some View {
        HStack(spacing: 14) {
            Image(systemName: room.roomType.systemImage)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Theme.brand)
                .frame(width: 52, height: 52)
                .background(Theme.lavender, in: .rect(cornerRadius: 16))
            VStack(alignment: .leading, spacing: 4) {
                Text(room.roomType.label)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Theme.brand)
                Text("Last painted: \(room.lastPaintedText)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.inkSecondary)
            }
            Spacer()
        }
        .paintCard(padding: 14)
    }

    // MARK: Photos

    private var photosSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(icon: "photo.on.rectangle.angled", title: "Photos")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(room.orderedPhotos) { photo in
                        Color(.secondarySystemBackground)
                            .frame(width: 130, height: 130)
                            .overlay {
                                if let image = photo.image {
                                    Image(uiImage: image)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .allowsHitTesting(false)
                                }
                            }
                            .clipShape(.rect(cornerRadius: 16))
                            .overlay(alignment: .bottomLeading) {
                                if photo.kind != .general {
                                    Text(photo.kind.label.uppercased())
                                        .font(.system(size: 10, weight: .heavy))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Theme.brand, in: .capsule)
                                        .padding(7)
                                }
                            }
                    }
                }
                .padding(.horizontal, 2)
            }
            .scrollClipDisabled()
        }
    }

    // MARK: Current color

    private var currentColorCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel(icon: "paintpalette.fill", title: "Current Color")
            if room.hasCurrentColor {
                HStack(spacing: 14) {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: room.currentColorHex.isEmpty ? "CCCCCC" : room.currentColorHex))
                        .frame(width: 52, height: 52)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.hairline, lineWidth: 1))
                    VStack(alignment: .leading, spacing: 3) {
                        Text(room.currentColorName.isEmpty ? "Unnamed color" : room.currentColorName)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Theme.ink)
                        HStack(spacing: 6) {
                            let detail = [room.currentColorBrand, room.currentColorCode]
                                .filter { !$0.isEmpty }
                                .joined(separator: " ")
                            if !detail.isEmpty {
                                Text(detail)
                                    .font(.system(size: 12.5, weight: .medium))
                                    .foregroundStyle(Theme.inkSecondary)
                            }
                            if let sheen = room.sheen {
                                Text(sheen.label)
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(Theme.brand)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Theme.lavender, in: .capsule)
                            }
                        }
                    }
                    Spacer()
                }
            } else {
                Button {
                    Haptics.tap()
                    showEditor = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 16, weight: .bold))
                        Text("Add the color that's on the walls")
                            .font(.system(size: 14.5, weight: .semibold))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Theme.inkSecondary.opacity(0.5))
                    }
                    .foregroundStyle(Theme.brand)
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .paintCard()
    }

    // MARK: Saved colors

    private var savedColorsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionLabel(icon: "heart.fill", title: "Saved Colors", tint: Theme.lavenderAccent)
                Spacer()
                Button {
                    Haptics.tap()
                    showColorPicker = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .bold))
                        Text("Add")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .foregroundStyle(Theme.brand)
                    .padding(.horizontal, 12)
                    .frame(height: 30)
                    .background(Theme.lavender, in: .capsule)
                }
                .buttonStyle(.plain)
            }

            if room.orderedSavedColors.isEmpty {
                Text("Save color ideas you're considering for this room.")
                    .font(.system(size: 13.5, weight: .medium))
                    .foregroundStyle(Theme.inkSecondary)
            } else {
                VStack(spacing: 10) {
                    ForEach(room.orderedSavedColors) { color in
                        HStack(spacing: 12) {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(color.swatch)
                                .frame(width: 40, height: 40)
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.hairline, lineWidth: 1))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(color.name)
                                    .font(.system(size: 14.5, weight: .bold))
                                    .foregroundStyle(Theme.ink)
                                if !color.detailLine.isEmpty {
                                    Text(color.detailLine)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundStyle(Theme.inkSecondary)
                                }
                            }
                            Spacer()
                        }
                        .contentShape(.rect)
                        .contextMenu {
                            Button(role: .destructive) {
                                removeColor(color)
                            } label: {
                                Label("Remove", systemImage: "trash")
                            }
                        }
                    }
                }
            }

            if room.orderedSavedColors.count >= 2 {
                Button {
                    Haptics.tap()
                    askExpertAboutColors()
                } label: {
                    HStack(spacing: 7) {
                        Image(systemName: "bubble.left.and.text.bubble.right.fill")
                            .font(.system(size: 12, weight: .bold))
                        Text("Need help choosing the final color? Ask a Paint Expert")
                            .font(.system(size: 13, weight: .bold))
                            .multilineTextAlignment(.leading)
                    }
                    .foregroundStyle(Theme.brand)
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .paintCard()
    }

    // MARK: Surfaces

    private var surfacesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel(icon: "checklist", title: "Surfaces in Scope")
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 8)], spacing: 8) {
                ForEach(room.surfaces) { surface in
                    HStack(spacing: 5) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12, weight: .bold))
                        Text(surface.label)
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundStyle(Theme.brand)
                    .frame(maxWidth: .infinity)
                    .frame(height: 34)
                    .background(Theme.lavender, in: .capsule)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .paintCard()
    }

    // MARK: Notes

    @ViewBuilder
    private var notesCards: some View {
        noteCard("Condition", icon: "eye.fill", text: room.conditionNotes)
        noteCard("Touch-Up Instructions", icon: "paintbrush.pointed.fill", text: room.touchUpInstructions)
        noteCard("Contractor Notes", icon: "person.badge.shield.checkmark.fill", text: room.contractorNotes)
        noteCard("Warranty & Care", icon: "checkmark.shield.fill", text: room.careNotes)
        noteCard("Notes", icon: "square.and.pencil", text: room.notes)
    }

    @ViewBuilder
    private func noteCard(_ title: String, icon: String, text: String) -> some View {
        if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                SectionLabel(icon: icon, title: title)
                Text(text)
                    .font(.system(size: 14.5))
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .paintCard()
        }
    }

    // MARK: Reminders

    private var remindersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionLabel(icon: "bell.badge.fill", title: "Care Reminders", tint: Theme.accent)
                Spacer()
                Button {
                    Haptics.tap()
                    showReminderEditor = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .bold))
                        Text("Add")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .foregroundStyle(Theme.brand)
                    .padding(.horizontal, 12)
                    .frame(height: 30)
                    .background(Theme.lavender, in: .capsule)
                }
                .buttonStyle(.plain)
            }

            if activeReminders.isEmpty {
                Text("Set touch-up and inspection reminders for this room — we'll nudge you at the right time.")
                    .font(.system(size: 13.5, weight: .medium))
                    .foregroundStyle(Theme.inkSecondary)
            } else {
                VStack(spacing: 10) {
                    ForEach(activeReminders) { reminder in
                        NavigationLink(value: reminder) {
                            ReminderRow(reminder: reminder, showRoom: false)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .paintCard()
    }

    // MARK: Estimate CTA

    private var estimateCTA: some View {
        VStack(spacing: 10) {
            PrimaryButton(title: "Request Estimate for This Room", systemImage: "envelope.fill") {
                showEstimate = true
            }
            Text("Free, no-pressure pricing from the Taulbee Painting team.")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Theme.inkSecondary)
        }
        .padding(.top, 4)
    }

    // MARK: Actions

    private func addColor(_ selection: ColorSelection) {
        let color = SavedColor(
            name: selection.name,
            brand: selection.brand,
            code: selection.code,
            hex: selection.hex
        )
        color.room = room
        modelContext.insert(color)
        room.updatedAt = .now
        ActivityEvent.log(.colorSaved, title: "\(selection.name) saved to \(room.name)", in: modelContext)
        try? modelContext.save()
        Haptics.success()
    }

    private func removeColor(_ color: SavedColor) {
        Haptics.warning()
        withAnimation {
            modelContext.delete(color)
            room.updatedAt = .now
            try? modelContext.save()
        }
    }

    private func askExpertAboutColors() {
        let names = room.orderedSavedColors
            .map { $0.detailLine.isEmpty ? $0.name : "\($0.name) (\($0.detailLine))" }
            .joined(separator: ", ")
        router.askExpert("I'm deciding between these colors for my \(room.name.lowercased()): \(names). Which would you recommend, and what should I consider?")
    }
}
