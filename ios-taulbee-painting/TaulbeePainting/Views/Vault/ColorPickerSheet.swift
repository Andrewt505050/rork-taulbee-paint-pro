//
//  ColorPickerSheet.swift
//  TaulbeePainting
//
//  Pick a paint color from the built-in Sherwin-Williams / Benjamin Moore /
//  PPG library, or enter one manually with a custom swatch.
//

import SwiftUI

/// A chosen color returned to the caller.
struct ColorSelection {
    let name: String
    let brand: String
    let code: String
    /// Six-digit hex without '#'.
    let hex: String
}

struct ColorPickerSheet: View {
    var title: String = "Choose a Color"
    let onPick: (ColorSelection) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var mode: PickerMode = .library
    @State private var query = ""
    @State private var brand: PaintBrand?

    @State private var customName = ""
    @State private var customBrand = ""
    @State private var customCode = ""
    @State private var customColor: Color = Color(hex: "B7A7D6")

    private enum PickerMode { case library, custom }

    private var results: [PaintColor] {
        PaintColorLibrary.colors(brand: brand, family: nil, query: query)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                modePicker
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .padding(.bottom, 12)
                if mode == .library {
                    libraryContent
                } else {
                    customContent
                }
            }
            .background(Theme.canvas.ignoresSafeArea())
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    // MARK: Mode picker

    private var modePicker: some View {
        HStack(spacing: 6) {
            modeButton("Color Library", .library)
            modeButton("Enter Manually", .custom)
        }
        .padding(5)
        .background(Theme.canvasDeep, in: .capsule)
    }

    private func modeButton(_ label: String, _ value: PickerMode) -> some View {
        Button {
            Haptics.tap()
            withAnimation(.snappy(duration: 0.2)) { mode = value }
        } label: {
            Text(label)
                .font(.system(size: 13.5, weight: .bold))
                .foregroundStyle(mode == value ? .white : Theme.inkSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background {
                    if mode == value {
                        Capsule().fill(Theme.brandGradient)
                    }
                }
        }
        .buttonStyle(.plain)
    }

    // MARK: Library

    private var libraryContent: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.inkSecondary)
                TextField("Search by name or code", text: $query)
                    .font(.system(size: 15))
                    .autocorrectionDisabled()
            }
            .padding(.horizontal, 14)
            .frame(height: 44)
            .background(Theme.surface, in: .rect(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.hairline, lineWidth: 1))
            .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    brandPill(nil, label: "All Brands")
                    ForEach(PaintBrand.allCases) { item in
                        brandPill(item, label: item.displayName)
                    }
                }
                .padding(.horizontal, 16)
            }

            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 104), spacing: 10)], spacing: 10) {
                    ForEach(results) { color in
                        swatchCard(color)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
    }

    private func brandPill(_ value: PaintBrand?, label: String) -> some View {
        Button {
            Haptics.tap()
            withAnimation(.snappy(duration: 0.2)) { brand = value }
        } label: {
            Text(label)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(brand == value ? .white : Theme.brand)
                .padding(.horizontal, 14)
                .frame(height: 34)
                .background(
                    brand == value ? AnyShapeStyle(Theme.brandGradient) : AnyShapeStyle(Theme.lavender),
                    in: .capsule
                )
        }
        .buttonStyle(.plain)
    }

    private func swatchCard(_ color: PaintColor) -> some View {
        Button {
            Haptics.success()
            onPick(ColorSelection(name: color.name, brand: color.brand.short, code: color.code, hex: color.hex))
            dismiss()
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                RoundedRectangle(cornerRadius: 0)
                    .fill(color.color)
                    .frame(height: 64)
                VStack(alignment: .leading, spacing: 2) {
                    Text(color.name)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Theme.ink)
                        .lineLimit(1)
                    Text("\(color.brand.short) \(color.code)")
                        .font(.system(size: 10.5, weight: .medium))
                        .foregroundStyle(Theme.inkSecondary)
                        .lineLimit(1)
                }
                .padding(.horizontal, 9)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.surface)
            }
            .clipShape(.rect(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.hairline, lineWidth: 1))
        }
        .buttonStyle(ScaleButtonStyle(scale: 0.95))
    }

    // MARK: Custom entry

    private var customContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    fieldLabel("Color name")
                    TextField("e.g. Agreeable Gray", text: $customName)
                        .font(.system(size: 16))
                        .padding(14)
                        .background(Theme.surface, in: .rect(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.hairline, lineWidth: 1))
                }
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 8) {
                        fieldLabel("Brand (optional)")
                        TextField("e.g. SW", text: $customBrand)
                            .font(.system(size: 16))
                            .padding(14)
                            .background(Theme.surface, in: .rect(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.hairline, lineWidth: 1))
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        fieldLabel("Code (optional)")
                        TextField("e.g. 7029", text: $customCode)
                            .font(.system(size: 16))
                            .padding(14)
                            .background(Theme.surface, in: .rect(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.hairline, lineWidth: 1))
                    }
                }
                VStack(alignment: .leading, spacing: 8) {
                    fieldLabel("Swatch")
                    HStack(spacing: 14) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(customColor)
                            .frame(width: 52, height: 52)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.hairline, lineWidth: 1))
                        ColorPicker("Pick the closest match", selection: $customColor, supportsOpacity: false)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Theme.ink)
                    }
                    .padding(14)
                    .background(Theme.surface, in: .rect(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.hairline, lineWidth: 1))
                }

                PrimaryButton(title: "Add Color", systemImage: "checkmark") {
                    let trimmed = customName.trimmingCharacters(in: .whitespaces)
                    guard !trimmed.isEmpty else { return }
                    Haptics.success()
                    onPick(ColorSelection(
                        name: trimmed,
                        brand: customBrand.trimmingCharacters(in: .whitespaces),
                        code: customCode.trimmingCharacters(in: .whitespaces),
                        hex: hexString(from: customColor)
                    ))
                    dismiss()
                }
                .opacity(customName.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)
                .disabled(customName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(16)
        }
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 12, weight: .heavy))
            .tracking(1)
            .foregroundStyle(Theme.inkSecondary)
    }

    private func hexString(from color: Color) -> String {
        let ui = UIColor(color)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        ui.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return String(
            format: "%02X%02X%02X",
            Int(round(red * 255)),
            Int(round(green * 255)),
            Int(round(blue * 255))
        )
    }
}
