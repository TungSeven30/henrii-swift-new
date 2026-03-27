import Foundation
import SwiftData

nonisolated final class DailyIntelligenceService: Sendable {
    static let shared = DailyIntelligenceService()

    private init() {}

    func morningBriefingText(baby: Baby, events: [BabyEvent]) -> String {
        let calendar = Calendar.current
        let start = calendar.date(byAdding: .hour, value: -12, to: Date()) ?? Date()
        let overnight = events.filter { $0.timestamp >= start }

        let wakeUps = overnight.filter { $0.category == .sleep && $0.endTime != nil }.count
        let feeds = overnight.filter { $0.category == .feeding }.count
        let sleepMinutes = overnight.filter { $0.category == .sleep }.compactMap(\.durationMinutes).reduce(0, +)

        let hours = sleepMinutes / 60
        return "Morning briefing: \(wakeUps) wake-ups, \(feeds) feeds, and about \(String(format: "%.1f", hours)) hours of overnight sleep for \(baby.name)."
    }

    func eveningSummaryText(baby: Baby, events: [BabyEvent]) -> String {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())
        let todayEvents = events.filter { $0.timestamp >= todayStart }

        let feeds = todayEvents.filter { $0.category == .feeding }.count
        let diapers = todayEvents.filter { $0.category == .diaper }.count
        let sleepMinutes = todayEvents.filter { $0.category == .sleep }.compactMap(\.durationMinutes).reduce(0, +)

        return "Evening summary: \(feeds) feeds, \(diapers) diapers, and \(String(format: "%.1f", sleepMinutes / 60)) hours of sleep today."
    }

    func weeklyDigestText(baby: Baby, events: [BabyEvent]) -> String {
        let start = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let weekEvents = events.filter { $0.timestamp >= start }

        let feedCount = weekEvents.filter { $0.category == .feeding }.count
        let avgFeedsPerDay = Double(feedCount) / 7
        let growthCount = weekEvents.filter { $0.category == .growth }.count

        return "Weekly digest: averaging \(String(format: "%.1f", avgFeedsPerDay)) feeds/day with \(growthCount) growth check\(growthCount == 1 ? "" : "s") this week."
    }

    @MainActor
    func maybeInsertMorningBriefing(baby: Baby, context: ModelContext) {
        let hour = Calendar.current.component(.hour, from: Date())
        guard hour >= 5 && hour <= 10 else { return }

        let since = Calendar.current.startOfDay(for: Date())
        let existingDescriptor = FetchDescriptor<ConversationEntry>(
            predicate: #Predicate<ConversationEntry> { $0.timestamp >= since }
        )
        let existing = (try? context.fetch(existingDescriptor)) ?? []
        guard !existing.contains(where: { $0.type == .system && $0.text.contains("Morning briefing") && $0.babyID == baby.id }) else { return }

        let eventDescriptor = FetchDescriptor<BabyEvent>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        let events = ((try? context.fetch(eventDescriptor)) ?? []).filter { $0.baby?.id == baby.id }
        guard !events.isEmpty else { return }

        let text = morningBriefingText(baby: baby, events: events)
        let entry = ConversationEntry(type: .system, text: text, babyID: baby.id)
        context.insert(entry)
    }
}
