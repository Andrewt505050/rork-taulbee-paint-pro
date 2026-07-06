//
//  ProductLibraryView.swift
//  TaulbeePainting
//
//  A browsable, searchable library of recommended paint products grouped by
//  use. Tapping a product opens its detail; an "Ask the Expert" callback lets
//  the user jump back to the chat with a tailored question.
//

import SwiftUI

/// Navigation routes within the Expert tab.
enum ExpertRoute: Hashable {
    case library
    case product(PaintProduct)
}

struct ProductLibraryView: View {
    let onAsk: (String) -> Void

    @State private var selectedCategory: ProductCategory?
    @State private var search: String = ""

    private var filtered: [PaintProduct] {
        var items = ProductCatalog.all
        if let selectedCategory {
            items = items.filter { $0.category == selectedCategory }
        }
        let query = search.trimmingCharacters(in: .whitespacesAndNewlines)
        if !query.isEmpty {
            items = items.filter {
                $0.name.localizedStandardContains(query)
                || $0.brand.localizedStandardContains(query)
                || $0.bestFor.localizedStandardContains(query)
            }
        }
        return items
    }

    /// Categories present in the filtered list, in canonical order.
    private var sections: [ProductCategory] {
        ProductCategory.allCases.filter { category in
            filtered.contains { $0.category == category }
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                categoryFilter
                if filtered.isEmpty {
                    emptyState
                } else {
                    ForEach(sections) { category in
                        section(category)
                    }
                }
                Color.clear.frame(height: 12)
            }
            .padding(.top, 8)
        }
        .background(Theme.canvas.ignoresSafeArea())
        .navigationTitle("Product Library")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $search, prompt: "Search products")
    }

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                CategoryChip(title: "All", systemImage: "square.grid.2x2.fill", tint: Theme.brand, isOn: selectedCategory == nil) {
                    Haptics.tap()
                    selectedCategory = nil
                }
                ForEach(ProductCategory.allCases) { category in
                    CategoryChip(title: category.label, systemImage: category.systemImage, tint: category.tint, isOn: selectedCategory == category) {
                        Haptics.tap()
                        selectedCategory = selectedCategory == category ? nil : category
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private func section(_ category: ProductCategory) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: category.systemImage)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(category.tint)
                Text(category.label)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Theme.ink)
            }
            VStack(spacing: 10) {
                ForEach(filtered.filter { $0.category == category }) { product in
                    NavigationLink(value: ExpertRoute.product(product)) {
                        ProductRow(product: product)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 16)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 30))
                .foregroundStyle(Theme.brand.opacity(0.6))
            Text("No products found")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Theme.ink)
            Text("Try a different search or category.")
                .font(.system(size: 14))
                .foregroundStyle(Theme.inkSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .padding(.horizontal, 16)
    }
}

// MARK: - Category chip

struct CategoryChip: View {
    let title: String
    let systemImage: String
    let tint: Color
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.system(size: 12, weight: .bold))
                Text(title)
                    .font(.system(size: 13.5, weight: .semibold))
            }
            .foregroundStyle(isOn ? .white : Theme.ink)
            .padding(.horizontal, 13)
            .padding(.vertical, 9)
            .background {
                if isOn {
                    tint
                } else {
                    Theme.surface
                }
            }
            .clipShape(.rect(cornerRadius: Theme.chipRadius))
            .overlay(RoundedRectangle(cornerRadius: Theme.chipRadius).stroke(isOn ? .clear : Theme.hairline, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Product row

struct ProductRow: View {
    let product: PaintProduct

    var body: some View {
        HStack(spacing: 13) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(product.category.tint.opacity(0.14))
                Image(systemName: product.category.systemImage)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(product.category.tint)
            }
            .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 3) {
                Text(product.name)
                    .font(.system(size: 15.5, weight: .bold))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                Text("\(product.brand) · \(product.finish)")
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(Theme.inkSecondary)
                Text(product.bestFor)
                    .font(.system(size: 12.5))
                    .foregroundStyle(Theme.inkSecondary)
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Theme.inkSecondary.opacity(0.5))
        }
        .padding(14)
        .background(Theme.surface, in: .rect(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Theme.hairline, lineWidth: 1))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 4)
    }
}
