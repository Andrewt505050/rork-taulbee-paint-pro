//
//  ChatMessage.swift
//  TaulbeePainting
//
//  A single message in the Paint Expert conversation. Persisted on-device so
//  customers can pick up where they left off.
//

import Foundation
import SwiftData

@Model
final class ChatMessage {
    var id: UUID
    var createdAt: Date
    /// "user" or "assistant".
    var roleRaw: String
    var text: String

    init(id: UUID = UUID(), createdAt: Date = .now, role: ChatRole, text: String) {
        self.id = id
        self.createdAt = createdAt
        self.roleRaw = role.rawValue
        self.text = text
    }

    var role: ChatRole { ChatRole(rawValue: roleRaw) ?? .assistant }
}

nonisolated enum ChatRole: String, Codable {
    case user
    case assistant
}
