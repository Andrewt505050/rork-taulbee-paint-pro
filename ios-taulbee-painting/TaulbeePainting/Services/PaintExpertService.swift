//
//  PaintExpertService.swift
//  TaulbeePainting
//
//  Sends the conversation to the AI model and returns the Paint Expert's reply.
//  Uses the Rork proxy (OpenAI-compatible chat completions).
//

import Foundation

nonisolated enum ExpertError: LocalizedError {
    case notConfigured
    case authError
    case insufficientBalance
    case rateLimited
    case serverError(Int)
    case emptyResponse

    var errorDescription: String? {
        switch self {
        case .notConfigured: "The Paint Expert isn't available yet. Please try again later."
        case .authError: "The Paint Expert is currently unavailable. Please restart the app."
        case .insufficientBalance: "The Paint Expert is temporarily unavailable. Please try again later."
        case .rateLimited: "A lot of questions at once — please wait a moment and try again."
        case .serverError: "Something went wrong. Please try asking again."
        case .emptyResponse: "I didn't catch that. Could you rephrase your question?"
        }
    }
}

nonisolated struct ExpertTurn {
    let role: ChatRole
    let text: String
}

nonisolated struct PaintExpertService {
    /// Gemini 3 Flash: fast, affordable, strong reasoning for advice.
    private let model = "google/gemini-3-flash"

    private var baseURL: String { Config.EXPO_PUBLIC_TOOLKIT_URL }
    private var secret: String { Config.EXPO_PUBLIC_RORK_TOOLKIT_SECRET_KEY }

    private var systemPrompt: String {
        """
        You are the Taulbee Painting Paint Expert — a warm, knowledgeable residential \
        painting advisor with decades of hands-on experience in interior and exterior \
        work, surface prep, product selection, and fixing common paint problems.

        Your job is to give homeowners clear, practical, trustworthy guidance. Be concise \
        and friendly. Prefer short paragraphs and simple bullet lists. Avoid jargon, or \
        briefly explain it when needed. Give specific, actionable steps.

        When recommending products, draw from the Taulbee recommended product list below \
        and name the brand and product. If something falls outside that list, you may still \
        suggest a product type (e.g. "a waterborne alkyd enamel for trim").

        When a job is large, risky (lead paint, heights, extensive rot/mold), or the homeowner \
        seems unsure, gently suggest they request a free quote from Taulbee Painting at \
        \(BusinessInfo.website). Do not be pushy — only when it genuinely helps.

        Keep replies focused on painting, coatings, prep, color, and home surfaces. If asked \
        something unrelated, kindly steer back to how you can help with their painting project.

        Taulbee recommended products:
        \(ProductCatalog.promptReference)
        """
    }

    /// Sends the full conversation and returns the assistant's reply text.
    func reply(to history: [ExpertTurn]) async throws -> String {
        guard !baseURL.isEmpty, !secret.isEmpty else { throw ExpertError.notConfigured }

        var messages: [[String: Any]] = [["role": "system", "content": systemPrompt]]
        for turn in history {
            messages.append(["role": turn.role.rawValue, "content": turn.text])
        }

        let url = URL(string: "\(baseURL)/v2/vercel/v1/chat/completions")!
        let body: [String: Any] = [
            "model": model,
            "temperature": 0.5,
            "messages": messages
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
            throw ExpertError.serverError(-1)
        }

        guard let http = response as? HTTPURLResponse else { throw ExpertError.serverError(-1) }
        switch http.statusCode {
        case 200: break
        case 401: throw ExpertError.authError
        case 402: throw ExpertError.insufficientBalance
        case 429: throw ExpertError.rateLimited
        default: throw ExpertError.serverError(http.statusCode)
        }

        let envelope = try JSONDecoder().decode(ExpertResponse.self, from: data)
        guard let content = envelope.choices.first?.message.content,
              !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ExpertError.emptyResponse
        }
        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private nonisolated struct ExpertResponse: Codable {
    struct Choice: Codable {
        struct Message: Codable { let content: String? }
        let message: Message
    }
    let choices: [Choice]
}
