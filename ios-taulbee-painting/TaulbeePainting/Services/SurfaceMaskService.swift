//
//  SurfaceMaskService.swift
//  TaulbeePainting
//
//  Asks the image AI for a black & white segmentation mask of the chosen
//  paintable surface. Runs once per photo + surface; the returned mask then
//  powers unlimited instant on-device recolors via RecolorEngine.
//

import UIKit

nonisolated struct SurfaceMaskService {
    private let model = "google/gemini-3.1-flash-image-preview"

    private var baseURL: String { Config.EXPO_PUBLIC_TOOLKIT_URL }
    private var secret: String { Config.EXPO_PUBLIC_RORK_TOOLKIT_SECRET_KEY }

    /// Returns a grayscale mask image where the target surface is white and
    /// everything else is black. Throws `VisualizerError` on failure so the
    /// caller can quietly fall back to direct AI rendering.
    func detectSurface(in image: UIImage, target: PaintTarget) async throws -> UIImage {
        guard !baseURL.isEmpty, !secret.isEmpty else { throw VisualizerError.notConfigured }
        guard let jpeg = ImageResizer.jpegUnderBudget(image) else { throw VisualizerError.imageTooLarge }

        let dataURI = "data:image/jpeg;base64,\(jpeg.base64EncodedString())"
        let url = URL(string: "\(baseURL)/v2/vercel/v1/chat/completions")!

        let prompt = """
        Create a segmentation mask of this photo. Output ONLY an image with the exact same \
        framing and aspect ratio as the input photo, where every pixel that belongs to \
        \(target.promptPhrase) is pure white (#FFFFFF) and every other pixel is pure black \
        (#000000).
        Be strict about the surface boundary: \(target.maskExclusions) are NOT part of the \
        target surface and must stay pure black, even where they are a very similar color or \
        brightness to it. Follow the geometry of the scene — a plane that changes orientation \
        (like where a wall meets the ceiling) is a boundary, not a continuation.
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
