//
//  ColorLibraryView.swift
//  TaulbeePainting
//
//  Searchable, filterable grid of real paint colors across the three brands.
//

import SwiftUI

struct ColorLibraryView: View {
    /// Called when the user taps a color to select it.
    let onSelect: (PaintColor) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var brand: PaintBrand?
    @State private var family: ColorFamily?

    private let columns = [GridItem(.adaptive(minimum: 104), spacing: 12)]

    private var results: [PaintColor] {
        PaintColorLibrary.colors(brand: brand, family: family, query: query)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                filters
                if results.isEmpty {
                    emptyState
                } else {
                    grid
                }
            }
            .background(Theme.canvas.ignoresSafeArea())
            .navigationTitle("Color Library")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(Theme.brand)
                }
            }
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search name or code")
        }
        .tint(Theme.brand)
    }

    // MARK: Filters

    private var filters: some View {
        VStack(spacing: 10) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(title: "All brands", isOn: brand == nil) { brand = nil }
                    ForEach(PaintBrand.allCases) { b in
                        FilterChip(title: b.displayName, isOn: brand == b) {
                            brand = (brand == b) ? nil : b
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(title: "All colors", isOn: family == nil) { family = nil }
                    ForEach(ColorFamily.allCases) { f in
                        FilterChip(title: f.rawValue, isOn: family == f) {
                            family = (family == f) ? nil : f
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .padding(.vertical, 12)
        .background(Theme.surface)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Theme.hairline).frame(height: 1)
        }
    }

    private var grid: some View {
        ScrollView {
            Text("\(results.count) colors")
                .font(.system(size: 12.5, weight: .semibold))
                .foregroundStyle(Theme.inkSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.top, 14)
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(results) { color in
                    Button {
                        Haptics.tap()
                        onSelect(color)
                        dismiss()
                    } label: {
                        SwatchCard(color: color)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 24)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "paintpalette")
                .font(.system(size: 36))
                .foregroundStyle(Theme.brand.opacity(0.5))
            Text("No colors match your search")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.ink)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Swatch

struct SwatchCard: View {
    let color: PaintColor

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            color.color
                .frame(height: 84)
                .overlay(alignment: .topTrailing) {
                    Text(color.brand.short)
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundStyle(color.prefersDarkText ? .black.opacity(0.55) : .white.opacity(0.85))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background((color.prefersDarkText ? Color.black : Color.white).opacity(0.16), in: .capsule)
                        .padding(8)
                }
            VStack(alignment: .leading, spacing: 2) {
                Text(color.name)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                Text(color.code)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Theme.inkSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
            .background(Theme.surface)
        }
        .clipShape(.rect(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.hairline, lineWidth: 1))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
}

// MARK: - Filter chip

struct FilterChip: View {
    let title: String
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13.5, weight: .semibold))
                .foregroundStyle(isOn ? .white : Theme.ink)
                .padding(.horizontal, 14)
                .frame(height: 34)
                .background {
                    if isOn { Theme.brand } else { Theme.canvasDeep }
                }
                .clipShape(.capsule)
        }
        .buttonStyle(.plain)
    }
}
