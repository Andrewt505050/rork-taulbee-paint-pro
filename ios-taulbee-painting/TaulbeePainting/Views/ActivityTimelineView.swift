//
//  ActivityTimelineView.swift
//  TaulbeePainting
//
//  The complete homeowner history: scans, visualizations, expert questions,
//  rooms, colors, reminders, photos, and estimate requests — grouped by day.
//

import SwiftUI
import SwiftData

struct ActivityTimelineView: View {
    @Query(sort: \ActivityEvent.createdAt, order: .reverse) private var events: [ActivityEvent]
    @Query(sort: \PaintScan.createdAt, order: .reverse) private var scans: [PaintScan]
    @Query(sort: \VisionProject.createdAt, order: .reverse) private var projects: [VisionProject]
    @Query(sort: \ChatMessage.createdAt, order: .reverse) private var messages: [ChatMessage]

    private var items: [ActivityItem] {
        var result: [ActivityItem] = []
        result += events.map {
            ActivityItem(id: "event-\($0.id)", title: $0.title, date: $0.createdAt, kind: ActivityKind(eventType: $0.type), scan: nil)
        }
        result += scans.map {
            ActivityItem(id: "scan-\($0.id)", title: $0.defectName, date: $0.createdAt, kind: .defect, scan: $0)
        }
        result += projects.map {
            ActivityItem(id: "vision-\($0.id)", title: "\($0.colorName) Visualization", date: $0.createdAt, kind: .vision, scan: nil)
        }
        result += messages.filter { $0.role == .user }.map {
            ActivityItem(id: "chat-\($0.id)", title: $0.text, date: $0.createdAt, kind: .expert, scan: nil)
        }
        return result.sorted { $0.date > $1.date }
    }

    private var grouped: [(day: Date, items: [ActivityItem])] {
        let groups = Dictionary(grouping: items) { Calendar.current.startOfDay(for: $0.date) }
        return groups.keys.sorted(by: >).map { (day: $0, items: groups[$0] ?? []) }
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                if items.isEmpty {
                    emptyState
                } else {
                    ForEach(grouped, id: \.day) { group in
                        VStack(alignment: .leading, spacing: 10) {
                            Text(dayLabel(group.day))
                                .font(.system(size: 13, weight: .heavy))
                                .tracking(0.6)
                                .foregroundStyle(Theme.inkSecondary)
                                .padding(.leading, 6)
                            VStack(spacing: 0) {
                                ForEach(Array(group.items.enumerated()), id: \.element.id) { index, item in
                                    row(for: item)
                                    if index < group.items.count - 1 {
                                        Divider().overlay(Theme.hairline).padding(.leading, 64)
                                    }
                                }
                            }
                            .paintCard(padding: 6, radius: 22)
                        }
                    }
                }
                Color.clear.frame(height: 16)
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
        }
        .background(Theme.canvas.ignoresSafeArea())
        .navigationTitle("Activity")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func row(for item: ActivityItem) -> some View {
        if let scan = item.scan {
            NavigationLink(value: scan) {
                ActivityRow(item: item)
            }
            .buttonStyle(.plain)
        } else {
            ActivityRow(item: item)
        }
    }

    private func dayLabel(_ day: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(day) { return "TODAY" }
        if calendar.isDateInYesterday(day) { return "YESTERDAY" }
        return day.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()).uppercased()
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 32))
                .foregroundStyle(Theme.brand.opacity(0.55))
            Text("Nothing here yet")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Theme.ink)
            Text("Scans, visualizations, rooms, colors, reminders, and estimate requests will all show up here.")
                .font(.system(size: 13.5, weight: .medium))
                .foregroundStyle(Theme.inkSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .paintCard()
    }
}
