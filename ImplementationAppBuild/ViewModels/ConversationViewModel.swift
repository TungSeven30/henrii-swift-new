import Foundation
import SwiftData
import SwiftUI

@Observable
final class ConversationViewModel {
    var composerText: String = ""
    var showUndoToast: Bool = false
    var undoEvent: BabyEvent?
    var undoEntry: ConversationEntry?
    var recentInsight: String?

    private let settings = SettingsManager.shared

    func processInput(_ input: String, baby: Baby, context: ModelContext) {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        insertDaySeparatorIfNeeded(baby: baby, context: context)

        let userEntry = ConversationEntry(type: .userMessage, text: trimmed, babyID: baby.id)
        context.insert(userEntry)

        guard let parsed = InputParser.parse(trimmed) else {
            let noteEntry = ConversationEntry(type: .system, text: "I didn't quite catch that. Try something like \"fed 4oz\" or \"diaper change\".", babyID: baby.id)
            context.insert(noteEntry)
            return
        }

        if parsed.isCorrection {
            handleCorrection(parsed, baby: baby, context: context)
            return
        }

        if parsed.isSleepEnd {
            handleSleepEnd(baby: baby, context: context)
            return
        }

        let event = createEvent(from: parsed)
        event.baby = baby
        context.insert(event)

        let confirmation = ConversationEntry(
            type: .confirmation,
            text: event.summaryText,
            eventID: event.id,
            babyID: baby.id
        )
        context.insert(confirmation)

        undoEvent = event
        undoEntry = confirmation
        showUndoToast = true

        generateInsightIfNeeded(baby: baby, event: event, context: context)
        generateNudgeIfNeeded(baby: baby, event: event, context: context)

        composerText = ""
    }

    func quickLog(category: EventCategory, baby: Baby, context: ModelContext, feedingType: FeedingType? = nil, diaperType: DiaperType? = nil, amountOz: Double? = nil) {
        insertDaySeparatorIfNeeded(baby: baby, context: context)

        let event = BabyEvent(category: category)
        event.baby = baby
        event.feedingType = feedingType
        event.diaperType = diaperType
        event.amountOz = amountOz
        context.insert(event)

        let confirmation = ConversationEntry(
            type: .confirmation,
            text: event.summaryText,
            eventID: event.id,
            babyID: baby.id
        )
        context.insert(confirmation)

        undoEvent = event
        undoEntry = confirmation
        showUndoToast = true

        generateInsightIfNeeded(baby: baby, event: event, context: context)
        generateNudgeIfNeeded(baby: baby, event: event, context: context)
    }

    func undoLastEvent(context: ModelContext) {
        if let entry = undoEntry {
            context.delete(entry)
        }
        if let event = undoEvent {
            context.delete(event)
        }
        undoEvent = nil
        undoEntry = nil
        showUndoToast = false
    }

    func deleteEvent(_ event: BabyEvent, context: ModelContext) {
        context.delete(event)
    }

    private func handleCorrection(_ parsed: ParsedEvent, baby: Baby, context: ModelContext) {
        let descriptor = FetchDescriptor<BabyEvent>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        guard let recentEvents = try? context.fetch(descriptor),
              let lastEvent = recentEvents.first(where: { $0.baby?.id == baby.id }) else {
            let entry = ConversationEntry(type: .system, text: "Nothing to correct yet.", babyID: baby.id)
            context.insert(entry)
            return
        }

        if let newOz = parsed.correctionAmount {
            let oldText = lastEvent.summaryText
            lastEvent.amountOz = newOz
            let confirmation = ConversationEntry(
                type: .confirmation,
                text: "Updated: \(lastEvent.summaryText)",
                eventID: lastEvent.id,
                babyID: baby.id
            )
            context.insert(confirmation)

            let entryDescriptor = FetchDescriptor<ConversationEntry>(
                sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
            )
            if let entries = try? context.fetch(entryDescriptor) {
                for entry in entries {
                    if entry.eventID == lastEvent.id && entry.type == .confirmation && entry.text == oldText {
                        context.delete(entry)
                        break
                    }
                }
            }
        }
    }

    private func handleSleepEnd(baby: Baby, context: ModelContext) {
        let descriptor = FetchDescriptor<BabyEvent>(
            predicate: #Predicate { $0.endTime == nil },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        if let events = try? context.fetch(descriptor),
           let sleepEvent = events.first(where: { $0.category == .sleep && $0.baby?.id == baby.id }) {
            sleepEvent.endTime = Date()
            let duration = Date().timeIntervalSince(sleepEvent.timestamp) / 60
            sleepEvent.durationMinutes = duration

            let confirmation = ConversationEntry(
                type: .confirmation,
                text: sleepEvent.summaryText,
                eventID: sleepEvent.id,
                babyID: baby.id
            )
            context.insert(confirmation)

            if duration >= 120 {
                let celebration = ConversationEntry(
                    type: .celebration,
                    text: "\(baby.name) slept for over 2 hours! Great stretch.",
                    babyID: baby.id
                )
                context.insert(celebration)
            }
        } else {
            let entry = ConversationEntry(type: .system, text: "No active sleep session found. Starting a new one.", babyID: baby.id)
            context.insert(entry)
            let event = BabyEvent(category: .sleep)
            event.baby = baby
            context.insert(event)
        }
    }

    private func createEvent(from parsed: ParsedEvent) -> BabyEvent {
        let event = BabyEvent(category: parsed.category)
        event.feedingType = parsed.feedingType
        event.amountOz = parsed.amountOz
        event.durationMinutes = parsed.durationMinutes
        event.diaperType = parsed.diaperType
        event.temperatureF = parsed.temperatureF
        event.medicationName = parsed.medicationName
        event.medicationDose = parsed.medicationDose
        event.weightLbs = parsed.weightLbs
        event.heightInches = parsed.heightInches
        event.foodType = parsed.foodType
        event.symptoms = parsed.notes != nil && parsed.category == .health ? parsed.notes : nil
        if parsed.category == .note || parsed.category == .activity || parsed.category == .milestone {
            event.notes = parsed.notes
        }
        if parsed.category == .diaper && parsed.notes != nil {
            event.notes = parsed.notes
        }
        if parsed.category == .milestone {
            event.milestoneDescription = parsed.notes
        }
        return event
    }

    private func insertDaySeparatorIfNeeded(baby: Baby, context: ModelContext) {
        let todayStart = Calendar.current.startOfDay(for: Date())
        let descriptor = FetchDescriptor<ConversationEntry>(
            predicate: #Predicate<ConversationEntry> { $0.timestamp >= todayStart },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )

        let todayEntries = (try? context.fetch(descriptor)) ?? []
        let hasSeparator = todayEntries.contains { $0.type == .daySeparator }
        guard !hasSeparator else { return }

        let lastEntryDesc = FetchDescriptor<ConversationEntry>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        let lastEntries = (try? context.fetch(lastEntryDesc)) ?? []
        guard let lastEntry = lastEntries.first else { return }

        let lastDay = Calendar.current.startOfDay(for: lastEntry.timestamp)
        if lastDay < todayStart {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            let sep = ConversationEntry(
                type: .daySeparator,
                text: formatter.string(from: Date()),
                babyID: baby.id
            )
            context.insert(sep)
        }
    }

    private func generateInsightIfNeeded(baby: Baby, event: BabyEvent, context: ModelContext) {
        guard settings.insightFrequency > 0.1 else { return }

        let todayStart = Calendar.current.startOfDay(for: Date())
        let descriptor = FetchDescriptor<BabyEvent>(
            predicate: #Predicate { $0.timestamp >= todayStart }
        )
        guard let todayEvents = try? context.fetch(descriptor) else { return }

        let feedCount = todayEvents.filter { $0.category == .feeding }.count
        let diaperCount = todayEvents.filter { $0.category == .diaper }.count
        let sleepMinutes = todayEvents.filter { $0.category == .sleep }.compactMap(\.durationMinutes).reduce(0, +)

        if feedCount == 8 && event.category == .feeding {
            let insight = ConversationEntry(type: .insight, text: "That's 8 feeds today — right on track for this age.", babyID: baby.id)
            context.insert(insight)
        } else if feedCount == 4 && event.category == .feeding && settings.insightFrequency > 0.3 {
            let insight = ConversationEntry(type: .insight, text: "Halfway there — 4 feeds so far today.", babyID: baby.id)
            context.insert(insight)
        }

        if diaperCount == 6 && event.category == .diaper {
            let insight = ConversationEntry(type: .insight, text: "6 diapers today. Good hydration signs.", babyID: baby.id)
            context.insert(insight)
        }

        if sleepMinutes >= 600 && event.category == .sleep && event.durationMinutes != nil {
            let hours = Int(sleepMinutes) / 60
            let insight = ConversationEntry(type: .insight, text: "\(baby.name) has gotten about \(hours) hours of sleep today. That's solid.", babyID: baby.id)
            context.insert(insight)
        }

        if event.category == .feeding, let oz = event.amountOz, oz >= 6 {
            let insight = ConversationEntry(type: .insight, text: "That's a big feed! \(baby.name) was hungry.", babyID: baby.id)
            context.insert(insight)
        }

        if event.category == .health, let temp = event.temperatureF, temp >= 100.4 {
            let alert = ConversationEntry(type: .insight, text: "\u{26A0}\u{FE0F} Temperature is \(String(format: "%.1f", temp))\u{00B0}F — that's above normal. Keep monitoring and contact your pediatrician if it persists.", babyID: baby.id)
            context.insert(alert)
        }
    }

    private func generateNudgeIfNeeded(baby: Baby, event: BabyEvent, context: ModelContext) {
        guard settings.insightFrequency > 0.3 else { return }

        let todayStart = Calendar.current.startOfDay(for: Date())
        let descriptor = FetchDescriptor<BabyEvent>(
            predicate: #Predicate { $0.timestamp >= todayStart }
        )
        guard let todayEvents = try? context.fetch(descriptor) else { return }

        if event.category == .feeding {
            let lastSleep = todayEvents.filter { $0.category == .sleep }.max(by: { $0.timestamp < $1.timestamp })
            if let lastSleep, let endTime = lastSleep.endTime {
                let hoursSinceWake = Date().timeIntervalSince(endTime) / 3600
                if hoursSinceWake > 2 && baby.ageInMonths < 6 {
                    let nudge = ConversationEntry(type: .nudge, text: "It's been about \(Int(hoursSinceWake)) hours since \(baby.name) woke up. A nap might be coming soon.", babyID: baby.id)
                    context.insert(nudge)
                }
            }
        }

        if event.category == .diaper {
            let lastFeed = todayEvents.filter { $0.category == .feeding }.max(by: { $0.timestamp < $1.timestamp })
            if let lastFeed {
                let hoursSinceFeed = Date().timeIntervalSince(lastFeed.timestamp) / 3600
                if hoursSinceFeed > 3 {
                    let nudge = ConversationEntry(type: .nudge, text: "It's been \(Int(hoursSinceFeed)) hours since the last feed. \(baby.name) might be getting hungry.", babyID: baby.id)
                    context.insert(nudge)
                }
            }
        }
    }
}
