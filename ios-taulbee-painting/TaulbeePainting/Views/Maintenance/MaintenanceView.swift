//
//  MaintenanceView.swift
//  TaulbeePainting
//
//  Care Reminders: helps homeowners remember when to inspect, touch up,
//  clean, and maintain painted surfaces — organized by urgency, with a
//  one-tap Recommended Care Schedule.
//

import SwiftUI
import SwiftData

struct MaintenanceView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PaintReminder.dueDate) private var reminders: [PaintReminder]

    @State private var showEditor = false
    @State private var showEstimate = false

    private var overdue: [PaintReminder] { reminders.filter { $0.status == .overdue } }
    private var dueSoon: [PaintReminder] { reminders.filter { $0.status == .dueSoon } }
    private var upcoming: [PaintReminder] { reminders.filter { $0.status == .upcoming } }
    private var completed: [PaintReminder] {
        reminders
            .filter { $0.completedAt != nil }
            .sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
    }

    private var activeReminders: [PaintReminder] { reminders.filter { $0.completedAt == nil } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                intro
                if activeReminders.isEmpty && completed.isEmpty {
                    emptyState
                } else {
                    if !overdue.isEmpty { section("Overdue", items: overdue, tint: ReminderStatus.overdue.tint) }
                    if !dueSoon.isEmpty { section("Due Soon", items: dueSoon, tint: ReminderStatus.dueSoon.tint) }
                    if !upcoming.isEmpty { section("Upcoming", items: upcoming, tint: Theme.brand) }
                }
                careSchedule
                helpCard
                if !completed.isEmpty { completedSection }
                Color.clear.frame(height: 16)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .background(Theme.canvas.ignoresSafeArea())
        .navigationTitle("Maintenance")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Haptics.tap()
                    showEditor = true
                } label: {
                    Image(systemName: "plus")
                        .fontWeight(.bold)
                        .foregroundStyle(Theme.brand)
                }
                .accessibilityLabel("Add reminder")
            }
        }
        .sheet(isPresented: $showEditor) {
            ReminderEditorView()
        }
        .sheet(isPresented: $showEstimate) {
            RequestEstimateView(contextLine: "Regarding: help with paint maintenance")
        }
    }

    // MARK: Intro

    private var intro: some View {
        HStack(spacing: 13) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(Theme.brand)
                .frame(width: 48, height: 48)
                .background(Theme.lavender, in: .rect(cornerRadius: 15))
            VStack(alignment: .leading, spacing: 3) {
                Text("Care Reminders")
                    .font(.system(size: 17, weight: .heavy))
                    .foregroundStyle(Theme.ink)
                Text("Stay ahead of touch-ups, caulk, and seasonal checks — your paint lasts longer.")
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(Theme.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .paintCard(padding: 14)
    }

    // MARK: Sections

    private func section(_ title: String, items: [PaintReminder], tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 17, weight: .heavy))
                    .foregroundStyle(Theme.ink)
                Text("\(items.count)")
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundStyle(tint)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(tint.opacity(0.12), in: .capsule)
            }
            VStack(spacing: 10) {
                ForEach(items) { reminder in
                    NavigationLink(value: reminder) {
                        ReminderRow(reminder: reminder)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button {
                            withAnimation { reminder.complete(in: modelContext) }
                            Haptics.success()
                        } label: {
                            Label("Mark Complete", systemImage: "checkmark.circle")
                        }
                        Button(role: .destructive) {
                            delete(reminder)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
    }

    private var completedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Completed")
                .font(.system(size: 17, weight: .heavy))
                .foregroundStyle(Theme.ink)
            VStack(spacing: 10) {
                ForEach(completed.prefix(8)) { reminder in
                    NavigationLink(value: reminder) {
                        ReminderRow(reminder: reminder)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(role: .destructive) {
                            delete(reminder)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
    }

    // MARK: Care schedule

    private var availableTemplates: [CareTemplate] {
        CareTemplate.all.filter { template in
            !activeReminders.contains { $0.title == template.title }
        }
    }

    @ViewBuilder
    private var careSchedule: some View {
        if !availableTemplates.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Recommended Care Schedule")
                        .font(.system(size: 17, weight: .heavy))
                        .foregroundStyle(Theme.ink)
                    Text("One tap adds the checks Taulbee recommends for every home.")
                        .font(.system(size: 12.5, weight: .medium))
                        .foregroundStyle(Theme.inkSecondary)
                }
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(availableTemplates) { template in
                            templateCard(template)
                        }
                    }
                    .padding(.horizontal, 2)
                    .padding(.vertical, 2)
                }
                .scrollClipDisabled()
            }
        }
    }

    private func templateCard(_ template: CareTemplate) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: template.category.systemImage)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(template.category.tint)
                    .frame(width: 36, height: 36)
                    .background(template.category.tint.opacity(0.12), in: .rect(cornerRadius: 11))
                Spacer()
                Text(template.recurrence.short)
                    .font(.system(size: 10.5, weight: .heavy))
                    .foregroundStyle(Theme.brand)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Theme.lavender, in: .capsule)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(template.title)
                    .font(.system(size: 13.5, weight: .bold))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Text(template.detail)
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundStyle(Theme.inkSecondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            Button {
                add(template)
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .bold))
                    Text("Add Reminder")
                        .font(.system(size: 12.5, weight: .bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background(Theme.brandGradient, in: .capsule)
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(14)
        .frame(width: 220, height: 196, alignment: .topLeading)
        .background(Theme.surface, in: .rect(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Theme.hairline, lineWidth: 1))
        .shadow(color: .black.opacity(0.04), radius: 10, y: 5)
    }

    // MARK: Help card

    private var helpCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Need help with this?")
                    .font(.system(size: 17, weight: .heavy))
                    .foregroundStyle(.white)
                Text("Send us what you're seeing — we'll take a look and tell you what it needs.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Button {
                Haptics.tap()
                showEstimate = true
            } label: {
                HStack(spacing: 7) {
                    Image(systemName: "paintbrush.pointed.fill")
                        .font(.system(size: 14, weight: .bold))
                    Text("Request Help")
                        .font(.system(size: 15, weight: .bold))
                }
                .foregroundStyle(Theme.brand)
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background(.white, in: .rect(cornerRadius: 13))
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background { HeroBackground() }
        .clipShape(.rect(cornerRadius: Theme.cardRadius))
        .shadow(color: Theme.brand.opacity(0.25), radius: 14, y: 8)
    }

    // MARK: Empty state

    private var emptyState: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Theme.lavender)
                    .frame(width: 84, height: 84)
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(Theme.brand)
            }
            VStack(spacing: 5) {
                Text("No reminders yet")
                    .font(.system(size: 17, weight: .heavy))
                    .foregroundStyle(Theme.ink)
                Text("Add reminders for touch-ups, exterior checks, caulking, and seasonal paint maintenance.")
                    .font(.system(size: 13.5, weight: .medium))
                    .foregroundStyle(Theme.inkSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Button {
                Haptics.tap()
                showEditor = true
            } label: {
                HStack(spacing: 7) {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .bold))
                    Text("Add First Reminder")
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .frame(height: 42)
                .background(Theme.brandGradient, in: .capsule)
                .shadow(color: Theme.brand.opacity(0.25), radius: 10, y: 5)
            }
            .buttonStyle(ScaleButtonStyle())
            .padding(.top, 2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 26)
        .paintCard()
    }

    // MARK: Actions

    private func add(_ template: CareTemplate) {
        Haptics.success()
        Task {
            await ReminderNotificationService.ensurePermission()
            let reminder = PaintReminder(
                title: template.title,
                detail: template.detail,
                category: template.category,
                dueDate: template.suggestedDueDate,
                recurrence: template.recurrence
            )
            modelContext.insert(reminder)
            ActivityEvent.log(.reminderCreated, title: template.title, in: modelContext)
            try? modelContext.save()
            await ReminderNotificationService.schedule(for: reminder)
        }
    }

    private func delete(_ reminder: PaintReminder) {
        Haptics.warning()
        ReminderNotificationService.cancel(reminder.notificationId)
        withAnimation {
            modelContext.delete(reminder)
            try? modelContext.save()
        }
    }
}

// MARK: - Reminder row (shared)

struct ReminderRow: View {
    let reminder: PaintReminder
    var showRoom: Bool = true

    var body: some View {
        HStack(spacing: 13) {
            Image(systemName: reminder.category.systemImage)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(reminder.category.tint)
                .frame(width: 42, height: 42)
                .background(reminder.category.tint.opacity(0.12), in: .rect(cornerRadius: 13))
            VStack(alignment: .leading, spacing: 3) {
                Text(reminder.title)
                    .font(.system(size: 14.5, weight: .bold))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                Text(metaLine)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.inkSecondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 6)
            HStack(spacing: 4) {
                Image(systemName: reminder.status.systemImage)
                    .font(.system(size: 9, weight: .bold))
                Text(reminder.status.label)
                    .font(.system(size: 10.5, weight: .heavy))
            }
            .foregroundStyle(reminder.status.tint)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(reminder.status.tint.opacity(0.12), in: .capsule)
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Theme.inkSecondary.opacity(0.45))
        }
        .padding(11)
        .background(Theme.surface, in: .rect(cornerRadius: 17))
        .overlay(
            RoundedRectangle(cornerRadius: 17)
                .stroke(reminder.status == .overdue ? reminder.status.tint.opacity(0.45) : Theme.hairline,
                        lineWidth: reminder.status == .overdue ? 1.5 : 1)
        )
        .shadow(color: .black.opacity(0.04), radius: 8, y: 4)
        .contentShape(.rect(cornerRadius: 17))
    }

    private var metaLine: String {
        var parts: [String] = []
        if reminder.completedAt != nil, let done = reminder.completedAt {
            parts.append("Completed \(done.formatted(.dateTime.month(.abbreviated).day()))")
        } else {
            parts.append(reminder.dueText)
        }
        if showRoom, !reminder.whereText.isEmpty {
            parts.append(reminder.whereText)
        }
        if reminder.recurrence != .none {
            parts.append(reminder.recurrence.short)
        }
        return parts.joined(separator: " · ")
    }
}
