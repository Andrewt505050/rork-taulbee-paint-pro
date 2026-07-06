//
//  ScanFlowView.swift
//  TaulbeePainting
//
//  Orchestrates a single scan: analyzing → result, with retry handling.
//  Presented as a full-screen cover once an image is chosen.
//

import SwiftUI
import SwiftData

struct ScanFlowView: View {
    let image: UIImage
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = ScanViewModel()

    var body: some View {
        NavigationStack {
            content
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Done") { dismiss() }
                            .tint(Theme.brand)
                    }
                }
        }
        .task {
            if case .idle = viewModel.phase {
                await viewModel.start(with: image)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.phase {
        case .idle, .analyzing:
            AnalyzingView(image: image)
        case let .finished(analysis):
            ResultView(
                result: ScanResult(image: image, analysis: analysis),
                onSave: { viewModel.save(to: modelContext) },
                showSaveButton: true
            )
        case let .failed(message):
            ScanErrorView(message: message) {
                Task { await viewModel.retry() }
            } onCancel: {
                dismiss()
            }
        }
    }
}

struct ScanErrorView: View {
    let message: String
    let onRetry: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 22) {
            Spacer()
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 46, weight: .semibold))
                .foregroundStyle(Theme.accent)
                .frame(width: 96, height: 96)
                .background(Theme.accent.opacity(0.12), in: .circle)
            VStack(spacing: 8) {
                Text("Couldn't analyze that photo")
                    .font(.system(size: 20, weight: .heavy))
                    .foregroundStyle(Theme.ink)
                Text(message)
                    .font(.system(size: 15))
                    .foregroundStyle(Theme.inkSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)
            VStack(spacing: 12) {
                PrimaryButton(title: "Try Again", systemImage: "arrow.clockwise", action: onRetry)
                PrimaryButton(title: "Cancel", systemImage: "xmark", fill: false, action: onCancel)
            }
            .padding(.horizontal, 28)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(Theme.canvas.ignoresSafeArea())
    }
}
