import Foundation
import SwiftData
import SwiftUI

@Observable
final class ConversationViewModel {
    var composerText: String = ""
    var showUndoToast: Bool = false
    var undoEvent: BabyEvent?
    var recentInsight: String?

    func processInput(_ input: String, baby: Baby, context: ModelContext) {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let userEntry = ConversationEntry(type: .userMessage, text: trimmed)
        context.insert(userEntry)

        guard let parsed = InputParser.parse(trimmed) else {
            let noteEntry = ConversationEntry(type: .system, text: "I didn't quite catch that. Try something like \"fed 4oz\" or \"diaper change\".")
            context.insert(noteEntry)
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
            eventID: event.id
        )
        context.insert(confirmation)

        undoEvent = event
        showUndoToast = true

        generateInsightIfNeeded(baby: baby, event: event, context: context)

        composerText = ""
    }

    func quickLog(category: EventCategory, baby: Baby, context: ModelContext, feedingType: FeedingType? = nil, diaperType: DiaperType? = nil) {
        let event = BabyEvent(category: category)
        event.baby = baby
        event.feedingType = feedingType
        event.diaperType = diaperType
        context.insert(event)

        let confirmation = ConversationEntry(
            type: .confirmation,
            text: event.summaryText,
            eventID: event.id
        )
        context.insert(confirmation)

        undoEvent = event
        showUndoToast = true
    }

    func undoLastEvent(context: ModelContext) {
        guard let event = undoEvent else { return }
        context.delete(event)
        undoEvent = nil
        showUndoToast = false
    }

    func deleteEvent(_ event: BabyEvent, context: ModelContext) {
        context.delete(event)
    }

    private func handleSleepEnd(baby: Baby, context: ModelContext) {
        let descriptor = FetchDescriptor<BabyEvent>(
            predicate: #Predicate { $0.endTime == nil },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        if let events = try? context.fetch(descriptor),
           let sleepEvent = events.first(where: { $0.category == .sleep }) {
            sleepEvent.endTime = Date()
            let duration = Date().timeIntervalSince(sleepEvent.timestamp) / 60
            sleepEvent.durationMinutes = duration

            let confirmation = ConversationEntry(
                type: .confirmation,
                text: sleepEvent.summaryText,
                eventID: sleepEvent.id
            )
            context.insert(confirmation)
        } else {
            let entry = ConversationEntry(type: .system, text: "No active sleep session found. Starting a new one.")
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
        if parsed.category == .note || parsed.category == .activity {
            event.notes = parsed.notes
        }
        return event
    }

    private func generateInsightIfNeeded(baby: Baby, event: BabyEvent, context: ModelContext) {
        let todayStart = Calendar.current.startOfDay(for: Date())
        let descriptor = FetchDescriptor<BabyEvent>(
            predicate: #Predicate { $0.timestamp >= todayStart }
        )
        guard let todayEvents = try? context.fetch(descriptor) else { return }

        let feedCount = todayEvents.filter { $0.category == .feeding }.count
        let diaperCount = todayEvents.filter { $0.category == .diaper }.count

        if feedCount == 8 && event.category == .feeding {
            let insight = ConversationEntry(type: .insight, text: "That's 8 feeds today \u{2014} right on track for this age.")
            context.insert(insight)
        }

        if diaperCount == 6 && event.category == .diaper {
            let insight = ConversationEntry(type: .insight, text: "6 diapers today. Good hydration signs.")
            context.insert(insight)
        }
    }
}
