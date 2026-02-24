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
    case queryResponse
    case medicalFlag
    case dailySummary
    case collapsedGroup
    case handoffSummary
}

@Model
final class ConversationEntry {
    var id: UUID
    var type: EntryType
    var text: String
    var timestamp: Date
    var eventID: UUID?
    var isRead: Bool
    var babyID: UUID?
    var chartData: String?
    var queryTopicRaw: String?
    var isDismissed: Bool
    var groupedEventIDs: String?
    var summaryFeedCount: Int
    var summarySleepHours: Double
    var summaryDiaperCount: Int
    var handoffFeedCount: Int
    var handoffSleepMinutes: Double
    var handoffDiaperCount: Int
    var handoffCaregiver: String?

    init(type: EntryType, text: String, timestamp: Date = Date(), eventID: UUID? = nil, babyID: UUID? = nil, chartData: String? = nil, queryTopicRaw: String? = nil) {
        self.id = UUID()
        self.type = type
        self.text = text
        self.timestamp = timestamp
        self.eventID = eventID
        self.isRead = false
        self.babyID = babyID
        self.chartData = chartData
        self.queryTopicRaw = queryTopicRaw
        self.isDismissed = false
        self.groupedEventIDs = nil
        self.summaryFeedCount = 0
        self.summarySleepHours = 0
        self.summaryDiaperCount = 0
        self.handoffFeedCount = 0
        self.handoffSleepMinutes = 0
        self.handoffDiaperCount = 0
        self.handoffCaregiver = nil
    }
}
