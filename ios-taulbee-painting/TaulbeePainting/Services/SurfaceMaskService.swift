//
//  SurfaceMaskService.swift
//  TaulbeePainting
//
//  Asks the image AI for a black & white segmentation mask of the chosen
//  paintable surface. Runs once per photo + surface; the returned mask then
//  powers unlimited instant on-device recolors via RecolorEngine.
//
//  Detection is anchored by the spot the customer tapped and every mask is
//  sanity-checked (MaskValidator) before it's accepted. A mask that outlines
//  the wrong plane — a pale ceiling instead of the walls — triggers one
//  stricter retry; if that also fails, the caller gets `surfaceNotFound`.
//

import UIKit

nonisolated struct SurfaceMaskService {
    private let model = "google/gemini-3.1-flash-image-preview"

    private var baseURL: String { Config.EXPO_PUBLIC_TOOLKIT_URL }
    private var secret: String { Config.EXPO_PUBLIC_RORK_TOOLKIT_SECRET_KEY }

    /// Detects the target surface, validates the result, and retries once
    /// with a firmer instruction when the first mask fails its sanity check.
    ///
    /// - Parameter hint: Where the customer tapped, normalized 0...1 on both
    ///   axes with the origin at the top-left of the upright photo.
    func detectSurface(in image: UIImage, target: PaintTarget, hint: CGPoint?) async throws -> UIImage {
        guard !baseURL.isEmpty, !secret.isEmpty else { throw VisualizerError.notConfigured }
        guard let jpeg = ImageResizer.jpegUnderBudget(image) else { throw VisualizerError.imageTooLarge }

        let first = try await requestMask(jpeg: jpeg, target: target, hint: hint, retryAfter: nil)
        guard let firstAnalysis = MaskAnalysis(mask: first) else { throw VisualizerError.decodingFailed }
        guard let rejection = MaskValidator.validate(firstAnalysis, target: target, hint: hint) else {
            return first
        }

        let second = try await requestMask(jpeg: jpeg, target: target, hint: hint, retryAfter: rejection)
        guard let secondAnalysis = MaskAnalysis(mask: second) else { throw VisualizerError.decodingFailed }
        if MaskValidator.validate(secondAnalysis, target: target, hint: hint) == nil {
            return second
        }

        // Both passes failed. Without a tap there's nothing to anchor a third
        // guess to, so surface the problem instead of painting the wrong area.
        throw VisualizerError.surfaceNotFound(target)
    }

    /// Raw single-pass detection without validation.
    func detectSurface(in image: UIImage, target: PaintTarget) async throws -> UIImage {
        try await detectSurface(in: image, target: target, hint: nil)
    }

    // MARK: - Request

    private func requestMask(jpeg: Data, target: PaintTarget, hint: CGPoint?, retryAfter: MaskRejection?) async throws -> UIImage {
        let dataURI = "data:image/jpeg;base64,\(jpeg.base64EncodedString())"
        let url = URL(string: "\(baseURL)/v2/vercel/v1/chat/completions")!

        var hintText = ""
        if let hint {
            let x = Int((Double(hint.x) * 100).rounded())
            let y = Int((Double(hint.y) * 100).rounded())
            hintText = """

            The user tapped the target surface at a point \(x)% from the left edge and \(y)% from \
            the top edge of the photo. That point is ON the target surface and must be white. \
            Select the whole continuous surface that point belongs to, plus any other parts of the \
            same kind of surface in the photo; do not select a different plane that merely touches it.
            """
        }

        var retryText = ""
        if let retryAfter {
            retryText = "\n\nIMPORTANT CORRECTION: \(retryAfter.retryInstruction)"
        }

        let prompt = """
        Create a segmentation mask of this photo. Output ONLY an image with the exact same \
        framing and aspect ratio as the input photo, where every pixel that belongs to \
        \(target.promptPhrase) is pure white (#FFFFFF) and every other pixel is pure black \
        (#000000).
        \(target.geometryNote)
        Be strict about the surface boundary: \(target.maskExclusions) are NOT part of the \
        target surface and must stay pure black, even where they are a very similar color or \
        brightness to it. Follow the geometry of the scene — a plane that changes orientation \
        (like where a wall meets the ceiling) is a boundary, not a continuation.\(hintText)\(retryText)
        Use only those two flat colors — no gray tones, no gradients, no outlines, \
        no text, and no labels. Do not repaint, restyle, or alter the scene in any other way; \
        return strictly the black-and-white mask image.
        """

        let body: [String: Any] = [
            "model": model,
            "modalities": ["text", "image"],
            "messages": [
                ["role": "user", "content": [
                    ["type": "image_url", "image_url": ["url": dataURI]],
                    ["type": "text", "text": prompt]
                ]]
            ]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 120
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(secret)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw VisualizerError.serverError(-1)
        }

        guard let http = response as? HTTPURLResponse else { throw VisualizerError.serverError(-1) }
        switch http.statusCode {
        case 200: break
        case 401: throw VisualizerError.authError
        case 402: throw VisualizerError.insufficientBalance
        case 413: throw VisualizerError.imageTooLarge
        case 429: throw VisualizerError.rateLimited
        default: throw VisualizerError.serverError(http.statusCode)
        }

        let envelope = try JSONDecoder().decode(ImageChatResponse.self, from: data)
        guard let imageString = envelope.choices.first?.message.images?.first?.normalizedBase64 else {
            throw VisualizerError.noImageReturned
        }
        guard let imageData = Data(base64Encoded: imageString),
              let mask = UIImage(data: imageData) else {
            throw VisualizerError.decodingFailed
        }
        return mask
    }
}
