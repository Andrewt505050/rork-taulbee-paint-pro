//
//  ScanViewModel.swift
//  TaulbeePainting
//

import SwiftUI
import SwiftData

/// Drives a single scan: holds the chosen image, runs analysis, exposes state.
@MainActor
@Observable
final class ScanViewModel {
    enum Phase: Equatable {
        case idle
        case analyzing
        case finished(DefectAnalysis)
        case failed(String)
    }

    private(set) var phase: Phase = .idle
    var image: UIImage?

    private let service = DefectScannerService()

    var isAnalyzing: Bool {
        if case .analyzing = phase { return true }
        return false
    }

    func start(with image: UIImage) async {
        self.image = image
        phase = .analyzing
        Haptics.soft()
        do {
            let analysis = try await service.analyze(image: image)
            phase = .finished(analysis)
            Haptics.success()
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? "Something went wrong. Please try again."
            phase = .failed(message)
            Haptics.warning()
        }
    }

    func retry() async {
        guard let image else { return }
        await start(with: image)
    }

    func reset() {
        phase = .idle
        image = nil
    }

    /// Persists a finished result to history.
    func save(to context: ModelContext) {
        guard case let .finished(analysis) = phase, let image else { return }
        let data = ImageResizer.storageJPEG(image)
        let scan = PaintScan(imageData: data, analysis: analysis)
        context.insert(scan)
        try? context.save()
    }
}
