//
//  VaultHomeView.swift
//  TaulbeePainting
//
//  The Paint Vault: room profiles, saved scans, visualizations, documents
//  and quotes in one private, organized place. "Never forget what color is
//  on your walls again."
//

import SwiftUI
import SwiftData

enum VaultFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case rooms = "Rooms"
    case scans = "Scans"
    case visualizations = "Visualizations"
    case docs = "Docs"
    case quotes = "Quotes"

    var id: String { rawValue }
}

struct VaultHomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PaintRoom.updatedAt, order: .reverse) private var rooms: [PaintRoom]
    @Query(sort: \HomeRecord.updatedAt, order: .reverse) private var records: [HomeRecord]
    @Query(sort: \PaintScan.createdAt, order: .reverse) private var scans: [PaintScan]
    @Query(sort: \VisionProject.createdAt, order: .reverse) private var projects: [VisionProject]

    @State private var filter: VaultFilter = .all
    @State private var showAddDialog = false
    @State private var showRecordEditor = false
    @State private var showRoomEditor = false
    @State private var pendingPricingRoom: PaintRoom?
    @State private var showPricingPrompt = false
    @State private var estimateRoom: PaintRoom?

    private var docRecords: [HomeRecord] { records.filter { $0.category != .contract } }
    private var quoteRecords: [HomeRecord] { records.filter { $0.category == .contract } }

    private var isEmpty: Bool { rooms.isEmpty && records.isEmpty && scans.isEmpty && projects.isEmpty }

    private var showRooms: Bool { filter == .all || filter == .rooms }
    private var showScans: Bool { (filter == .all || filter == .scans) && !scans.isEmpty }
    private var showVisualizations: Bool { (filter == .all || filter == .visualizations) && !projects.isEmpty }
    private var showDocs: Bool { (filter == .all || filter == .docs) && !docRecords.isEmpty }
    private var showQuotes: Bool { filter == .all || filter == .quotes }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    filterPills
                    if isEmpty {
                        emptyState
                    } else {
                        if showRooms { roomsSection }
                        if showScans { scansSection }
                        if showVisualizations { visualizationsSection }
                        if showDocs { docsSection }
                        if showQuotes { quotesSection }
                    }
                    Color.clear.frame(height: 16)
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)
            }
            .background(Theme.canvas.ignoresSafeArea())
            .navigationTitle("")
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: HomeRecord.self) { record in
                RecordDetailView(record: record)
            }
            .navigationDestination(for: PaintScan.self) { scan in
                ResultView(result: ScanResult(scan: scan))
            }
            .navigationDestination(for: VisionProject.self) { project in
                SavedProjectView(project: project)
            }
            .navigationDestination(for: PaintRoom.self) { room in
                RoomDetailView(room: room)
            }
            .navigationDestination(for: PaintReminder.self) { reminder in
                ReminderDetailView(reminder: reminder)
            }
            .navigationDestination(for: HubRoute.self) { route in
                switch route {
                case .maintenance:
                    MaintenanceView()
                case .timeline:
                    ActivityTimelineView()
                }
            }
        }
        .sheet(isPresented: $showRecordEditor) {
            RecordEditorView()
        }
        .sheet(isPresented: $showRoomEditor, onDismiss: {
            if pendingPricingRoom != nil { showPricingPrompt = true }
        }) {
            RoomEditorView(onSaved: { pendingPricingRoom = $0 })
        }
        .sheet(item: $estimateRoom) { room in
            RequestEstimateView(prefilledRoomName: room.name)
        }
        .confirmationDialog(
            "Want pricing for \(pendingPricingRoom?.name ?? "this room")?",
            isPresented: $showPricingPrompt,
            titleVisibility: .visible
        ) {
            Button("Request Estimate") {
                estimateRoom = pendingPricingRoom
                pendingPricingRoom = nil
            }
            Button("Not Now", role: .cancel) {
                pendingPricingRoom = nil
            }
        } message: {
            Text("Taulbee Painting can send you free, no-pressure pricing for this room.")
        }
        .confirmationDialog("Add to your Paint Vault", isPresented: $showAddDialog, titleVisibility: .visible) {
            Button("Add Room") { showRoomEditor = true }
            Button("Add Document or Record") { showRecordEditor = true }
            Button("Cancel", role: .cancel) { }
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Paint Vault")
                    .font(.system(size: 26, weight: .heavy))
                    .foregroundStyle(Theme.ink)
                Text("Never forget what color is on your walls again.")
                    .font(.system(size: 13.5, weight: .medium))
                    .foregroundStyle(Theme.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            HStack(spacing: 8) {
                NavigationLink(value: HubRoute.maintenance) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Theme.brand)
                        .frame(width: 42, height: 42)
                        .background(Theme.surface, in: .circle)
                        .overlay(Circle().stroke(Theme.hairline, lineWidth: 1))
                }
                .buttonStyle(ScaleButtonStyle(scale: 0.92))
                .accessibilityLabel("Maintenance reminders")

                Button {
                    Haptics.tap()
                    showAddDialog = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 42, height: 42)
                        .background(Theme.brandGradient, in: .circle)
                        .shadow(color: Theme.brand.opacity(0.3), radius: 8, y: 4)
                }
                .buttonStyle(ScaleButtonStyle(scale: 0.92))
                .accessibilityLabel("Add to vault")
            }
        }
        .padding(.top, 8)
    }

    // MARK: Filter pills

    private var filterPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(VaultFilter.allCases) { item in
                    Button {
                        Haptics.tap()
                        withAnimation(.snappy(duration: 0.2)) { filter = item }
                    } label: {
                        Text(item.rawValue)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(filter == item ? .white : Theme.brand)
                            .padding(.horizontal, 16)
                            .frame(height: 38)
                            .background(
                                filter == item ? AnyShapeStyle(Theme.brandGradient) : AnyShapeStyle(Theme.lavender),
                                in: .capsule
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 2)
        }
        .scrollClipDisabled()
    }

    // MARK: Sections

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 17, weight: .heavy))
            .foregroundStyle(Theme.ink)
    }

    @ViewBuilder
    private var roomsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Rooms")
            if rooms.isEmpty {
                roomsEmpty
            } else {
                ForEach(rooms.prefix(filter == .rooms ? 50 : 4)) { room in
                    NavigationLink(value: room) { RoomCard(room: room) }
                        .buttonStyle(.plain)
                }
                if filter == .rooms {
                    addRoomButton
                }
            }
        }
    }

    private var roomsEmpty: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "door.left.hand.open")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Theme.brand)
                    .frame(width: 44, height: 44)
                    .background(Theme.lavender, in: .circle)
                VStack(alignment: .leading, spacing: 2) {
                    Text("No rooms yet")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Theme.ink)
                    Text("Save each room's colors, photos, and touch-up notes.")
                        .font(.system(size: 12.5, weight: .medium))
                        .foregroundStyle(Theme.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            addRoomButton
        }
        .paintCard()
    }

    private var addRoomButton: some View {
        Button {
            Haptics.tap()
            showRoomEditor = true
        } label: {
            HStack(spacing: 7) {
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .bold))
                Text("Add Room")
                    .font(.system(size: 14, weight: .bold))
            }
            .foregroundStyle(Theme.brand)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(Theme.lavender, in: .rect(cornerRadius: 14))
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private var scansSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Saved Scans")
            ForEach(scans.prefix(filter == .scans ? 50 : 4)) { scan in
                NavigationLink(value: scan) { ScanRow(scan: scan) }
                    .buttonStyle(.plain)
            }
        }
    }

    private var visualizationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Saved Visualizations")
            ForEach(projects.prefix(filter == .visualizations ? 50 : 4)) { project in
                NavigationLink(value: project) { ProjectRow(project: project) }
                    .buttonStyle(.plain)
            }
        }
    }

    private var docsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Documents")
            ForEach(docRecords.prefix(filter == .docs ? 50 : 4)) { record in
                NavigationLink(value: record) { RecordRow(record: record) }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(role: .destructive) { delete(record) } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
        }
    }

    @ViewBuilder
    private var quotesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Quotes")
            if quoteRecords.isEmpty {
                quotesEmpty
            } else {
                ForEach(quoteRecords.prefix(filter == .quotes ? 50 : 4)) { record in
                    NavigationLink(value: record) { RecordRow(record: record) }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button(role: .destructive) { delete(record) } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
        }
    }

    private var quotesEmpty: some View {
        HStack(spacing: 12) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Theme.brand)
                .frame(width: 44, height: 44)
                .background(Theme.lavender, in: .circle)
            VStack(alignment: .leading, spacing: 2) {
                Text("No quotes yet")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Theme.ink)
                Text("Request an estimate and save the quote here when it arrives.")
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(Theme.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .paintCard()
    }

    // MARK: Empty state

    private var emptyState: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Theme.lavender)
                    .frame(width: 84, height: 84)
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(Theme.brand)
            }
            VStack(spacing: 5) {
                Text("Your Paint Vault is empty")
                    .font(.system(size: 17, weight: .heavy))
                    .foregroundStyle(Theme.ink)
                Text("Save rooms, colors, project photos, and touch-up notes in one place.")
                    .font(.system(size: 13.5, weight: .medium))
                    .foregroundStyle(Theme.inkSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Button {
                Haptics.tap()
                showRoomEditor = true
            } label: {
                HStack(spacing: 7) {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .bold))
                    Text("Add First Room")
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

    private func delete(_ record: HomeRecord) {
        Haptics.warning()
        withAnimation {
            modelContext.delete(record)
            try? modelContext.save()
        }
    }
}

// MARK: - Room card

struct RoomCard: View {
    let room: PaintRoom

    var body: some View {
        HStack(spacing: 14) {
            thumbnail
            VStack(alignment: .leading, spacing: 5) {
                Text(room.name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                Text("Last painted: \(room.lastPaintedText)")
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(Theme.inkSecondary)
                HStack(spacing: 8) {
                    if !room.orderedSavedColors.isEmpty {
                        HStack(spacing: 4) {
                            HStack(spacing: -4) {
                                ForEach(room.orderedSavedColors.prefix(4)) { color in
                                    Circle()
                                        .fill(color.swatch)
                                        .frame(width: 14, height: 14)
                                        .overlay(Circle().stroke(Theme.surface, lineWidth: 1.5))
                                }
                            }
                            Text("\(room.savedColors.count) color\(room.savedColors.count == 1 ? "" : "s")")
                                .font(.system(size: 11.5, weight: .semibold))
                                .foregroundStyle(Theme.inkSecondary)
                        }
                    }
                    if let next = room.nextReminder {
                        HStack(spacing: 3) {
                            Image(systemName: "bell.fill")
                                .font(.system(size: 9, weight: .bold))
                            Text(next.dueText)
                                .font(.system(size: 11.5, weight: .semibold))
                        }
                        .foregroundStyle(next.status.tint)
                    }
                }
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Theme.inkSecondary.opacity(0.5))
        }
        .padding(12)
        .background(Theme.surface, in: .rect(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Theme.hairline, lineWidth: 1))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 4)
        .contentShape(.rect(cornerRadius: 18))
    }

    private var thumbnail: some View {
        Theme.lavender
            .frame(width: 58, height: 58)
            .overlay {
                if let data = room.orderedPhotos.first?.data, let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .allowsHitTesting(false)
                } else if room.hasCurrentColor && !room.currentColorHex.isEmpty {
                    Color(hex: room.currentColorHex)
                } else {
                    Image(systemName: room.roomType.systemImage)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(Theme.brand)
                }
            }
            .clipShape(.rect(cornerRadius: 13))
    }
}

// MARK: - Record row

struct RecordRow: View {
    let record: HomeRecord

    var body: some View {
        HStack(spacing: 14) {
            thumbnail
            VStack(alignment: .leading, spacing: 5) {
                Text(record.title.isEmpty ? "Untitled" : record.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    categoryBadge
                    if !record.room.isEmpty {
                        Text(record.room)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Theme.inkSecondary)
                            .lineLimit(1)
                    }
                }
                if let expiryText {
                    Text(expiryText.text)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(expiryText.color)
                }
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Theme.inkSecondary.opacity(0.5))
        }
        .padding(12)
        .background(Theme.surface, in: .rect(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(record.isExpiringSoon || record.isExpired ? Theme.accent.opacity(0.6) : Theme.hairline,
                        lineWidth: record.isExpiringSoon || record.isExpired ? 1.5 : 1)
        )
        .shadow(color: .black.opacity(0.04), radius: 8, y: 4)
    }

    private var thumbnail: some View {
        Color(record.category.tint.opacity(0.14))
            .frame(width: 58, height: 58)
            .overlay {
                if let data = record.thumbnailData, let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .allowsHitTesting(false)
                } else if !record.colorHex.isEmpty {
                    Color(hex: record.colorHex)
                } else {
                    Image(systemName: record.category.systemImage)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(record.category.tint)
                }
            }
            .clipShape(.rect(cornerRadius: 13))
    }

    private var categoryBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: record.category.systemImage)
                .font(.system(size: 9, weight: .bold))
            Text(record.category.label)
                .font(.system(size: 11, weight: .bold))
        }
        .foregroundStyle(record.category.tint)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(record.category.tint.opacity(0.12), in: .capsule)
    }

    private var expiryText: (text: String, color: Color)? {
        guard let days = record.daysUntilExpiry else { return nil }
        if days < 0 {
            return ("Expired", Theme.accent)
        } else if days == 0 {
            return ("Expires today", Theme.accent)
        } else if days <= 30 {
            return ("Expires in \(days) day\(days == 1 ? "" : "s")", Theme.accent)
        }
        return nil
    }
}
