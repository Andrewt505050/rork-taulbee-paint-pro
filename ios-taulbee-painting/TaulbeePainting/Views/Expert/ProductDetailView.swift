//
//  ProductDetailView.swift
//  TaulbeePainting
//
//  Full detail for a recommended product, with an "Ask the Expert about this"
//  shortcut that returns to the chat with a tailored question.
//

import SwiftUI

struct ProductDetailView: View {
    let product: PaintProduct
    let onAsk: (String) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                bestForCard
                featuresCard
                askButton
                Color.clear.frame(height: 12)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .background(Theme.canvas.ignoresSafeArea())
        .navigationTitle(product.brand)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: product.category.systemImage)
                    .font(.system(size: 13, weight: .bold))
                Text(product.category.label.uppercased())
                    .font(.system(size: 12, weight: .heavy))
                    .tracking(1.2)
            }
            .foregroundStyle(.white.opacity(0.9))

            Text(product.name)
                .font(.system(size: 26, weight: .heavy))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                Label(product.brand, systemImage: "tag.fill")
                Text("·")
                Label(product.finish, systemImage: "paintbrush.fill")
            }
            .font(.system(size: 13.5, weight: .semibold))
            .foregroundStyle(.white.opacity(0.9))
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            ZStack {
                LinearGradient(colors: [product.category.tint, product.category.tint.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
                ColorDots()
            }
        }
        .clipShape(.rect(cornerRadius: 26))
        .shadow(color: product.category.tint.opacity(0.28), radius: 18, y: 10)
        .padding(.top, 8)
    }

    private var bestForCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionLabel(icon: "star.fill", title: "Best for", tint: product.category.tint)
            Text(product.bestFor)
                .font(.system(size: 15.5))
                .foregroundStyle(Theme.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .paintCard()
    }

    private var featuresCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel(icon: "checkmark.seal.fill", title: "Key features", tint: product.category.tint)
            VStack(alignment: .leading, spacing: 10) {
                ForEach(product.features, id: \.self) { feature in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(product.category.tint)
                        Text(feature)
                            .font(.system(size: 14.5))
                            .foregroundStyle(Theme.ink)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
        .paintCard()
    }

    private var askButton: some View {
        PrimaryButton(title: "Ask the Expert about this", systemImage: "paintbrush.pointed.fill") {
            onAsk("Tell me more about \(product.brand) \(product.name) — is it a good choice for my project, and how should I apply it?")
        }
        .padding(.top, 2)
    }
}
