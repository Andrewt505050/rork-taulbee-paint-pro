//
//  ReminderEditorView.swift
//  TaulbeePainting
//
//  Create or edit a maintenance reminder: category, related room or surface,
//  due date, recurrence, priority, and notes. Notification permission is
//  requested only when the first reminder is created.
//

import SwiftUI
import SwiftData

struct ReminderEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \PaintRoom.name) private var rooms: [PaintRoom]

    /// Existing reminder to edit, or nil to create a new one.
    let existing: PaintReminder?

    @State private var title: String
    @State private var detail: String
    @State private var category: ReminderCategory
    @State private var selectedRoom: PaintRoom?
    @State private var surfaceLabel: String
    @State private var dueDate: Date
    @State private var recurrence: ReminderRecurrence
    @State private var customDays: Int
    @State private var priority: ReminderPriority
    @State private var notes: String

    private let surfaceOptions = ["Walls", "Ceiling", "Trim", "Doors", "Cabinets", "Exterior", "Deck", "Fence", "Front Door"]

    init(existing: PaintReminder? = nil, room: PaintRoom? = nil) {
        self.existing = existing
        _title = State(initialValue: existing?.title ?? "")
        _detail = State(initialValue: existing?.detail ?? "")
        _category = State(initialValue: existing?.category ?? .interiorTouchUp)
        _selectedRoom = State(initialValue: existing?.room ?? room)
        _surfaceLabel = State(initialValue: existing?.surfaceLabel ?? "")
        _dueDate = State(initialValue: existing?.dueDate ?? Calendar.current.date(byAdding: .month, value: 1, to: .now) ?? .now)
        _recurrence = State(initialValue: existing?.recurrence ?? .none)
        _customDays = State(initialValue: existing?.customIntervalDays ?? 180)
        _priority = State(initialValue: existing?.priority ?? .normal)
        _notes = State(initialValue: existing?.notes ?? "")
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    titleField
                    detailField
                    categorySection
                    linkSection
                    scheduleSection
                    prioritySection
                    notesField
                    Color.clear.frame(height: 8)
                }
                .padding(16)
            }
            .background(Theme.canvas.ignoresSafeArea())
            .navigationTitle(existing == nil ? "Add Reminder" : "Edit Reminder")
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
        }
    }

    // MARK: Fields

    private var titleField: some View {
        VStack(alignment: .leading, spacing: 8) {
            fieldLabel("Title")
            TextField("e.g. Check deck stain", text: $title)
                .font(.system(size: 16))
                .padding(14)
                .background(Theme.surface, in: .rect(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.hairline, lineWidth: 1))
        }
    }

    private var detailField: some View {
        VStack(alignment: .leading, spacing: 8) {
            fieldLabel("Description")
            TextField("What should you look for?", text: $detail, axis: .vertical)
                .font(.system(size: 15))
                .lineLimit(2...5)
                .padding(14)
                .background(Theme.surface, in: .rect(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.hairline, lineWidth: 1))
        }
    }

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            fieldLabel("Category")
            Menu {
                ForEach(ReminderCategory.allCases) { option in
                    Button {
                        category = option
                    } label: {
                        Label(option.label, systemImage: option.systemImage)
                    }
                }
            } label: {
                menuRow(icon: category.systemImage, tint: category.tint, text: category.label)
            }
        }
    }

    private var linkSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            fieldLabel("Related room or surface")
            VStack(spacing: 10) {
                Menu {
                    Button("No room") { selectedRoom = nil }
                    ForEach(rooms) { room in
                        Button {
                            selectedRoom = room
                        } label: {
                            Label(room.name, systemImage: room.roomType.systemImage)
                        }
                    }
                } label: {
                    menuRow(
                        icon: selectedRoom?.roomType.systemImage ?? "door.left.hand.open",
                        tint: Theme.brand,
                        text: selectedRoom?.name ?? (rooms.isEmpty ? "No rooms in your Vault yet" : "Link a room (optional)")
                    )
                }
                .disabled(rooms.isEmpty)
                .opacity(rooms.isEmpty ? 0.6 : 1)

                Menu {
                    Button("No surface") { surfaceLabel = "" }
                    ForEach(surfaceOptions, id: \.self) { option in
                        Button(option) { surfaceLabel = option }
                    }
                } label: {
                    menuRow(
                        icon: "square.dashed",
                        tint: Theme.lavenderAccent,
                        text: surfaceLabel.isEmpty ? "Surface (optional)" : surfaceLabel
                    )
                }
            }
        }
    }

    private var scheduleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            fieldLabel("Schedule")
            VStack(spacing: 0) {
                DatePicker(selection: $dueDate, in: Date.now..., displayedComponents: .date) {
                    Text("Due date")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Theme.ink)
                }
                .tint(Theme.brand)

                Divider().padding(.vertical, 12)

                HStack {
                    Text("Repeats")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Theme.ink)
                    Spacer()
                    Menu {
                        ForEach(ReminderRecurrence.allCases) { option in
                            Button(option.label) { recurrence = option }
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Text(recurrence.label)
                                .font(.system(size: 14, weight: .bold))
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .foregroundStyle(Theme.brand)
                    }
                }

                if recurrence == .custom {
                    Divider().padding(.vertical, 12)
                    Stepper(value: $customDays, in: 7...1095, step: 7) {
                        Text("Every \(customDays) days")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Theme.ink)
                    }
                }
            }
            .padding(14)
            .background(Theme.surface, in: .rect(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.hairline, lineWidth: 1))
        }
    }

    private var prioritySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            fieldLabel("Priority")
            HStack(spacing: 8) {
                ForEach(ReminderPriority.allCases) { option in
                    Button {
                        Haptics.tap()
                        withAnimation(.snappy(duration: 0.2)) { priority = option }
                    } label: {
                        Text(option.label)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(priority == option ? .white : option.tint)
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .background(
                                priority == option ? AnyShapeStyle(option.tint) : AnyShapeStyle(option.tint.opacity(0.12)),
                                in: .rect(cornerRadius: 12)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var notesField: some View {
        VStack(alignment: .leading, spacing: 8) {
            fieldLabel("Notes")
            TextField("Anything to remember when this comes due…", text: $notes, axis: .vertical)
                .font(.system(size: 15))
                .lineLimit(2...6)
                .padding(14)
                .background(Theme.surface, in: .rect(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.hairline, lineWidth: 1))
        }
    }

    private func menuRow(icon: String, tint: Color, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: 32, height: 32)
                .background(tint.opacity(0.12), in: .rect(cornerRadius: 10))
            Text(text)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.ink)
                .lineLimit(1)
            Spacer(minLength: 6)
            Image(systemName: "chevron.up.chevron.down")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Theme.inkSecondary.opacity(0.6))
        }
        .padding(.horizontal, 12)
        .frame(height: 52)
        .background(Theme.surface, in: .rect(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.hairline, lineWidth: 1))
        .contentShape(.rect(cornerRadius: 14))
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 12, weight: .heavy))
            .tracking(1)
            .foregroundStyle(Theme.inkSecondary)
    }

    // MARK: Save

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        Haptics.success()

        Task {
            await ReminderNotificationService.ensurePermission()

            let reminder: PaintReminder
            let isNew = existing == nil
            if let existing {
                reminder = existing
                ReminderNotificationService.cancel(existing.notificationId)
            } else {
                reminder = PaintReminder(title: trimmed, dueDate: dueDate)
                modelContext.insert(reminder)
            }

            reminder.title = trimmed
            reminder.detail = detail
            reminder.category = category
            reminder.room = selectedRoom
            reminder.surfaceLabel = surfaceLabel
            reminder.dueDate = dueDate
            reminder.recurrence = recurrence
            reminder.customIntervalDays = customDays
            reminder.priority = priority
            reminder.notes = notes

            if isNew {
                ActivityEvent.log(.reminderCreated, title: trimmed, detail: reminder.whereText, in: modelContext)
            }
            try? modelContext.save()
            await ReminderNotificationService.schedule(for: reminder)
            dismiss()
        }
    }
}
