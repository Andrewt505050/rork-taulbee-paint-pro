//
//  BeforeAfterSlider.swift
//  TaulbeePainting
//
//  Draggable reveal slider comparing the original photo (before) with the
//  AI-repainted result (after).
//

import SwiftUI

struct BeforeAfterSlider: View {
    let before: UIImage
    let after: UIImage

    @State private var fraction: CGFloat = 0.5

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let handleX = max(0, min(width, width * fraction))

            ZStack(alignment: .leading) {
                // After (result) fills the background.
                Image(uiImage: after)
                    .resizable()
                    .scaledToFill()
                    .frame(width: width, height: geo.size.height)
                    .clipped()
                    .overlay(alignment: .topTrailing) { tag("After", tint: Theme.brand) }

                // Before (original) clipped to the slider fraction.
                Image(uiImage: before)
                    .resizable()
                    .scaledToFill()
                    .frame(width: width, height: geo.size.height)
                    .clipped()
                    .overlay(alignment: .topLeading) { tag("Before", tint: .black.opacity(0.55)) }
                    .mask(alignment: .leading) {
                        Rectangle().frame(width: handleX)
                    }

                // Divider + handle
                handle
                    .position(x: handleX, y: geo.size.height / 2)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        fraction = max(0, min(1, value.location.x / width))
                    }
            )
        }
    }

    private var handle: some View {
        ZStack {
            Rectangle()
                .fill(.white)
                .frame(width: 3)
                .shadow(color: .black.opacity(0.3), radius: 4)
            Circle()
                .fill(.white)
                .frame(width: 38, height: 38)
                .shadow(color: .black.opacity(0.25), radius: 6, y: 2)
                .overlay {
                    Image(systemName: "arrow.left.and.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Theme.brand)
                }
        }
    }

    private func tag(_ text: String, tint: Color) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .heavy))
            .foregroundStyle(.white)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(tint, in: .capsule)
            .padding(10)
    }
}
