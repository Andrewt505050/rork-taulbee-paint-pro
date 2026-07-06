//
//  HomeSheets.swift
//  TaulbeePainting
//
//  Lightweight sheets presented from the Home dashboard: the notifications
//  center and the "How it works" project-path explainer.
//

import SwiftUI

// MARK: - Notifications

struct NotificationsSheet: View {
    let onVisualize: () -> Void
    let onQuote: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 12) {
                    Image(systemName: "bell.badge")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(Theme.brand)
                        .frame(width: 66, height: 66)
                        .background(Theme.lavender, in: .circle)
                    VStack(spacing: 4) {
                        Text("You're all caught up")
                            .font(.system(size: 18, weight: .heavy))
                            .foregroundStyle(Theme.ink)
                        Text("Updates about your projects and Taulbee Painting will show up here.")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Theme.inkSecondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.top, 10)

                VStack(alignment: .leading, spacing: 10) {
                    Text("FOR YOU")
                        .font(.system(size: 11, weight: .heavy))
                        .tracking(0.8)
                        .foregroundStyle(Theme.inkSecondary)
                        .padding(.leading, 6)

                    suggestionRow(
                        icon: "wand.and.stars",
                        title: "Try the Color Visualizer",
                        text: "See your room in a new color before you commit.",
                        action: onVisualize
                    )
                    suggestionRow(
                        icon: "envelope.fill",
                        title: "Free project estimates",
                        text: "Send us your project — we'll take it from there.",
                        action: onQuote
                    )
                }
            }
            .padding(20)
        }
        .background(Theme.canvas)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    private func suggestionRow(icon: String, title: String, text: String, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            HStack(spacing: 13) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.brand)
                    .frame(width: 40, height: 40)
                    .background(Theme.lavender, in: .rect(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 14.5, weight: .bold))
                        .foregroundStyle(Theme.ink)
                    Text(text)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Theme.inkSecondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 6)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Theme.inkSecondary.opacity(0.5))
            }
            .padding(13)
            .background(Theme.surface, in: .rect(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Theme.hairline, lineWidth: 1))
            .contentShape(.rect(cornerRadius: 18))
        }
        .buttonStyle(ScaleButtonStyle(scale: 0.97))
    }
}

// MARK: - How it works

struct HowItWorksSheet: View {
    let onStart: () -> Void

    @Environment(\.dismiss) private var dismiss

    private let items: [(icon: String, title: String, text: String)] = [
        ("photo.badge.plus", "Upload Photo", "Snap or choose a photo of any room or exterior surface."),
        ("paintpalette.fill", "Preview Colors", "Apply real Sherwin-Williams, Benjamin Moore, and PPG colors instantly."),
        ("heart.fill", "Save Favorites", "Keep the looks you love safe in your Vault."),
        ("envelope.fill", "Request Estimate", "Send your project to Taulbee Painting for expert pricing.")
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("How it works")
                        .font(.system(size: 22, weight: .heavy))
                        .foregroundStyle(Theme.ink)
                    Text("From \u{201C}what if\u{201D} to a freshly painted space in four steps.")
                        .font(.system(size: 13.5, weight: .medium))
                        .foregroundStyle(Theme.inkSecondary)
                }
                .padding(.top, 14)

                VStack(alignment: .leading, spacing: 16) {
                    ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                        HStack(alignment: .top, spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(Theme.lavender)
                                    .frame(width: 44, height: 44)
                                Image(systemName: item.icon)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(Theme.brand)
                            }
                            .overlay(alignment: .topTrailing) {
                                Text("\(index + 1)")
                                    .font(.system(size: 10, weight: .heavy))
                                    .foregroundStyle(.white)
                                    .frame(width: 17, height: 17)
                                    .background(Theme.brand, in: .circle)
                                    .offset(x: 4, y: -3)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.title)
                                    .font(.system(size: 15.5, weight: .bold))
                                    .foregroundStyle(Theme.ink)
                                Text(item.text)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(Theme.inkSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }

                Button {
                    Haptics.tap()
                    onStart()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "wand.and.stars")
                            .font(.system(size: 15, weight: .bold))
                        Text("Start Visualizing")
                            .font(.system(size: 16, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Theme.brandGradient, in: .rect(cornerRadius: 15))
                    .shadow(color: Theme.brand.opacity(0.3), radius: 10, y: 5)
                }
                .buttonStyle(ScaleButtonStyle())
                .padding(.top, 4)
            }
            .padding(20)
        }
        .background(Theme.canvas)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}
