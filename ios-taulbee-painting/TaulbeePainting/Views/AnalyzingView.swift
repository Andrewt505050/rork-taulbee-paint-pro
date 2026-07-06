//
//  AnalyzingView.swift
//  TaulbeePainting
//
//  Engaging progress state shown while the AI analyzes the photo.
//

import SwiftUI
import Combine

struct AnalyzingView: View {
    let image: UIImage

    @State private var scan: CGFloat = -1
    @State private var pulse = false
    @State private var stepIndex = 0

    private let steps = [
        "Examining the surface…",
        "Detecting defect patterns…",
        "Identifying likely causes…",
        "Preparing recommendations…"
    ]

    private let timer = Timer.publish(every: 1.6, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            ZStack {
                Color(.secondarySystemBackground)
                    .frame(width: 260, height: 260)
                    .overlay {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .allowsHitTesting(false)
                    }
                    .clipShape(.rect(cornerRadius: 28))
                    .overlay {
                        // Scanning sweep line
                        GeometryReader { geo in
                            LinearGradient(
                                colors: [.clear, Theme.brand.opacity(0.55), .clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(height: 70)
                            .offset(y: scan * (geo.size.height + 70) / 2)
                        }
                        .clipShape(.rect(cornerRadius: 28))
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 28)
                            .stroke(Theme.brand.opacity(0.5), lineWidth: 2)
                    )
                    .shadow(color: Theme.brand.opacity(0.25), radius: 24, y: 12)

                RoundedRectangle(cornerRadius: 28)
                    .stroke(Theme.brand.opacity(pulse ? 0 : 0.4), lineWidth: 2)
                    .frame(width: 260, height: 260)
                    .scaleEffect(pulse ? 1.12 : 1)
                    .opacity(pulse ? 0 : 1)
            }

            VStack(spacing: 8) {
                Text("Analyzing your photo")
                    .font(.system(size: 21, weight: .heavy))
                    .foregroundStyle(Theme.ink)
                Text(steps[stepIndex])
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Theme.inkSecondary)
                    .id(stepIndex)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
            .animation(.easeInOut, value: stepIndex)

            PaintChips()
                .opacity(0.9)

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(Theme.canvas.ignoresSafeArea())
        .onAppear {
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                scan = 1
            }
            withAnimation(.easeOut(duration: 1.8).repeatForever(autoreverses: false)) {
                pulse = true
            }
        }
        .onReceive(timer) { _ in
            withAnimation { stepIndex = (stepIndex + 1) % steps.count }
        }
    }
}
