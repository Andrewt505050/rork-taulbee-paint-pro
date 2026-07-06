//
//  ImageResizer.swift
//  TaulbeePainting
//
//  Re-encodes images against a byte budget so they fit the AI gateway
//  request-body limit before being sent for analysis.
//

import UIKit

nonisolated enum ImageResizer {
    /// Steps of (maxLongEdge, jpegQuality) tried in order.
    private static let ladder: [(maxEdge: CGFloat, quality: CGFloat)] = [
        (1280, 0.82),
        (1024, 0.78),
        (832, 0.74),
        (640, 0.70),
        (512, 0.65)
    ]

    /// Returns raw JPEG data under `maxBytes`, or nil if it cannot fit.
    static func jpegUnderBudget(_ image: UIImage, maxBytes: Int = 3_000_000) -> Data? {
        for step in ladder {
            guard let resized = resize(image, maxEdge: step.maxEdge),
                  let data = resized.jpegData(compressionQuality: step.quality) else { continue }
            if data.count <= maxBytes {
                return data
            }
        }
        // Last-ditch: most aggressive step regardless of budget check failures.
        if let resized = resize(image, maxEdge: 512) {
            return resized.jpegData(compressionQuality: 0.6)
        }
        return nil
    }

    /// A small JPEG suitable for persisting as a thumbnail/full record.
    static func storageJPEG(_ image: UIImage) -> Data {
        let resized = resize(image, maxEdge: 1400) ?? image
        return resized.jpegData(compressionQuality: 0.8) ?? Data()
    }

    private static func resize(_ image: UIImage, maxEdge: CGFloat) -> UIImage? {
        let size = image.size
        let longEdge = max(size.width, size.height)
        guard longEdge > 0 else { return nil }
        let scale = min(1, maxEdge / longEdge)
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
