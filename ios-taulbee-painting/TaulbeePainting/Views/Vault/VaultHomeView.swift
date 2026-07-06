//
//  VaultHomeView.swift
//  TaulbeePainting
//
//  The Vault: a private, on-device project history that brings together
//  saved scans, visualizations, documents and quotes in one organized place.
//

import SwiftUI
import SwiftData

enum VaultFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case scans = "Scans"
    case visualizations = "Visualizations"
    case docs = "Docs"
    case quotes = "Quotes"

    var id: String { rawValue }
}

struct VaultHomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \HomeRecord.updatedAt, order: .reverse) private var records: [HomeRecord]
    @Query(sort: \PaintScan.createdAt, order: .reverse) private var scans: [PaintScan]
    @Query(sort: \VisionProject.createdAt, order: .reverse) private var projects: [VisionProject]

    @State private var filter: VaultFilter = .all
    @State private var showEditor = false

    private var docRecords: [HomeRecord] { records.filter { $0.category != .contract } }
    private var quoteRecords: [HomeRecord] { records.filter { $0.category == .contract } }

    private var isEmpty: Bool { records.isEmpty && scans.isEmpty && projects.isEmpty }

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
                        if showScans { scansSection }
                        if showVisualizations { visualizationsSection }
                        if showDocs { docsSection }
                        if showQuotes { quotesSection }
                        if !showScans && !showVisualizations && !showDocs && !showQuotes {
                            noMatchState
                        }
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
        }
        .sheet(isPresented: $showEditor) {
            RecordEditorView()
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Vault")
                    .font(.system(size: 26, weight: .heavy))
                    .foregroundStyle(Theme.ink)
                Text("Your projects, saved and organized.")
                    .font(.system(size: 13.5, weight: .medium))
                    .foregroundStyle(Theme.inkSecondary)
            }
            Spacer()
            Button {
                Haptics.tap()
                showEditor = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(Theme.brandGradient, in: .circle)
                    .shadow(color: Theme.brand.opacity(0.3), radius: 8, y: 4)
            }
            .buttonStyle(.plain)
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
                Text("Request an estimate from the More tab and it’ll land here.")
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(Theme.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .paintCard()
    }

    // MARK: Empty states

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "tray.full.fill")
                .font(.system(size: 36))
                .foregroundStyle(Theme.brand.opacity(0.55))
            Text("Your vault is empty")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Theme.ink)
            Text("Save scans, visualizations, documents and quotes to keep your whole project in one safe place.")
                .font(.system(size: 14))
                .foregroundStyle(Theme.inkSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .paintCard()
    }

    private var noMatchState: some View {
        Text("Nothing here yet.")
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(Theme.inkSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 30)
    }

    private func delete(_ record: HomeRecord) {
        Haptics.warning()
        withAnimation {
            modelContext.delete(record)
            try? modelContext.save()
        }
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
