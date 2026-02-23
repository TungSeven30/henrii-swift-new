import Foundation
import SwiftData

nonisolated enum EntryType: String, Codable, Sendable {
    case userMessage
    case confirmation
    case insight
    case nudge
    case celebration
    case system
    case daySeparator
}

@Model
final class ConversationEntry {
    var id: UUID
    var type: EntryType
    var text: String
    var timestamp: Date
    var eventID: UUID?
    var isRead: Bool

    init(type: EntryType, text: String, timestamp: Date = Date(), eventID: UUID? = nil) {
        self.id = UUID()
        self.type = type
        self.text = text
        self.timestamp = timestamp
        self.eventID = eventID
        self.isRead = false
    }
}
