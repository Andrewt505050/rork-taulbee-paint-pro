//
//  DefectScannerService.swift
//  TaulbeePainting
//
//  Sends a photo to the AI vision model and returns a structured paint-defect
//  diagnosis. Uses the Rork proxy (OpenAI-compatible chat completions).
//

import UIKit

nonisolated enum ScannerError: LocalizedError {
    case notConfigured
    case imageTooLarge
    case authError
    case insufficientBalance
    case rateLimited
    case serverError(Int)
    case emptyResponse
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .notConfigured: "Scanner isn't configured yet. Please try again later."
        case .imageTooLarge: "That photo is too large to analyze. Try a different one."
        case .authError: "The scanner is currently unavailable. Please restart the app."
        case .insufficientBalance: "The scanner is temporarily unavailable. Please try again later."
        case .rateLimited: "Too many scans at once. Please wait a moment and try again."
        case .serverError: "Something went wrong while analyzing. Please try again."
        case .emptyResponse: "We couldn't read a result from that photo. Try another angle."
        case .decodingFailed: "We couldn't interpret the diagnosis. Please try again."
        }
    }
}

nonisolated struct DefectScannerService {
    /// Gemini 3 Flash: fast, affordable, strong vision + JSON adherence.
    private let model = "google/gemini-3-flash"

    private var baseURL: String { Config.EXPO_PUBLIC_TOOLKIT_URL }
    private var secret: String { Config.EXPO_PUBLIC_RORK_TOOLKIT_SECRET_KEY }

    private let systemPrompt = """
    You are a senior residential painting inspector for Taulbee Painting with 25 years \
    of experience diagnosing interior and exterior paint and coating failures.

    Analyze the photo and identify the single most likely paint or coating defect \
    (examples: peeling, blistering, alligatoring, cracking/flaking, efflorescence, \
    mildew/mold, chalking, fading, sagging/runs, lap marks, nail/tannin/water staining, \
    surfactant leaching, wrinkling, poor hide/coverage).

    Respond with STRICT, MINIFIED JSON only — no markdown, no commentary, no code fences. \
    Use exactly this schema:
    {
      "isPaintIssue": boolean,            // false if the photo is not a paint/wall surface
      "defectName": string,               // short, e.g. "Peeling Paint"
      "confidence": number,               // 0.0 - 1.0
      "severity": string,                 // one of: "minor", "moderate", "serious"
      "summary": string,                  // 1-2 friendly sentences for a homeowner
      "surface": string,                  // e.g. "Exterior wood trim", "Interior drywall", "Unknown"
      "causes": string[],                 // 2-4 likely causes, plain language
      "solutions": string[],              // 3-5 ordered, actionable DIY/prep steps
      "whenToCallPro": string             // 1 sentence on when to call Taulbee Painting
    }

    If the image clearly is not a paintable surface or no defect is visible, set \
    isPaintIssue=false, defectName="No paint issue detected", give a gentle summary, \
    and leave causes/solutions reasonable but minimal. Keep all text concise and homeowner-friendly.
    """

    func analyze(image: UIImage) async throws -> DefectAnalysis {
        guard !baseURL.isEmpty, !secret.isEmpty else { throw ScannerError.notConfigured }
        guard let jpeg = ImageResizer.jpegUnderBudget(image) else { throw ScannerError.imageTooLarge }

        let dataURI = "data:image/jpeg;base64,\(jpeg.base64EncodedString())"
        let url = URL(string: "\(baseURL)/v2/vercel/v1/chat/completions")!

        let body: [String: Any] = [
            "model": model,
            "temperature": 0.2,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": [
                    ["type": "text", "text": "Diagnose the paint defect in this photo and return JSON only."],
                    ["type": "image_url", "image_url": ["url": dataURI]]
                ]]
            ]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 60
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(secret)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw ScannerError.serverError(-1)
        }

        guard let http = response as? HTTPURLResponse else { throw ScannerError.serverError(-1) }
        switch http.statusCode {
        case 200: break
        case 401: throw ScannerError.authError
        case 402: throw ScannerError.insufficientBalance
        case 413: throw ScannerError.imageTooLarge
        case 429: throw ScannerError.rateLimited
        default: throw ScannerError.serverError(http.statusCode)
        }

        let envelope = try JSONDecoder().decode(ChatResponse.self, from: data)
        guard let content = envelope.choices.first?.message.content,
              !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ScannerError.emptyResponse
        }

        guard let analysis = Self.decodeAnalysis(from: content) else {
            throw ScannerError.decodingFailed
        }
        return analysis
    }

    /// Extracts JSON from the model response, tolerating code fences or stray prose.
    static func decodeAnalysis(from raw: String) -> DefectAnalysis? {
        let candidates = [raw, stripFences(raw), extractBraced(raw)].compactMap { $0 }
        for candidate in candidates {
            if let data = candidate.data(using: .utf8),
               let analysis = try? JSONDecoder().decode(DefectAnalysis.self, from: data) {
                return analysis
            }
        }
        return nil
    }

    private static func stripFences(_ s: String) -> String {
        s.replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func extractBraced(_ s: String) -> String? {
        guard let first = s.firstIndex(of: "{"), let last = s.lastIndex(of: "}"), first < last else {
            return nil
        }
        return String(s[first...last])
    }
}

private nonisolated struct ChatResponse: Codable {
    struct Choice: Codable {
        struct Message: Codable { let content: String? }
        let message: Message
    }
    let choices: [Choice]
}
