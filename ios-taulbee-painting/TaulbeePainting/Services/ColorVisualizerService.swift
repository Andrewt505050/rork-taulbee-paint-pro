//
//  ColorVisualizerService.swift
//  TaulbeePainting
//
//  Sends a room/exterior photo + a target paint color to a Gemini image model
//  (Nano Banana 2) via the Rork proxy and returns a photorealistic repaint.
//

import UIKit

nonisolated enum VisualizerError: LocalizedError {
    case notConfigured
    case imageTooLarge
    case authError
    case insufficientBalance
    case rateLimited
    case serverError(Int)
    case noImageReturned
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .notConfigured: "The Vision Tool isn't configured yet. Please try again later."
        case .imageTooLarge: "That photo is too large. Try a smaller one."
        case .authError: "The Vision Tool is currently unavailable. Please restart the app."
        case .insufficientBalance: "The Vision Tool is temporarily unavailable. Please try again later."
        case .rateLimited: "Too many requests at once. Please wait a moment and try again."
        case .serverError: "Something went wrong while rendering. Please try again."
        case .noImageReturned: "We couldn't render that preview. Try another photo or color."
        case .decodingFailed: "We couldn't read the rendered image. Please try again."
        }
    }
}

/// The surface the customer wants repainted in their photo.
nonisolated enum PaintTarget: String, CaseIterable, Identifiable {
    case interiorWalls
    case exteriorSiding
    case trim
    case frontDoor
    case cabinets

    var id: String { rawValue }

    var label: String {
        switch self {
        case .interiorWalls: "Interior walls"
        case .exteriorSiding: "Exterior siding"
        case .trim: "Trim & accents"
        case .frontDoor: "Front door"
        case .cabinets: "Cabinets"
        }
    }

    var systemImage: String {
        switch self {
        case .interiorWalls: "square.split.bottomrightquarter"
        case .exteriorSiding: "house.fill"
        case .trim: "rectangle.portrait.inset.filled"
        case .frontDoor: "door.left.hand.closed"
        case .cabinets: "cabinet.fill"
        }
    }

    /// Phrase describing exactly which surfaces to recolor.
    var promptPhrase: String {
        switch self {
        case .interiorWalls: "the main interior wall surfaces"
        case .exteriorSiding: "the exterior siding and main wall surfaces of the house"
        case .trim: "only the trim, molding, baseboards and accent woodwork"
        case .frontDoor: "only the front entry door"
        case .cabinets: "only the cabinet doors, drawer fronts and cabinet frames"
        }
    }

    /// Compact name for the surface chips on the live canvas.
    var shortLabel: String {
        switch self {
        case .interiorWalls: "Walls"
        case .exteriorSiding: "Siding"
        case .trim: "Trim"
        case .frontDoor: "Door"
        case .cabinets: "Cabinets"
        }
    }

    /// Layering order when several surfaces are painted together — higher
    /// values paint over lower ones, the way a real job cuts trim and doors
    /// in over walls.
    var zOrder: Int {
        switch self {
        case .interiorWalls: 0
        case .exteriorSiding: 1
        case .cabinets: 2
        case .trim: 3
        case .frontDoor: 4
        }
    }
}

/// One surface plus the paint color assigned to it in a scheme.
nonisolated struct SurfacePaint: Identifiable, Hashable {
    let target: PaintTarget
    let color: PaintColor

    var id: String { target.rawValue }
}

nonisolated struct ColorVisualizerService {
    /// Nano Banana 2: fast, affordable multimodal image editing that preserves scene geometry.
    private let model = "google/gemini-3.1-flash-image-preview"

    private var baseURL: String { Config.EXPO_PUBLIC_TOOLKIT_URL }
    private var secret: String { Config.EXPO_PUBLIC_RORK_TOOLKIT_SECRET_KEY }

    /// Repaints one or more surfaces — each with its own color — in a single
    /// photorealistic pass.
    func repaint(image: UIImage, plan: [SurfacePaint]) async throws -> UIImage {
        guard !plan.isEmpty else { throw VisualizerError.noImageReturned }
        guard !baseURL.isEmpty, !secret.isEmpty else { throw VisualizerError.notConfigured }
        guard let jpeg = ImageResizer.jpegUnderBudget(image) else { throw VisualizerError.imageTooLarge }

        let base64 = jpeg.base64EncodedString()
        let dataURI = "data:image/jpeg;base64,\(base64)"
        let url = URL(string: "\(baseURL)/v2/vercel/v1/chat/completions")!

        let ordered = plan.sorted { $0.target.zOrder < $1.target.zOrder }
        let assignments = ordered
            .map { paint in
                "- \(paint.target.promptPhrase): paint with \"\(paint.color.name)\" " +
                "(\(paint.color.brand.displayName) \(paint.color.code)), approximately hex #\(paint.color.hex)"
            }
            .joined(separator: "\n")
        let phrases = ordered.map { $0.target.promptPhrase }.joined(separator: "; ")

        let prompt = """
        Repaint the following surfaces in this photo, each with its own specified paint color:
        \(assignments)
        Apply every color realistically, following the existing lighting, shadows, highlights, \
        surface texture and perspective so it looks like a real professional paint job. Where two \
        repainted surfaces meet, keep the edges crisp and clean, as if walls, trim and doors were \
        cut in separately by a professional painter. Keep everything else exactly the same — do \
        not change furniture, flooring, windows, glass, hardware, plants, sky, landscaping, \
        people, or any surface other than: \(phrases). Produce a clean, photorealistic result at \
        the same composition and framing as the original photo.
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
              let result = UIImage(data: imageData) else {
            throw VisualizerError.decodingFailed
        }
        return result
    }
}

// MARK: - Response decoding

/// Gemini may return images either as plain strings or `{ image_url: { url } }`
/// objects in `message.images[]`. This handles both shapes. Shared with the
/// surface-detection service.
nonisolated struct ImageChatResponse: Decodable {
    struct Choice: Decodable {
        struct Message: Decodable {
            let images: [ImageEntry]?
        }
        let message: Message
    }
    let choices: [Choice]
}

nonisolated struct ImageEntry: Decodable {
    let raw: String?

    private struct ImageURL: Decodable { let url: String }

    init(from decoder: Decoder) throws {
        if let single = try? decoder.singleValueContainer(), let str = try? single.decode(String.self) {
            raw = str
            return
        }
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let url = try? container.decode(String.self, forKey: .imageUrlString) {
            raw = url
        } else if let nested = try? container.decode(ImageURL.self, forKey: .imageUrl) {
            raw = nested.url
        } else {
            raw = nil
        }
    }

    enum CodingKeys: String, CodingKey {
        case imageUrl = "image_url"
        case imageUrlString = "url"
    }

    /// Strips any `data:...;base64,` prefix and returns raw base64.
    var normalizedBase64: String? {
        guard let raw else { return nil }
        if raw.hasPrefix("data:"), let comma = raw.firstIndex(of: ",") {
            return String(raw[raw.index(after: comma)...])
        }
        return raw
    }
}
