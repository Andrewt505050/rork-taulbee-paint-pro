//
//  HeroSlideCard.swift
//  TaulbeePainting
//
//  A premium hero slide for the Home carousel: editorial serif headline and
//  CTAs on the left, a full-height photo on the right. Falls back to a brand
//  gradient with an icon if the photo asset is unavailable.
//

import SwiftUI

struct HeroSlideCard: View {
    let eyebrow: String
    let headline: String
    let subtext: String
    let imageName: String
    let fallbackIcon: String
    let primaryTitle: String
    let primaryIcon: String
    let primaryAction: () -> Void
    var secondaryTitle: String? = nil
    var secondaryIcon: String? = nil
    var secondaryAction: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 0) {
            content
            photo
        }
        .frame(maxWidth: .infinity)
        .frame(height: 324)
        .background(Theme.surface)
        .clipShape(.rect(cornerRadius: Theme.heroRadius))
        .overlay(RoundedRectangle(cornerRadius: Theme.heroRadius).stroke(Theme.hairline, lineWidth: 1))
        .shadow(color: Theme.brand.opacity(0.10), radius: 14, y: 8)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(eyebrow)
                .font(.system(size: 10.5, weight: .heavy))
                .tracking(1.2)
                .foregroundStyle(Theme.brand)

            Text(headline)
                .font(.system(size: 23, weight: .bold, design: .serif))
                .foregroundStyle(Theme.ink)
                .lineSpacing(1)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 9)

            Text(subtext)
                .font(.system(size: 12.5, weight: .medium))
                .foregroundStyle(Theme.inkSecondary)
                .lineSpacing(1)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 7)

            Spacer(minLength: 12)

            Button {
                Haptics.tap()
                primaryAction()
            } label: {
                HStack(spacing: 7) {
                    Image(systemName: primaryIcon)
                        .font(.system(size: 13, weight: .bold))
                    Text(primaryTitle)
                        .font(.system(size: 14, weight: .bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background(Theme.brandGradient, in: .rect(cornerRadius: 14))
                .shadow(color: Theme.brand.opacity(0.30), radius: 8, y: 4)
            }
            .buttonStyle(ScaleButtonStyle())

            if let secondaryTitle, let secondaryAction {
                Button {
                    Haptics.tap()
                    secondaryAction()
                } label: {
                    HStack(spacing: 7) {
                        if let secondaryIcon {
                            Image(systemName: secondaryIcon)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Theme.brand)
                        }
                        Text(secondaryTitle)
                            .font(.system(size: 13, weight: .bold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .foregroundStyle(Theme.ink)
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
                    .background(Theme.canvas, in: .rect(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.hairline, lineWidth: 1))
                }
                .buttonStyle(ScaleButtonStyle())
                .padding(.top, 8)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    /// Size-anchored photo column: the Color drives layout, the image overlays
    /// and is visually clipped so `.fill` overflow can never cover the text.
    private var photo: some View {
        Theme.lavender
            .frame(width: 148)
            .frame(maxHeight: .infinity)
            .overlay {
                if let uiImage = UIImage(named: imageName) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .allowsHitTesting(false)
                } else {
                    ZStack {
                        Theme.heroGradient
                        Image(systemName: fallbackIcon)
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.92))
                    }
                    .allowsHitTesting(false)
                }
            }
            .clipped()
    }
}
