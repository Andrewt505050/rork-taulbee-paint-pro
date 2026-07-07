//
//  RootView.swift
//  TaulbeePainting
//
//  Keep-alive tab host with a custom premium bottom bar. Every tab stays
//  alive (navigation and scroll state survive switching) and the active tab
//  is wrapped in a sliding lavender pill.
//

import SwiftUI

/// Top-level tabs. `home` hosts the Dashboard hub; the Defect Scanner is
/// pushed from Home (and reachable from More).
enum AppTab: String, CaseIterable, Identifiable, Hashable {
    case home, visualize, vault, expert, more

    var id: String { rawValue }

    var label: String {
        switch self {
        case .home: return "Home"
        case .visualize: return "Visualize"
        case .vault: return "Vault"
        case .expert: return "Expert"
        case .more: return "More"
        }
    }

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .visualize: return "wand.and.stars"
        case .vault: return "lock.shield.fill"
        case .expert: return "bubble.left.and.text.bubble.right.fill"
        case .more: return "ellipsis"
        }
    }
}

struct RootView: View {
    @State private var router = AppRouter()
    @AppStorage("appearanceMode") private var appearanceMode: AppearanceMode = .system

    var body: some View {
        @Bindable var router = router
        // The tab bar sits BELOW the content in a VStack (not as a safe-area
        // inset) so scroll content can never end up hidden behind it —
        // additional bottom safe area doesn't reliably propagate into
        // NavigationStacks on device, which left bottom buttons covered.
        VStack(spacing: 0) {
            ZStack {
                pane(.home) { HomeTab(selectedTab: $router.selectedTab) }
                pane(.visualize) { VisionHomeView() }
                pane(.vault) { VaultHomeView() }
                pane(.expert) { ExpertChatView() }
                pane(.more) { MoreView(selectedTab: $router.selectedTab) }
            }
            .animation(.easeInOut(duration: 0.16), value: router.selectedTab)

            TaulbeeTabBar(selected: $router.selectedTab)
        }
        .tint(Theme.brand)
        .preferredColorScheme(appearanceMode.colorScheme)
        .environment(router)
        .task { await PaintColorCatalog.shared.loadIfNeeded() }
    }

    /// Keeps every tab mounted so navigation & scroll state survive switching;
    /// only the selected pane is visible and interactive.
    @ViewBuilder
    private func pane<Content: View>(_ tab: AppTab, @ViewBuilder content: () -> Content) -> some View {
        content()
            .opacity(router.selectedTab == tab ? 1 : 0)
            .allowsHitTesting(router.selectedTab == tab)
            .accessibilityHidden(router.selectedTab != tab)
    }
}

/// Home tab: the Dashboard at the root, with the dedicated scanner pushed on top.
struct HomeTab: View {
    @Binding var selectedTab: AppTab
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            DashboardView(selectedTab: $selectedTab, path: $path)
                .navigationDestination(for: ScanRoute.self) { route in
                    switch route {
                    case .scanner:
                        ScannerHomeView()
                    }
                }
                .navigationDestination(for: PaintScan.self) { scan in
                    ResultView(result: ScanResult(scan: scan))
                }
                .navigationDestination(for: HubRoute.self) { route in
                    switch route {
                    case .maintenance:
                        MaintenanceView()
                    case .timeline:
                        ActivityTimelineView()
                    }
                }
                .navigationDestination(for: PaintReminder.self) { reminder in
                    ReminderDetailView(reminder: reminder)
                }
        }
    }
}

enum ScanRoute: Hashable {
    case scanner
}

// MARK: - Custom tab bar

/// Premium bottom bar: evenly spaced items with a sliding lavender pill that
/// wraps the active tab's icon and label. Slides away while the keyboard is
/// visible so input bars sit directly above the keyboard.
struct TaulbeeTabBar: View {
    @Binding var selected: AppTab

    @Namespace private var pillNamespace
    @State private var keyboardVisible = false

    var body: some View {
        Group {
            if keyboardVisible {
                Color.clear.frame(height: 0)
            } else {
                bar
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            withAnimation(.easeOut(duration: 0.22)) { keyboardVisible = true }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            withAnimation(.easeOut(duration: 0.22)) { keyboardVisible = false }
        }
    }

    private var bar: some View {
        HStack(spacing: 4) {
            ForEach(AppTab.allCases) { tab in
                item(for: tab)
            }
        }
        .padding(.horizontal, 10)
        .padding(.top, 9)
        .padding(.bottom, 7)
        .frame(maxWidth: .infinity)
        .background {
            Rectangle()
                .fill(Theme.surface)
                .overlay(alignment: .top) {
                    Rectangle().fill(Theme.hairline).frame(height: 0.8)
                }
                .shadow(color: .black.opacity(0.06), radius: 14, y: -4)
                .ignoresSafeArea(edges: .bottom)
        }
    }

    private func item(for tab: AppTab) -> some View {
        let isActive = selected == tab
        return Button {
            guard selected != tab else { return }
            Haptics.tap()
            withAnimation(.spring(response: 0.34, dampingFraction: 0.78)) {
                selected = tab
            }
        } label: {
            VStack(spacing: 3) {
                Image(systemName: tab.icon)
                    .font(.system(size: 17, weight: .semibold))
                Text(tab.label)
                    .font(.system(size: 10, weight: isActive ? .bold : .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .foregroundStyle(isActive ? Theme.brand : Theme.inkSecondary)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background {
                if isActive {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Theme.lavender)
                        .matchedGeometryEffect(id: "activePill", in: pillNamespace)
                        .padding(.horizontal, 2)
                }
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.label)
        .accessibilityAddTraits(isActive ? [.isSelected] : [])
    }
}
