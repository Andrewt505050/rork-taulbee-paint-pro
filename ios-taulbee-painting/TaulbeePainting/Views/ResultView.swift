//
//  ResultView.swift
//  TaulbeePainting
//

import SwiftUI

struct ResultView: View {
    let result: ScanResult
    /// Shown for fresh scans so the user can persist the result.
    var onSave: (() -> Void)? = nil
    var showSaveButton: Bool = false

    @State private var showShare = false
    @State private var didSave = false
    @State private var appeared = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                heroImage
                diagnosisCard
                if !result.causes.isEmpty { causesCard }
                if !result.solutions.isEmpty { solutionsCard }
                if !result.whenToCallPro.isEmpty { proCard }
                actions
                Color.clear.frame(height: 8)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .background(Theme.canvas.ignoresSafeArea())
        .navigationTitle("Diagnosis")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showShare) {
            ShareSheet(items: shareItems)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.45)) { appeared = true }
        }
    }

    private var shareItems: [Any] {
        var items: [Any] = [result.shareText]
        if let image = result.image { items.append(image) }
        return items
    }

    // MARK: Sections

    private var heroImage: some View {
        Group {
            if let image = result.image {
                Color(.secondarySystemBackground)
                    .frame(height: 240)
                    .overlay {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .allowsHitTesting(false)
                    }
                    .clipShape(.rect(cornerRadius: Theme.cardRadius))
                    .overlay(alignment: .topLeading) {
                        SeverityBadge(severity: result.severity)
                            .padding(12)
                    }
            }
        }
        .shadow(color: .black.opacity(0.08), radius: 14, y: 8)
    }

    private var diagnosisCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(result.defectName)
                        .font(.system(size: 24, weight: .heavy))
                        .foregroundStyle(Theme.ink)
                    Label(result.surface, systemImage: "square.dashed")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Theme.inkSecondary)
                }
                Spacer()
                SeverityGauge(severity: result.severity)
            }
            Text(result.summary)
                .font(.system(size: 15.5, weight: .regular))
                .foregroundStyle(Theme.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(3)
            ConfidenceBar(value: result.confidence)
        }
        .paintCard()
    }

    private var causesCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionLabel(icon: "magnifyingglass", title: "Likely causes", tint: Theme.accent)
            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(result.causes.enumerated()), id: \.offset) { _, cause in
                    HStack(alignment: .top, spacing: 10) {
                        Circle()
                            .fill(Theme.accent)
                            .frame(width: 7, height: 7)
                            .padding(.top, 7)
                        Text(cause)
                            .font(.system(size: 15))
                            .foregroundStyle(Theme.ink)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .paintCard()
    }

    private var solutionsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionLabel(icon: "checklist", title: "Recommended solutions")
            VStack(alignment: .leading, spacing: 14) {
                ForEach(Array(result.solutions.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(index + 1)")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 24, height: 24)
                            .background(Theme.brandGradient, in: .circle)
                        Text(step)
                            .font(.system(size: 15))
                            .foregroundStyle(Theme.ink)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .paintCard()
    }

    private var proCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "phone.badge.checkmark")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Theme.brand)
                .frame(width: 38, height: 38)
                .background(Theme.brand.opacity(0.12), in: .circle)
            VStack(alignment: .leading, spacing: 4) {
                Text("When to call a pro")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Theme.ink)
                Text(result.whenToCallPro)
                    .font(.system(size: 14.5))
                    .foregroundStyle(Theme.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
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

    private var actions: some View {
        VStack(spacing: 12) {
            PrimaryButton(title: "Send to Taulbee", systemImage: "paperplane.fill") {
                showShare = true
            }
            if showSaveButton {
                PrimaryButton(
                    title: didSave ? "Saved to History" : "Save to History",
                    systemImage: didSave ? "checkmark.circle.fill" : "tray.and.arrow.down.fill",
                    fill: false
                ) {
                    guard !didSave else { return }
                    onSave?()
                    withAnimation { didSave = true }
                }
                .disabled(didSave)
            }
        }
        .padding(.top, 4)
    }
}

struct SeverityBadge: View {
    let severity: Severity
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: severity.systemImage)
                .font(.system(size: 12, weight: .bold))
            Text(severity.label)
                .font(.system(size: 13, weight: .bold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(severity.color, in: .capsule)
        .shadow(color: .black.opacity(0.2), radius: 6, y: 3)
    }
}
