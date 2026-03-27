import Foundation
import SwiftData

@Observable
final class HandoffService {
    private var lastActiveTime: Date?
    private var lastSessionStart: Date?

    func checkForHandoff(baby: Baby, context: ModelContext) {
        let now = Date()
        let calendar = Calendar.current

        if let lastActive = lastActiveTime {
            let gap = now.timeIntervalSince(lastActive)
            let gapHours = gap / 3600

            if gapHours >= 2 {
                generateHandoffCard(baby: baby, since: lastActive, context: context)
                lastSessionStart = now
            }
        } else {
            let hour = calendar.component(.hour, from: now)
            if hour >= 6, hour <= 10 {
                let todayStart = calendar.startOfDay(for: now)
                generateHandoffCard(baby: baby, since: todayStart, context: context)
            }
            lastSessionStart = now
        }

        lastActiveTime = now
    }

    private func generateHandoffCard(baby: Baby, since: Date, context: ModelContext) {
        let existingDesc = FetchDescriptor<ConversationEntry>(
            predicate: #Predicate<ConversationEntry> { entry in
                entry.timestamp >= since
            },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        let recentEntries = (try? context.fetch(existingDesc)) ?? []
        let hasHandoff = recentEntries.contains { $0.type == .handoffSummary && $0.babyID == baby.id }
        guard !hasHandoff else { return }

        let eventDesc = FetchDescriptor<BabyEvent>(
            predicate: #Predicate<BabyEvent> { event in
                event.timestamp >= since
            },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        guard let recentEvents = try? context.fetch(eventDesc) else { return }
        let babyEvents = recentEvents.filter { $0.baby?.id == baby.id }
        guard !babyEvents.isEmpty else { return }

        let feedCount = babyEvents.filter { $0.category == .feeding }.count
        let sleepMinutes = babyEvents.filter { $0.category == .sleep }.compactMap(\.durationMinutes).reduce(0, +)
        let diaperCount = babyEvents.filter { $0.category == .diaper }.count
        let healthEvents = babyEvents.filter { $0.category == .health }
        let milestones = babyEvents.filter { $0.category == .milestone }

        var parts: [String] = []
        parts.append(greetingForTime())

        if feedCount > 0 || diaperCount > 0 || sleepMinutes > 0 {
            parts.append("Since you were last here:")
        }

        if feedCount > 0 {
            parts.append("\(feedCount) feed\(feedCount == 1 ? "" : "s")")
        }
        if sleepMinutes > 30 {
            let hours = Int(sleepMinutes) / 60
            let mins = Int(sleepMinutes) % 60
            let sleepStr = hours > 0 ? "\(hours)h \(mins)m sleep" : "\(mins)m sleep"
            parts.append(sleepStr)
        }
        if diaperCount > 0 {
            parts.append("\(diaperCount) diaper\(diaperCount == 1 ? "" : "s")")
        }

        if let tempEvent = healthEvents.first(where: { ($0.temperatureF ?? 0) >= 100.4 }) {
            parts.append(String(format: "Temp was %.1f\u{00B0}F — keep monitoring", tempEvent.temperatureF ?? 0))
        }

        if let milestone = milestones.first {
            parts.append(milestone.milestoneDescription ?? "A new milestone!")
        }

        let text = parts.joined(separator: ". ") + "."

        let entry = ConversationEntry(type: .handoffSummary, text: text, babyID: baby.id)
        entry.handoffFeedCount = feedCount
        entry.handoffSleepMinutes = sleepMinutes
        entry.handoffDiaperCount = diaperCount
        context.insert(entry)
    }

    private func greetingForTime() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<21: return "Good evening"
        default: return "Welcome back"
        }
    }
}
