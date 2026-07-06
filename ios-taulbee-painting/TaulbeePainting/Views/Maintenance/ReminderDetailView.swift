//
//  ReminderDetailView.swift
//  TaulbeePainting
//
//  One reminder in full: status, schedule, description, and notes — with
//  Mark Complete, Ask an Expert, and Request Help actions. Overdue reminders
//  add a soft "Want us to take a look?" prompt.
//

import SwiftUI
import SwiftData

struct ReminderDetailView: View {
    let reminder: PaintReminder

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(AppRouter.self) private var router

    @State private var showEditor = false
    @State private var showEstimate = false
    @State private var confirmDelete = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                headerCard
                if reminder.status == .overdue { overduePrompt }
                scheduleCard
                if !reminder.detail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    descriptionCard
                }
                if !reminder.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    notesCard
                }
                actions
                Color.clear.frame(height: 12)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .background(Theme.canvas.ignoresSafeArea())
        .navigationTitle("Reminder")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showEditor = true
                    } label: {
                        Label("Edit Reminder", systemImage: "pencil")
                    }
                    Button(role: .destructive) {
                        confirmDelete = true
                    } label: {
                        Label("Delete Reminder", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(Theme.brand)
                }
            }
        }
        .sheet(isPresented: $showEditor) {
            ReminderEditorView(existing: reminder)
        }
        .sheet(isPresented: $showEstimate) {
            RequestEstimateView(
                contextLine: "Regarding maintenance: \(reminder.title)",
                prefilledRoomName: reminder.room?.name
            )
        }
        .confirmationDialog("Delete this reminder?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                Haptics.warning()
                ReminderNotificationService.cancel(reminder.notificationId)
                modelContext.delete(reminder)
                try? modelContext.save()
                dismiss()
            }
            Button("Cancel", role: .cancel) { }
        }
    }

    // MARK: Header

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: reminder.category.systemImage)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(reminder.category.tint)
                    .frame(width: 48, height: 48)
                    .background(reminder.category.tint.opacity(0.12), in: .rect(cornerRadius: 14))
                Spacer()
                HStack(spacing: 5) {
                    Image(systemName: reminder.status.systemImage)
                        .font(.system(size: 11, weight: .bold))
                    Text(reminder.status.label)
                        .font(.system(size: 12, weight: .heavy))
                }
                .foregroundStyle(reminder.status.tint)
                .padding(.horizontal, 11)
                .padding(.vertical, 6)
                .background(reminder.status.tint.opacity(0.12), in: .capsule)
            }
            Text(reminder.title)
                .font(.system(size: 22, weight: .heavy))
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 6) {
                Text(reminder.category.label)
                    .font(.system(size: 11.5, weight: .bold))
                    .foregroundStyle(reminder.category.tint)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(reminder.category.tint.opacity(0.12), in: .capsule)
                Text(reminder.priority.label + " priority")
                    .font(.system(size: 11.5, weight: .bold))
                    .foregroundStyle(reminder.priority.tint)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(reminder.priority.tint.opacity(0.12), in: .capsule)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .paintCard()
    }

    // MARK: Overdue prompt

    private var overduePrompt: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "person.badge.shield.checkmark.fill")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Theme.brand)
                .frame(width: 40, height: 40)
                .background(Theme.lavender, in: .circle)
            VStack(alignment: .leading, spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Want us to take a look?")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Theme.ink)
                    Text("This one's past due — Taulbee Painting can check it out and handle whatever it needs.")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Theme.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Button {
                    Haptics.tap()
                    showEstimate = true
                } label: {
                    Text("Request Help")
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
        .padding(16)
        .background(Theme.brand.opacity(0.06), in: .rect(cornerRadius: Theme.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cardRadius)
                .stroke(Theme.brand.opacity(0.18), lineWidth: 1)
        )
    }

    // MARK: Schedule

    private var scheduleCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionLabel(icon: "calendar", title: "Schedule")
            VStack(spacing: 12) {
                metaRow(icon: "calendar", label: "Due date", value: reminder.dueDate.formatted(.dateTime.weekday(.wide).month().day()))
                metaRow(icon: "repeat", label: "Repeats", value: reminder.recurrence == .custom ? "Every \(reminder.customIntervalDays) days" : reminder.recurrence.label)
                if let room = reminder.room {
                    metaRow(icon: room.roomType.systemImage, label: "Room", value: room.name)
                }
                if !reminder.surfaceLabel.isEmpty {
                    metaRow(icon: "square.dashed", label: "Surface", value: reminder.surfaceLabel)
                }
                if let completedAt = reminder.completedAt {
                    metaRow(icon: "checkmark.circle.fill", label: "Completed", value: completedAt.formatted(.dateTime.month().day().year()))
                }
            }
            if reminder.completedAt != nil, reminder.recurrence != .none {
                Text("The next check was added to your schedule automatically.")
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(ReminderStatus.completed.tint)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .paintCard()
    }

    private func metaRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Theme.brand)
                .frame(width: 30, height: 30)
                .background(Theme.lavender, in: .rect(cornerRadius: 9))
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Theme.inkSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.trailing)
        }
    }

    // MARK: Description & notes

    private var descriptionCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionLabel(icon: "text.alignleft", title: "What to check")
            Text(reminder.detail)
                .font(.system(size: 14.5))
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .paintCard()
    }

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionLabel(icon: "square.and.pencil", title: "Notes")
            Text(reminder.notes)
                .font(.system(size: 14.5))
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .paintCard()
    }

    // MARK: Actions

    private var actions: some View {
        VStack(spacing: 12) {
            if reminder.completedAt == nil {
                PrimaryButton(title: "Mark Complete", systemImage: "checkmark.circle.fill") {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        reminder.complete(in: modelContext)
                    }
                    Haptics.success()
                }
            }
            PrimaryButton(title: "Ask an Expert", systemImage: "bubble.left.and.text.bubble.right.fill", fill: false) {
                askExpert()
            }
            PrimaryButton(title: "Request Help", systemImage: "envelope.fill", fill: false) {
                showEstimate = true
            }
        }
        .padding(.top, 4)
    }

    private func askExpert() {
        var question = "\(reminder.title): what should I look for, and how do I handle what I find?"
        if let room = reminder.room {
            question = "\(reminder.title) for my \(room.name.lowercased()): what should I look for, and how do I handle what I find?"
        }
        router.askExpert(question)
    }
}
