//
//  MoreView.swift
//  TaulbeePainting
//
//  The More tab: homeowner profile, a quote CTA, quick links into the app's
//  saved content, and ways to reach Taulbee Painting.
//

import SwiftUI

struct MoreView: View {
    @Binding var selectedTab: AppTab

    @State private var path = NavigationPath()
    @State private var showPrivacy = false
    @State private var showSettings = false
    @State private var showEstimate = false
    @AppStorage("appearanceMode") private var appearanceMode: AppearanceMode = .system

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(spacing: 18) {
                    profileCard
                    quoteCTA
                    hubGroup
                    projectsGroup
                    appearanceGroup
                    contactGroup
                    aboutGroup
                    disclaimer
                    Color.clear.frame(height: 8)
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)
            }
            .background(Theme.canvas.ignoresSafeArea())
            .navigationTitle("More")
            .navigationBarTitleDisplayMode(.large)
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
            .sheet(isPresented: $showEstimate) {
                RequestEstimateView()
            }
            .sheet(isPresented: $showPrivacy) {
                InfoSheet(
                    title: "Privacy & Data",
                    icon: "lock.shield.fill",
                    message: "Your scans, visualizations and vault records are stored privately on this device. Photos are only sent for analysis when you start a scan or visualization, and nothing is shared with Taulbee Painting until you choose to send it."
                )
            }
            .sheet(isPresented: $showSettings) {
                InfoSheet(
                    title: "App Settings",
                    icon: "gearshape.fill",
                    message: "Reminder notifications arrive on each reminder's due date. To adjust or silence them, open iOS Settings \u{2192} Notifications \u{2192} Taulbee Painting. Everything else stays local on your device."
                )
            }
        }
    }

    // MARK: Profile

    private var profileCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(Theme.brandGradient).frame(width: 60, height: 60)
                Text("H")
                    .font(.system(size: 26, weight: .heavy))
                    .foregroundStyle(.white)
            }
            .shadow(color: Theme.brand.opacity(0.3), radius: 8, y: 4)
            VStack(alignment: .leading, spacing: 3) {
                Text("Homeowner")
                    .font(.system(size: 19, weight: .heavy))
                    .foregroundStyle(Theme.ink)
                Text("Tap to set up your profile")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.inkSecondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Theme.inkSecondary.opacity(0.5))
        }
        .paintCard()
    }

    // MARK: Quote CTA

    private var quoteCTA: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Need help with a real project?")
                    .font(.system(size: 19, weight: .heavy))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Get a free estimate from the Taulbee Painting team.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Button {
                Haptics.tap()
                requestQuote()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "paintbrush.pointed.fill")
                        .font(.system(size: 16, weight: .bold))
                    Text("Request a Quote")
                        .font(.system(size: 16, weight: .bold))
                }
                .foregroundStyle(Theme.brand)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(.white, in: .rect(cornerRadius: 14))
                .shadow(color: .black.opacity(0.18), radius: 8, y: 4)
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background { HeroBackground() }
        .clipShape(.rect(cornerRadius: Theme.heroRadius))
        .shadow(color: Theme.brand.opacity(0.30), radius: 20, y: 12)
    }

    // MARK: Groups

    private var hubGroup: some View {
        MoreGroup(title: "Homeowner Hub") {
            MoreRow(icon: "calendar.badge.clock", tint: Theme.accent, title: "Maintenance Reminders") {
                path.append(HubRoute.maintenance)
            }
            MoreDivider()
            MoreRow(icon: "lock.shield.fill", tint: Theme.brand, title: "Paint Vault") {
                selectedTab = .vault
            }
            MoreDivider()
            MoreRow(icon: "paintpalette.fill", tint: Theme.lavenderAccent, title: "Saved Colors") {
                selectedTab = .vault
            }
            MoreDivider()
            MoreRow(icon: "photo.fill.on.rectangle.fill", tint: Color(hex: "3B82A0"), title: "Project Photos") {
                selectedTab = .vault
            }
            MoreDivider()
            MoreRow(icon: "clock.arrow.circlepath", tint: Color(hex: "2E9E6B"), title: "Activity Timeline") {
                path.append(HubRoute.timeline)
            }
        }
    }

    private var projectsGroup: some View {
        MoreGroup(title: "My Stuff") {
            MoreRow(icon: "camera.viewfinder", tint: Theme.brandBright, title: "Paint Defect Scanner") {
                path.append(ScanRoute.scanner)
            }
            MoreDivider()
            MoreRow(icon: "doc.text.fill", tint: Color(hex: "5B5BD6"), title: "Saved Documents") {
                selectedTab = .vault
            }
        }
    }

    private var appearanceGroup: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("APPEARANCE")
                .font(.system(size: 12, weight: .heavy))
                .tracking(0.8)
                .foregroundStyle(Theme.inkSecondary)
                .padding(.leading, 6)
            HStack(spacing: 8) {
                ForEach(AppearanceMode.allCases) { mode in
                    Button {
                        Haptics.tap()
                        withAnimation(.easeInOut(duration: 0.25)) { appearanceMode = mode }
                    } label: {
                        VStack(spacing: 7) {
                            Image(systemName: mode.systemImage)
                                .font(.system(size: 18, weight: .semibold))
                            Text(mode.label)
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundStyle(appearanceMode == mode ? .white : Theme.ink)
                        .frame(maxWidth: .infinity)
                        .frame(height: 64)
                        .background {
                            if appearanceMode == mode {
                                Theme.brandGradient
                            } else {
                                Theme.lavender
                            }
                        }
                        .clipShape(.rect(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(Theme.surface, in: .rect(cornerRadius: Theme.cardRadius))
            .overlay(RoundedRectangle(cornerRadius: Theme.cardRadius).stroke(Theme.hairline, lineWidth: 1))
            .shadow(color: .black.opacity(0.04), radius: 12, y: 6)
        }
    }

    private var contactGroup: some View {
        MoreGroup(title: "Taulbee Painting") {
            MoreRow(icon: "phone.fill", tint: Color(hex: "2E9E6B"), title: "Contact Taulbee Painting", detail: BusinessInfo.phone) {
                open("tel://\(BusinessInfo.phoneDialable)")
            }
            MoreDivider()
            MoreRow(icon: "envelope.fill", tint: Theme.brand, title: "Request an Estimate") {
                requestQuote()
            }
            MoreDivider()
            MoreRow(icon: "globe", tint: Color(hex: "3B82A0"), title: "Visit our Website", detail: BusinessInfo.website) {
                open(BusinessInfo.websiteURL)
            }
        }
    }

    private var aboutGroup: some View {
        MoreGroup(title: "App") {
            MoreRow(icon: "lock.shield.fill", tint: Theme.lavenderAccent, title: "Privacy & Data") {
                showPrivacy = true
            }
            MoreDivider()
            MoreRow(icon: "gearshape.fill", tint: Theme.inkSecondary, title: "App Settings") {
                showSettings = true
            }
        }
    }

    private var disclaimer: some View {
        Text("Diagnoses and color previews are AI-generated guidance and may not be perfect. For an accurate assessment, contact Taulbee Painting.")
            .font(.system(size: 12))
            .foregroundStyle(Theme.inkSecondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 12)
    }

    // MARK: Actions

    private func requestQuote() {
        showEstimate = true
    }

    private func open(_ string: String) {
        guard let url = URL(string: string) else { return }
        UIApplication.shared.open(url)
    }
}

// MARK: - Building blocks

struct MoreGroup<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.system(size: 12, weight: .heavy))
                .tracking(0.8)
                .foregroundStyle(Theme.inkSecondary)
                .padding(.leading, 6)
            VStack(spacing: 0) { content }
                .background(Theme.surface, in: .rect(cornerRadius: Theme.cardRadius))
                .overlay(RoundedRectangle(cornerRadius: Theme.cardRadius).stroke(Theme.hairline, lineWidth: 1))
                .shadow(color: .black.opacity(0.04), radius: 12, y: 6)
        }
    }
}

struct MoreRow: View {
    let icon: String
    let tint: Color
    let title: String
    var detail: String? = nil
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(tint, in: .rect(cornerRadius: 10))
                Text(title)
                    .font(.system(size: 15.5, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                Spacer(minLength: 8)
                if let detail {
                    Text(detail)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Theme.inkSecondary)
                        .lineLimit(1)
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Theme.inkSecondary.opacity(0.45))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}

struct MoreDivider: View {
    var body: some View {
        Divider().overlay(Theme.hairline).padding(.leading, 62)
    }
}

struct InfoSheet: View {
    let title: String
    let icon: String
    let message: String

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    Image(systemName: icon)
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 72, height: 72)
                        .background(Theme.brandGradient, in: .rect(cornerRadius: 20))
                        .shadow(color: Theme.brand.opacity(0.3), radius: 10, y: 6)
                    Text(title)
                        .font(.system(size: 22, weight: .heavy))
                        .foregroundStyle(Theme.ink)
                    Text(message)
                        .font(.system(size: 15))
                        .foregroundStyle(Theme.inkSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(24)
            }
            .background(Theme.canvas.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Theme.brand)
                }
            }
        }
    }
}
