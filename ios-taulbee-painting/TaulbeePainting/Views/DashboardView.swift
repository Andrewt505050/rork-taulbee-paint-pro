//
//  DashboardView.swift
//  TaulbeePainting
//
//  Home / Dashboard — a premium hub: compact brand header with notifications,
//  a swipeable photo hero carousel, the dotted project path, icon-left quick
//  actions, and a unified recent-activity feed.
//

import SwiftUI
import SwiftData
import Combine

struct DashboardView: View {
    @Binding var selectedTab: AppTab
    @Binding var path: NavigationPath

    @Query(sort: \PaintScan.createdAt, order: .reverse) private var scans: [PaintScan]
    @Query(sort: \VisionProject.createdAt, order: .reverse) private var projects: [VisionProject]
    @Query(sort: \ChatMessage.createdAt, order: .reverse) private var messages: [ChatMessage]

    @AppStorage("homeNoticesSeen") private var noticesSeen = false
    @State private var showNotifications = false
    @State private var showHowItWorks = false

    // Hero carousel state
    @State private var heroID: Int? = 0
    @State private var heroInteracted = false
    @State private var autoTarget: Int?

    private let heroTimer = Timer.publish(every: 6.5, on: .main, in: .common).autoconnect()

    private var activity: [ActivityItem] {
        var items: [ActivityItem] = []
        items += scans.prefix(6).map {
            ActivityItem(id: "scan-\($0.id)", title: $0.defectName, date: $0.createdAt, kind: .defect, scan: $0)
        }
        items += projects.prefix(6).map {
            ActivityItem(id: "vision-\($0.id)", title: "\($0.colorName) Visualization", date: $0.createdAt, kind: .vision, scan: nil)
        }
        items += messages.filter { $0.role == .user }.prefix(6).map {
            ActivityItem(id: "chat-\($0.id)", title: $0.text, date: $0.createdAt, kind: .expert, scan: nil)
        }
        return Array(items.sorted { $0.date > $1.date }.prefix(5))
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 26) {
                header
                heroCarousel
                projectPath
                quickActions
                activitySection
            }
            .padding(.horizontal, 16)
            .padding(.top, 6)
            .padding(.bottom, 16)
        }
        .background(Theme.canvas.ignoresSafeArea())
        .navigationTitle("")
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showNotifications) {
            NotificationsSheet(
                onVisualize: {
                    showNotifications = false
                    selectedTab = .visualize
                },
                onQuote: { requestQuote() }
            )
        }
        .sheet(isPresented: $showHowItWorks) {
            HowItWorksSheet {
                showHowItWorks = false
                selectedTab = .visualize
            }
        }
        .onReceive(heroTimer) { _ in
            guard selectedTab == .home, !heroInteracted, !showNotifications, !showHowItWorks else { return }
            let next = ((heroID ?? 0) + 1) % heroSlideCount
            autoTarget = next
            withAnimation(.easeInOut(duration: 0.5)) { heroID = next }
        }
        .onChange(of: heroID) { _, newValue in
            // A position change we didn't schedule means the user swiped.
            if let newValue, newValue != autoTarget {
                heroInteracted = true
            }
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: 12) {
            Image("Logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 44, height: 44)
            VStack(alignment: .leading, spacing: 2) {
                Text(BusinessInfo.name)
                    .font(.system(size: 17, weight: .heavy))
                    .foregroundStyle(Theme.ink)
                Text("Smarter paint projects")
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(Theme.inkSecondary)
            }
            Spacer()
            Button {
                Haptics.tap()
                noticesSeen = true
                showNotifications = true
            } label: {
                Image(systemName: "bell")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.brand)
                    .frame(width: 42, height: 42)
                    .background(Theme.surface, in: .circle)
                    .overlay(Circle().stroke(Theme.hairline, lineWidth: 1))
                    .overlay(alignment: .topTrailing) {
                        if !noticesSeen {
                            Circle()
                                .fill(Theme.brand)
                                .frame(width: 9, height: 9)
                                .overlay(Circle().stroke(Theme.surface, lineWidth: 2))
                                .offset(x: -8, y: 8)
                        }
                    }
                    .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
            }
            .buttonStyle(ScaleButtonStyle(scale: 0.92))
            .accessibilityLabel("Notifications")
        }
        .padding(.top, 4)
    }

    // MARK: Hero carousel

    private var heroSlideCount: Int { 3 }

    private var heroCarousel: some View {
        VStack(spacing: 12) {
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    HeroSlideCard(
                        eyebrow: "COLOR VISUALIZER",
                        headline: "See your room in a new color",
                        subtext: "Upload a photo, preview real paint colors, and save your favorites.",
                        imageName: "modern_living_room_lavender",
                        fallbackIcon: "wand.and.stars",
                        primaryTitle: "Start Visualizing",
                        primaryIcon: "wand.and.stars",
                        primaryAction: { selectedTab = .visualize },
                        secondaryTitle: "Ask a Paint Expert",
                        secondaryIcon: "bubble.left.and.text.bubble.right.fill",
                        secondaryAction: { selectedTab = .expert }
                    )
                    .containerRelativeFrame(.horizontal)
                    .id(0)

                    HeroSlideCard(
                        eyebrow: "DEFECT SCANNER",
                        headline: "Catch paint problems early",
                        subtext: "Snap a photo of peeling, cracking, or stains and get causes and fixes.",
                        imageName: "peeling_wall_window",
                        fallbackIcon: "camera.viewfinder",
                        primaryTitle: "Scan a Defect",
                        primaryIcon: "camera.viewfinder",
                        primaryAction: { path.append(ScanRoute.scanner) }
                    )
                    .containerRelativeFrame(.horizontal)
                    .id(1)

                    HeroSlideCard(
                        eyebrow: "PAINT EXPERT",
                        headline: "Real answers from painting pros",
                        subtext: "Ask anything about paint, prep, finishes, and color.",
                        imageName: "paint_swatch_fan_deck",
                        fallbackIcon: "bubble.left.and.text.bubble.right.fill",
                        primaryTitle: "Ask an Expert",
                        primaryIcon: "bubble.left.and.text.bubble.right.fill",
                        primaryAction: { selectedTab = .expert }
                    )
                    .containerRelativeFrame(.horizontal)
                    .id(2)
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollClipDisabled()
            .scrollPosition(id: $heroID)
            .frame(height: 324)

            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { index in
                    Capsule()
                        .fill(index == (heroID ?? 0) ? Theme.brand : Theme.hairline)
                        .frame(width: index == (heroID ?? 0) ? 20 : 6, height: 6)
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: heroID)
        }
    }

    // MARK: Project path

    private let steps: [PathStep] = [
        PathStep(id: 1, icon: "photo.badge.plus", title: "Upload Photo", subtitle: "Add your room"),
        PathStep(id: 2, icon: "paintpalette.fill", title: "Preview Colors", subtitle: "See it come to life"),
        PathStep(id: 3, icon: "heart.fill", title: "Save Favorites", subtitle: "Curate your picks"),
        PathStep(id: 4, icon: "envelope.fill", title: "Request Estimate", subtitle: "Get expert pricing")
    ]

    private var projectPath: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                Text("Project Path")
                    .font(.system(size: 17, weight: .heavy))
                    .foregroundStyle(Theme.ink)
                Spacer()
                Button {
                    Haptics.tap()
                    showHowItWorks = true
                } label: {
                    HStack(spacing: 3) {
                        Text("How it works")
                            .font(.system(size: 13, weight: .bold))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 9, weight: .bold))
                    }
                    .foregroundStyle(Theme.brand)
                }
                .buttonStyle(.plain)
            }

            HStack(alignment: .top, spacing: 0) {
                ForEach(steps) { step in
                    stepView(step)
                    if step.id != steps.count {
                        DottedLine()
                            .stroke(style: StrokeStyle(lineWidth: 1.6, lineCap: .round, dash: [2.5, 4.5]))
                            .foregroundStyle(Theme.lavenderAccent.opacity(0.65))
                            .frame(width: 14, height: 2)
                            .padding(.top, 22)
                    }
                }
            }
        }
        .paintCard(padding: 16, radius: 26)
    }

    private func stepView(_ step: PathStep) -> some View {
        Button {
            Haptics.tap()
            handleStep(step.id)
        } label: {
            VStack(spacing: 4) {
                Circle()
                    .fill(Theme.lavender)
                    .frame(width: 46, height: 46)
                    .overlay {
                        Image(systemName: step.icon)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Theme.brand)
                    }
                Text("\(step.id)")
                    .font(.system(size: 11, weight: .heavy))
                    .foregroundStyle(Theme.ink)
                    .padding(.top, 4)
                Text(step.title)
                    .font(.system(size: 11.5, weight: .bold))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                Text(step.subtitle)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Theme.inkSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .contentShape(.rect)
        }
        .buttonStyle(ScaleButtonStyle(scale: 0.94))
    }

    private func handleStep(_ id: Int) {
        switch id {
        case 1, 2: selectedTab = .visualize
        case 3: selectedTab = .vault
        default: requestQuote()
        }
    }

    // MARK: Quick actions

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle("Quick Actions")
            LazyVGrid(columns: columns, spacing: 12) {
                QuickActionTile(icon: "camera.viewfinder", title: "Scan a Defect", subtitle: "Find and flag painting issues") {
                    path.append(ScanRoute.scanner)
                }
                QuickActionTile(icon: "bubble.left.and.text.bubble.right.fill", title: "Ask an Expert", subtitle: "Get answers from our pros") {
                    selectedTab = .expert
                }
                QuickActionTile(icon: "lock.shield.fill", title: "View Vault", subtitle: "Your saved projects and photos") {
                    selectedTab = .vault
                }
                QuickActionTile(icon: "envelope.fill", title: "Request Estimate", subtitle: "Get a custom project estimate") {
                    requestQuote()
                }
            }
        }
    }

    // MARK: Activity

    private var activitySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                sectionTitle("Your Activity")
                Spacer()
                if !activity.isEmpty {
                    Button {
                        Haptics.tap()
                        selectedTab = .vault
                    } label: {
                        Text("See All")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Theme.brand)
                    }
                    .buttonStyle(.plain)
                }
            }
            if activity.isEmpty {
                emptyActivity
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(activity.enumerated()), id: \.element.id) { index, item in
                        Button {
                            Haptics.tap()
                            handleTap(item)
                        } label: {
                            ActivityRow(item: item)
                        }
                        .buttonStyle(.plain)
                        if index < activity.count - 1 {
                            Divider().overlay(Theme.hairline).padding(.leading, 64)
                        }
                    }
                }
                .paintCard(padding: 6, radius: 24)
            }
        }
    }

    private var emptyActivity: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Theme.lavender)
                    .frame(width: 84, height: 84)
                Image(systemName: "paintbrush.pointed.fill")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(Theme.brand)
                Image(systemName: "sparkle")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Theme.lavenderAccent)
                    .offset(x: 38, y: -28)
                Image(systemName: "sparkle")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(Theme.lavenderAccent)
                    .offset(x: -40, y: -12)
                Image(systemName: "sparkle")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Theme.lavenderAccent)
                    .offset(x: 42, y: 20)
            }
            VStack(spacing: 5) {
                Text("No activity yet")
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundStyle(Theme.ink)
                Text("Start by scanning a defect, visualizing a room, or asking an expert.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.inkSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Button {
                Haptics.tap()
                selectedTab = .visualize
            } label: {
                HStack(spacing: 7) {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .bold))
                    Text("Create First Project")
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
        .paintCard(padding: 26, radius: 24)
    }

    private func handleTap(_ item: ActivityItem) {
        switch item.kind {
        case .defect:
            if let scan = item.scan { path.append(scan) }
        case .vision:
            selectedTab = .visualize
        case .expert:
            selectedTab = .expert
        }
    }

    // MARK: Helpers

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 18, weight: .heavy))
            .foregroundStyle(Theme.ink)
    }

    private func requestQuote() {
        guard let url = URL(string: BusinessInfo.quoteMailto) else { return }
        UIApplication.shared.open(url)
    }
}

// MARK: - Project path model

struct PathStep: Identifiable {
    let id: Int
    let icon: String
    let title: String
    let subtitle: String
}

/// Horizontal dotted connector between project-path steps.
struct DottedLine: Shape {
    nonisolated func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.width, y: rect.midY))
        return path
    }
}

// MARK: - Activity model

struct ActivityItem: Identifiable {
    let id: String
    let title: String
    let date: Date
    let kind: ActivityKind
    let scan: PaintScan?
}

enum ActivityKind {
    case defect, vision, expert

    var icon: String {
        switch self {
        case .defect: "camera.viewfinder"
        case .vision: "wand.and.stars"
        case .expert: "bubble.left.and.text.bubble.right.fill"
        }
    }

    var label: String {
        switch self {
        case .defect: "Defect"
        case .vision: "Vision"
        case .expert: "Expert"
        }
    }

    var tint: Color {
        switch self {
        case .defect: Theme.brand
        case .vision: Theme.brandBright
        case .expert: Theme.lavenderAccent
        }
    }
}

struct ActivityRow: View {
    let item: ActivityItem

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: item.kind.icon)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(item.kind.tint)
                .frame(width: 44, height: 44)
                .background(item.kind.tint.opacity(0.12), in: .rect(cornerRadius: 14))
            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                Text(item.date, format: .dateTime.month().day().hour().minute())
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.inkSecondary)
            }
            Spacer(minLength: 8)
            Text(item.kind.label)
                .font(.system(size: 11, weight: .heavy))
                .foregroundStyle(item.kind.tint)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(item.kind.tint.opacity(0.12), in: .capsule)
        }
        .padding(10)
        .contentShape(.rect)
    }
}

// MARK: - Quick action tile

struct QuickActionTile: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            HStack(alignment: .top, spacing: 11) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.brand)
                    .frame(width: 40, height: 40)
                    .background(Theme.lavender, in: .rect(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Theme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text(subtitle)
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundStyle(Theme.inkSecondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, minHeight: 62, alignment: .topLeading)
            .padding(13)
            .background(Theme.surface, in: .rect(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Theme.hairline, lineWidth: 1))
            .shadow(color: .black.opacity(0.04), radius: 12, y: 6)
            .contentShape(.rect(cornerRadius: 20))
        }
        .buttonStyle(ScaleButtonStyle(scale: 0.96))
    }
}
