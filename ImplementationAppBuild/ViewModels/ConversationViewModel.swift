import Foundation
import SwiftData
import SwiftUI
import WidgetKit

@Observable
final class ConversationViewModel {
    var composerText: String = ""
    var showUndoToast: Bool = false
    var undoEvent: BabyEvent?
    var undoEntry: ConversationEntry?
    var recentInsight: String?

    private let settings = SettingsManager.shared
    private let notificationService = NotificationService.shared

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

        if parsed.isQuery {
            handleQuery(parsed, baby: baby, context: context)
            composerText = ""
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
        if let customDate = parsed.customDate {
            event.timestamp = customDate
        }
        context.insert(event)

        var confirmText = event.summaryText
        if let customDate = parsed.customDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            confirmText += " (\(formatter.string(from: customDate)))"
        }

        let confirmation = ConversationEntry(
            type: .confirmation,
            text: confirmText,
            eventID: event.id,
            babyID: baby.id
        )
        context.insert(confirmation)

        undoEvent = event
        undoEntry = confirmation
        showUndoToast = true

        generateInsightIfNeeded(baby: baby, event: event, context: context)
        generateNudgeIfNeeded(baby: baby, event: event, context: context)
        checkMedicalFlag(baby: baby, event: event, context: context)
        collapseRecentIfNeeded(baby: baby, event: event, context: context)
        scheduleNotificationsIfNeeded(for: event, baby: baby)
        updateWidgetData(baby: baby, context: context)

        composerText = ""
    }

    func quickLog(category: EventCategory, baby: Baby, context: ModelContext, feedingType: FeedingType? = nil, diaperType: DiaperType? = nil, amountOz: Double? = nil, notes: String? = nil) {
        insertDaySeparatorIfNeeded(baby: baby, context: context)

        let event = BabyEvent(category: category)
        event.baby = baby
        event.feedingType = feedingType
        event.diaperType = diaperType
        event.amountOz = amountOz
        event.notes = notes
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
        scheduleNotificationsIfNeeded(for: event, baby: baby)
        updateWidgetData(baby: baby, context: context)
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

    func dismissMedicalFlag(_ entry: ConversationEntry) {
        entry.isDismissed = true
    }

    func generateDailySummary(baby: Baby, context: ModelContext) {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())

        let existingDesc = FetchDescriptor<ConversationEntry>(
            predicate: #Predicate<ConversationEntry> { $0.timestamp >= todayStart }
        )
        let todayEntries = (try? context.fetch(existingDesc)) ?? []
        let hasSummary = todayEntries.contains { $0.type == .dailySummary }
        guard !hasSummary else { return }

        let eventDesc = FetchDescriptor<BabyEvent>(
            predicate: #Predicate { $0.timestamp >= todayStart },
            sortBy: [SortDescriptor(\.timestamp)]
        )
        guard let todayEvents = try? context.fetch(eventDesc) else { return }
        let babyEvents = todayEvents.filter { $0.baby?.id == baby.id }
        guard !babyEvents.isEmpty else { return }

        let feedCount = babyEvents.filter { $0.category == .feeding }.count
        let sleepMinutes = babyEvents.filter { $0.category == .sleep }.compactMap(\.durationMinutes).reduce(0, +)
        let diaperCount = babyEvents.filter { $0.category == .diaper }.count
        let sleepHours = sleepMinutes / 60

        var text = ""
        if feedCount > 0 && sleepHours > 0 && diaperCount > 0 {
            text = "A solid day. \(feedCount) feeds, \(String(format: "%.1f", sleepHours)) hours of sleep, and \(diaperCount) diaper changes."
        } else if feedCount > 0 {
            text = "\(feedCount) feeds logged today so far."
        } else {
            text = "Here's today's snapshot."
        }

        let summary = ConversationEntry(type: .dailySummary, text: text, babyID: baby.id)
        summary.summaryFeedCount = feedCount
        summary.summarySleepHours = sleepHours
        summary.summaryDiaperCount = diaperCount
        context.insert(summary)
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
            lastEvent.amountOz = newOz

            let entryDescriptor = FetchDescriptor<ConversationEntry>(
                sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
            )
            if let entries = try? context.fetch(entryDescriptor) {
                for entry in entries {
                    if entry.eventID == lastEvent.id && entry.type == .confirmation {
                        entry.text = "Updated: \(lastEvent.summaryText)"
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
        event.diaperColor = parsed.diaperColor
        event.symptoms = parsed.notes != nil && parsed.category == .health ? parsed.notes : nil
        if parsed.category == .note || parsed.category == .activity || parsed.category == .milestone {
            event.notes = parsed.notes
        }
        if parsed.category == .milestone {
            event.milestoneDescription = parsed.notes
        }
        return event
    }

    func insertDaySeparatorIfNeeded(baby: Baby, context: ModelContext) {
        let calendar = Calendar.current
        let now = Date()
        let todayStart = calendar.startOfDay(for: now)

        let lastEntryDesc = FetchDescriptor<ConversationEntry>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        let lastEntries = (try? context.fetch(lastEntryDesc)) ?? []
        guard let lastEntry = lastEntries.first(where: { $0.babyID == baby.id || $0.babyID == nil }) else { return }

        let lastDay = calendar.startOfDay(for: lastEntry.timestamp)
        guard lastDay < todayStart else { return }

        let separatorDesc = FetchDescriptor<ConversationEntry>(
            predicate: #Predicate<ConversationEntry> { $0.timestamp >= todayStart },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        let todayEntries = (try? context.fetch(separatorDesc)) ?? []
        let hasSeparator = todayEntries.contains { $0.type == .daySeparator && ($0.babyID == baby.id || $0.babyID == nil) }
        guard !hasSeparator else { return }

        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"

        var datesToInsert: [Date] = []
        var cursor = calendar.startOfDay(for: lastEntry.timestamp)
        while cursor < todayStart {
            guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            datesToInsert.append(next)
            cursor = next
        }

        for date in datesToInsert {
            let label: String
            if calendar.isDateInToday(date) {
                label = "Today"
            } else if calendar.isDateInYesterday(date) {
                label = "Yesterday"
            } else {
                label = formatter.string(from: date)
            }
            let sep = ConversationEntry(
                type: .daySeparator,
                text: label,
                timestamp: date,
                babyID: baby.id
            )
            context.insert(sep)
        }
    }

    private func checkMedicalFlag(baby: Baby, event: BabyEvent, context: ModelContext) {
        guard event.category == .health else { return }

        if let temp = event.temperatureF, temp >= 100.4 {
            let yesterday = Calendar.current.date(byAdding: .hour, value: -24, to: Date())!
            let descriptor = FetchDescriptor<BabyEvent>(
                predicate: #Predicate { $0.timestamp >= yesterday },
                sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
            )
            let recentHealth = (try? context.fetch(descriptor))?.filter { $0.baby?.id == baby.id && $0.category == .health } ?? []
            let elevatedTemps = recentHealth.filter { ($0.temperatureF ?? 0) >= 100.4 }

            if elevatedTemps.count >= 2 {
                let flag = ConversationEntry(
                    type: .medicalFlag,
                    text: "Temperature has been elevated (\(String(format: "%.1f", temp))\u{00B0}F) for multiple readings. Monitor closely and contact your pediatrician if it persists or rises above 104\u{00B0}F.",
                    babyID: baby.id
                )
                context.insert(flag)
            }
        }

        if let medName = event.medicationName {
            let twoDaysAgo = Calendar.current.date(byAdding: .day, value: -2, to: Date())!
            let descriptor = FetchDescriptor<BabyEvent>(
                predicate: #Predicate { $0.timestamp >= twoDaysAgo },
                sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
            )
            let recentMeds = (try? context.fetch(descriptor))?.filter {
                $0.baby?.id == baby.id && $0.medicationName?.lowercased() == medName.lowercased()
            } ?? []

            if recentMeds.count >= 6 {
                let flag = ConversationEntry(
                    type: .medicalFlag,
                    text: "\(medName) has been given \(recentMeds.count) times in the last 48 hours. Please verify dosing schedule with your pediatrician.",
                    babyID: baby.id
                )
                context.insert(flag)
            }
        }
    }

    private func generateInsightIfNeeded(baby: Baby, event: BabyEvent, context: ModelContext) {
        guard settings.insightFrequency > 0.1 else { return }

        let calendar = Calendar.current
        if let lastDate = settings.lastAutoInsightDate, calendar.isDate(lastDate, inSameDayAs: Date()) {
            return
        }

        let todayStart = calendar.startOfDay(for: Date())
        let descriptor = FetchDescriptor<BabyEvent>(
            predicate: #Predicate { $0.timestamp >= todayStart }
        )
        guard let todayEvents = try? context.fetch(descriptor) else { return }

        let babyTodayEvents = todayEvents.filter { $0.baby?.id == baby.id }
        let feedCount = babyTodayEvents.filter { $0.category == .feeding }.count
        let diaperCount = babyTodayEvents.filter { $0.category == .diaper }.count
        let sleepMinutes = babyTodayEvents.filter { $0.category == .sleep }.compactMap(\.durationMinutes).reduce(0, +)

        var insightText: String?
        var confidence: Double = 0

        if feedCount == 8 && event.category == .feeding {
            insightText = "That's 8 feeds today — right on track for this age."
            confidence = 0.9
        } else if feedCount == 4 && event.category == .feeding && settings.insightFrequency > 0.3 {
            insightText = "Halfway there — 4 feeds so far today."
            confidence = 0.86
        } else if diaperCount == 6 && event.category == .diaper {
            insightText = "6 diapers today. Good hydration signs."
            confidence = 0.89
        } else if sleepMinutes >= 600 && event.category == .sleep && event.durationMinutes != nil {
            let hours = Int(sleepMinutes) / 60
            insightText = "\(baby.name) has gotten about \(hours) hours of sleep today. That's solid."
            confidence = 0.88
        } else if event.category == .feeding, let oz = event.amountOz, oz >= 6 {
            insightText = "That's a big feed! \(baby.name) was hungry."
            confidence = 0.85
        } else if event.category == .growth, let weight = event.weightLbs {
            let whoResult = WHOGrowthData.percentile(weightLbs: weight, ageMonths: baby.ageInMonths, gender: baby.gender)
            if whoResult.percentile >= 50 {
                insightText = "\(baby.name) crossed into about the \(ordinal(whoResult.percentile)) percentile for weight today."
                confidence = 0.92
            }
        } else if event.category == .health, let temp = event.temperatureF, temp >= 100.4 {
            insightText = "⚠️ Temperature is \(String(format: "%.1f", temp))°F — that's above normal. Keep monitoring and contact your pediatrician if it persists."
            confidence = 0.95
        }

        guard let insightText, confidence >= settings.insightConfidenceThreshold else { return }
        let insight = ConversationEntry(type: .insight, text: insightText, babyID: baby.id)
        context.insert(insight)
        settings.lastAutoInsightDate = Date()
    }

    private func scheduleNotificationsIfNeeded(for event: BabyEvent, baby: Baby) {
        if event.category == .feeding, settings.feedingNotifications {
            notificationService.scheduleFeedingReminder()
        }

        if event.category == .health,
           settings.medicationNotifications,
           let medicationName = event.medicationName,
           let dose = event.medicationDose,
           let dueDate = Calendar.current.date(byAdding: .hour, value: 4, to: event.timestamp) {
            notificationService.scheduleMedicationReminder(
                title: "Medication Follow-up",
                body: "\(medicationName) \(dose) is due soon for \(baby.name).",
                date: dueDate
            )
        }

        if event.category == .milestone {
            notificationService.scheduleCelebrationNotification(
                title: "Milestone Reached",
                body: "\(baby.name) just logged a new milestone."
            )
        }
    }

    private func handleQuery(_ parsed: ParsedEvent, baby: Baby, context: ModelContext) {
        let topic = parsed.queryTopic ?? .general
        let descriptor = FetchDescriptor<BabyEvent>(
            sortBy: [SortDescriptor(\BabyEvent.timestamp, order: .reverse)]
        )
        let allEvents = (try? context.fetch(descriptor))?.filter { $0.baby?.id == baby.id } ?? []

        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"

        switch topic {
        case .medication:
            handleMedicationQuery(parsed, baby: baby, allEvents: allEvents, context: context)
            return

        case .lastEvent:
            handleLastEventQuery(parsed, baby: baby, allEvents: allEvents, context: context)
            return

        case .weight:
            let weightEvents = allEvents.filter { $0.category == .growth && $0.weightLbs != nil }
                .sorted { $0.timestamp < $1.timestamp }

            if weightEvents.isEmpty {
                let entry = ConversationEntry(
                    type: .queryResponse,
                    text: "No weight data logged yet. Try saying \"weight 10lb\" to start tracking.",
                    babyID: baby.id,
                    queryTopicRaw: topic.rawValue
                )
                context.insert(entry)
            } else {
                let chartPairs = weightEvents.suffix(7).map { event in
                    let label = formatter.string(from: event.timestamp)
                    return "\(label):\(event.weightLbs ?? 0)"
                }
                let chartData = chartPairs.joined(separator: "|")

                let latest = weightEvents.last!
                let latestW = String(format: "%.1f", latest.weightLbs ?? 0)
                var text = "\(baby.name) is at \(latestW) lbs."

                let whoResult = WHOGrowthData.percentile(weightLbs: latest.weightLbs ?? 0, ageMonths: baby.ageInMonths, gender: baby.gender)
                text += " That's around the \(ordinal(whoResult.percentile)) percentile (\(whoResult.description)) for \(baby.gender == .boy ? "boys" : "girls") this age."

                if weightEvents.count >= 2 {
                    let prev = weightEvents[weightEvents.count - 2]
                    let diff = (latest.weightLbs ?? 0) - (prev.weightLbs ?? 0)
                    let direction = diff > 0 ? "up" : diff < 0 ? "down" : "steady"
                    if diff != 0 {
                        text += " That's \(direction) \(String(format: "%.1f", abs(diff))) lbs since the last measurement."
                    }
                }

                if weightEvents.count == 1 {
                    text += " Log more weights over time to see the trend."
                } else {
                    text += " Looking good — keep tracking!"
                }

                let entry = ConversationEntry(
                    type: .queryResponse,
                    text: text,
                    babyID: baby.id,
                    chartData: chartData,
                    queryTopicRaw: topic.rawValue
                )
                context.insert(entry)
            }

        case .feeding:
            let feeds = allEvents.filter { $0.category == .feeding }
            let last7 = feeds.filter { $0.timestamp >= calendar.date(byAdding: .day, value: -7, to: Date())! }

            if feeds.isEmpty {
                let entry = ConversationEntry(type: .queryResponse, text: "No feeds logged yet.", babyID: baby.id, queryTopicRaw: topic.rawValue)
                context.insert(entry)
            } else {
                var chartPairs: [String] = []
                for offset in (0..<7).reversed() {
                    guard let day = calendar.date(byAdding: .day, value: -offset, to: Date()) else { continue }
                    let start = calendar.startOfDay(for: day)
                    let end = calendar.date(byAdding: .day, value: 1, to: start)!
                    let count = last7.filter { $0.timestamp >= start && $0.timestamp < end }.count
                    chartPairs.append("\(formatter.string(from: start)):\(count)")
                }
                let chartData = chartPairs.joined(separator: "|")

                let todayFeeds = last7.filter { calendar.isDateInToday($0.timestamp) }.count
                let avgDaily = last7.isEmpty ? 0 : last7.count / max(1, Set(last7.map { calendar.startOfDay(for: $0.timestamp) }).count)
                let totalOz = last7.compactMap(\.amountOz).reduce(0, +)

                var text = "\(baby.name) has had \(todayFeeds) feed\(todayFeeds == 1 ? "" : "s") today."
                text += " Averaging \(avgDaily) feeds per day this week."
                if totalOz > 0 {
                    text += " Total intake: \(String(format: "%.0f", totalOz))oz over 7 days."
                }

                let entry = ConversationEntry(type: .queryResponse, text: text, babyID: baby.id, chartData: chartData, queryTopicRaw: topic.rawValue)
                context.insert(entry)
            }

        case .sleep:
            let sleeps = allEvents.filter { $0.category == .sleep }
            let last7 = sleeps.filter { $0.timestamp >= calendar.date(byAdding: .day, value: -7, to: Date())! }

            if sleeps.isEmpty {
                let entry = ConversationEntry(type: .queryResponse, text: "No sleep data logged yet.", babyID: baby.id, queryTopicRaw: topic.rawValue)
                context.insert(entry)
            } else {
                var chartPairs: [String] = []
                for offset in (0..<7).reversed() {
                    guard let day = calendar.date(byAdding: .day, value: -offset, to: Date()) else { continue }
                    let start = calendar.startOfDay(for: day)
                    let end = calendar.date(byAdding: .day, value: 1, to: start)!
                    let mins = last7.filter { $0.timestamp >= start && $0.timestamp < end }.compactMap(\.durationMinutes).reduce(0, +)
                    chartPairs.append("\(formatter.string(from: start)):\(mins)")
                }
                let chartData = chartPairs.joined(separator: "|")

                let totalMins = last7.compactMap(\.durationMinutes).reduce(0, +)
                let days = max(1, Set(last7.map { calendar.startOfDay(for: $0.timestamp) }).count)
                let avgHrs = (totalMins / Double(days)) / 60

                var text = String(format: "\(baby.name) is averaging %.1f hours of sleep per day this week.", avgHrs)
                let todayMins = last7.filter { calendar.isDateInToday($0.timestamp) }.compactMap(\.durationMinutes).reduce(0, +)
                if todayMins > 0 {
                    text += String(format: " Today so far: %.1f hours.", todayMins / 60)
                }

                let entry = ConversationEntry(type: .queryResponse, text: text, babyID: baby.id, chartData: chartData, queryTopicRaw: topic.rawValue)
                context.insert(entry)
            }

        case .diaper:
            let diapers = allEvents.filter { $0.category == .diaper }
            let last7 = diapers.filter { $0.timestamp >= calendar.date(byAdding: .day, value: -7, to: Date())! }

            if diapers.isEmpty {
                let entry = ConversationEntry(type: .queryResponse, text: "No diaper changes logged yet.", babyID: baby.id, queryTopicRaw: topic.rawValue)
                context.insert(entry)
            } else {
                var chartPairs: [String] = []
                for offset in (0..<7).reversed() {
                    guard let day = calendar.date(byAdding: .day, value: -offset, to: Date()) else { continue }
                    let start = calendar.startOfDay(for: day)
                    let end = calendar.date(byAdding: .day, value: 1, to: start)!
                    let count = last7.filter { $0.timestamp >= start && $0.timestamp < end }.count
                    chartPairs.append("\(formatter.string(from: start)):\(count)")
                }
                let chartData = chartPairs.joined(separator: "|")

                let todayCount = last7.filter { calendar.isDateInToday($0.timestamp) }.count
                let wet = last7.filter { $0.diaperType == .wet }.count
                let dirty = last7.filter { $0.diaperType == .dirty }.count
                let both = last7.filter { $0.diaperType == .both }.count

                var text = "\(todayCount) diaper\(todayCount == 1 ? "" : "s") today."
                text += " This week: \(wet) wet, \(dirty) dirty, \(both) both."

                let entry = ConversationEntry(type: .queryResponse, text: text, babyID: baby.id, chartData: chartData, queryTopicRaw: topic.rawValue)
                context.insert(entry)
            }

        case .growth:
            let growthEvents = allEvents.filter { $0.category == .growth }
                .sorted { $0.timestamp < $1.timestamp }

            if growthEvents.isEmpty {
                let entry = ConversationEntry(type: .queryResponse, text: "No growth data logged yet. Try \"weight 10lb\" or \"height 24in\".", babyID: baby.id, queryTopicRaw: topic.rawValue)
                context.insert(entry)
            } else {
                var text = "Growth log for \(baby.name):"
                if let latestW = growthEvents.last(where: { $0.weightLbs != nil }) {
                    text += " Weight: \(String(format: "%.1f", latestW.weightLbs!)) lbs."
                    let whoResult = WHOGrowthData.percentile(weightLbs: latestW.weightLbs!, ageMonths: baby.ageInMonths, gender: baby.gender)
                    text += " ~\(ordinal(whoResult.percentile)) percentile for \(baby.gender == .boy ? "boys" : "girls")."
                }
                if let latestH = growthEvents.last(where: { $0.heightInches != nil }) {
                    text += " Height: \(String(format: "%.1f", latestH.heightInches!)) in."
                }

                let weightData = growthEvents.filter { $0.weightLbs != nil }.suffix(7)
                let chartPairs = weightData.map { event in
                    "\(formatter.string(from: event.timestamp)):\(event.weightLbs ?? 0)"
                }
                let chartData = chartPairs.joined(separator: "|")

                let entry = ConversationEntry(type: .queryResponse, text: text, babyID: baby.id, chartData: chartData.isEmpty ? nil : chartData, queryTopicRaw: topic.rawValue)
                context.insert(entry)
            }

        case .health:
            let healthEvents = allEvents.filter { $0.category == .health }
                .sorted { $0.timestamp > $1.timestamp }

            if healthEvents.isEmpty {
                let entry = ConversationEntry(type: .queryResponse, text: "No health entries logged. That's great!", babyID: baby.id, queryTopicRaw: topic.rawValue)
                context.insert(entry)
            } else {
                var text = "Recent health log:"
                for event in healthEvents.prefix(3) {
                    text += " \(event.summaryText) (\(event.timestamp.formatted(.dateTime.month().day())))."
                }
                let entry = ConversationEntry(type: .queryResponse, text: text, babyID: baby.id, queryTopicRaw: topic.rawValue)
                context.insert(entry)
            }

        case .general:
            let todayStart = calendar.startOfDay(for: Date())
            let todayEvents = allEvents.filter { $0.timestamp >= todayStart }
            let feeds = todayEvents.filter { $0.category == .feeding }.count
            let diapers = todayEvents.filter { $0.category == .diaper }.count
            let sleepMins = todayEvents.filter { $0.category == .sleep }.compactMap(\.durationMinutes).reduce(0, +)

            var text = "Here's \(baby.name)'s day so far: \(feeds) feed\(feeds == 1 ? "" : "s"), \(diapers) diaper\(diapers == 1 ? "" : "s")"
            if sleepMins > 0 {
                text += String(format: ", %.1f hours of sleep", sleepMins / 60)
            }
            text += ". Looking steady!"

            let entry = ConversationEntry(type: .queryResponse, text: text, babyID: baby.id, queryTopicRaw: topic.rawValue)
            context.insert(entry)
        }
    }

    private func handleMedicationQuery(_ parsed: ParsedEvent, baby: Baby, allEvents: [BabyEvent], context: ModelContext) {
        let medName = parsed.queryMedicationName ?? "medication"
        let medEvents = allEvents.filter {
            $0.category == .health && $0.medicationName?.lowercased() == medName.lowercased()
        }.sorted { $0.timestamp > $1.timestamp }

        if medEvents.isEmpty {
            let entry = ConversationEntry(
                type: .queryResponse,
                text: "No \(medName) doses logged yet.",
                babyID: baby.id,
                queryTopicRaw: "health"
            )
            context.insert(entry)
        } else {
            let last = medEvents[0]
            let timeAgo = RelativeDateTimeFormatter()
            timeAgo.unitsStyle = .full
            let relativeTime = timeAgo.localizedString(for: last.timestamp, relativeTo: Date())

            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "h:mm a"
            let exactTime = timeFormatter.string(from: last.timestamp)

            let dayFormatter = DateFormatter()
            dayFormatter.dateStyle = .medium
            dayFormatter.timeStyle = .none
            let dayStr = Calendar.current.isDateInToday(last.timestamp) ? "today" :
                         Calendar.current.isDateInYesterday(last.timestamp) ? "yesterday" :
                         dayFormatter.string(from: last.timestamp)

            var text = "\(baby.name) had \(medName)"
            if let dose = last.medicationDose {
                text += " (\(dose))"
            }
            text += " \(dayStr) at \(exactTime) (\(relativeTime))."

            if medEvents.count > 1 {
                text += " That's \(medEvents.count) dose\(medEvents.count == 1 ? "" : "s") total."
            }

            let entry = ConversationEntry(
                type: .queryResponse,
                text: text,
                babyID: baby.id,
                queryTopicRaw: "health"
            )
            context.insert(entry)
        }
    }

    private func handleLastEventQuery(_ parsed: ParsedEvent, baby: Baby, allEvents: [BabyEvent], context: ModelContext) {
        guard let category = parsed.queryCategory else {
            let entry = ConversationEntry(type: .queryResponse, text: "I'm not sure what you're looking for.", babyID: baby.id, queryTopicRaw: "general")
            context.insert(entry)
            return
        }

        let matching = allEvents.filter { $0.category == category }.sorted { $0.timestamp > $1.timestamp }

        if matching.isEmpty {
            let label = category.rawValue
            let entry = ConversationEntry(
                type: .queryResponse,
                text: "No \(label) events logged yet.",
                babyID: baby.id,
                queryTopicRaw: label
            )
            context.insert(entry)
        } else {
            let last = matching[0]
            let timeAgo = RelativeDateTimeFormatter()
            timeAgo.unitsStyle = .full
            let relativeTime = timeAgo.localizedString(for: last.timestamp, relativeTo: Date())

            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "h:mm a"
            let exactTime = timeFormatter.string(from: last.timestamp)

            let dayStr: String
            if Calendar.current.isDateInToday(last.timestamp) {
                dayStr = "today"
            } else if Calendar.current.isDateInYesterday(last.timestamp) {
                dayStr = "yesterday"
            } else {
                let dayFormatter = DateFormatter()
                dayFormatter.dateStyle = .medium
                dayFormatter.timeStyle = .none
                dayStr = dayFormatter.string(from: last.timestamp)
            }

            var text = "Last \(category.rawValue): \(last.summaryText) — \(dayStr) at \(exactTime) (\(relativeTime))."

            if matching.count >= 2 {
                let prev = matching[1]
                let gap = last.timestamp.timeIntervalSince(prev.timestamp)
                let gapHours = Int(gap / 3600)
                let gapMins = Int((gap.truncatingRemainder(dividingBy: 3600)) / 60)
                if gapHours > 0 {
                    text += " Previous one was \(gapHours)h \(gapMins)m before that."
                } else {
                    text += " Previous one was \(gapMins)m before that."
                }
            }

            let topicRaw: String
            switch category {
            case .feeding: topicRaw = "feeding"
            case .sleep: topicRaw = "sleep"
            case .diaper: topicRaw = "diaper"
            default: topicRaw = "general"
            }

            let entry = ConversationEntry(
                type: .queryResponse,
                text: text,
                babyID: baby.id,
                queryTopicRaw: topicRaw
            )
            context.insert(entry)
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

    private func collapseRecentIfNeeded(baby: Baby, event: BabyEvent, context: ModelContext) {
        let threshold: TimeInterval = 30 * 60
        let cutoff = Date().addingTimeInterval(-threshold)

        let entryDesc = FetchDescriptor<ConversationEntry>(
            predicate: #Predicate<ConversationEntry> { $0.timestamp >= cutoff },
            sortBy: [SortDescriptor(\ConversationEntry.timestamp, order: .reverse)]
        )
        guard let recentEntries = try? context.fetch(entryDesc) else { return }

        let confirmations = recentEntries.filter {
            $0.type == .confirmation && $0.babyID == baby.id
        }
        guard confirmations.count >= 4 else { return }

        let hasGroup = recentEntries.contains { $0.type == .collapsedGroup && $0.babyID == baby.id }
        guard !hasGroup else { return }

        let toCollapse = Array(confirmations.dropFirst())
        guard toCollapse.count >= 3 else { return }

        let eventIDs = toCollapse.compactMap { $0.eventID?.uuidString }
        let grouped = ConversationEntry(
            type: .collapsedGroup,
            text: "\(toCollapse.count) earlier entries",
            babyID: baby.id
        )
        grouped.groupedEventIDs = eventIDs.joined(separator: ",")
        grouped.timestamp = toCollapse.last?.timestamp ?? Date()
        context.insert(grouped)

        for entry in toCollapse {
            context.delete(entry)
        }
    }

    func updateWidgetData(baby: Baby, context: ModelContext) {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())
        let descriptor = FetchDescriptor<BabyEvent>(
            predicate: #Predicate { $0.timestamp >= todayStart },
            sortBy: [SortDescriptor(\BabyEvent.timestamp, order: .reverse)]
        )
        let todayEvents = ((try? context.fetch(descriptor)) ?? []).filter { $0.baby?.id == baby.id }

        let feeds = todayEvents.filter { $0.category == .feeding }
        let sleeps = todayEvents.filter { $0.category == .sleep }
        let diapers = todayEvents.filter { $0.category == .diaper }

        let lastFeedText: String
        if let lastFeed = feeds.first {
            let interval = Date().timeIntervalSince(lastFeed.timestamp)
            let minutes = Int(interval / 60)
            if minutes < 1 {
                lastFeedText = "Last feed just now"
            } else if minutes < 60 {
                lastFeedText = "Last feed \(minutes)m ago"
            } else {
                let hours = minutes / 60
                lastFeedText = "Last feed \(hours)h ago"
            }
        } else {
            lastFeedText = "No feeds today yet"
        }

        let sleepHours = sleeps.compactMap(\.durationMinutes).reduce(0, +) / 60
        let statusText = "\(feeds.count) feeds, \(String(format: "%.1f", sleepHours))h sleep, \(diapers.count) diapers today"

        let defaults = UserDefaults.standard
        defaults.set(lastFeedText, forKey: "widgetLastFeedText")
        defaults.set(statusText, forKey: "widgetStatusText")
        defaults.set(feeds.count, forKey: "widgetFeedCount")
        defaults.set(sleepHours, forKey: "widgetSleepHours")
        defaults.set(diapers.count, forKey: "widgetDiaperCount")

        WidgetCenter.shared.reloadAllTimelines()
    }

    private func ordinal(_ n: Int) -> String {
        let suffix: String
        let ones = n % 10
        let tens = (n / 10) % 10
        if tens == 1 {
            suffix = "th"
        } else if ones == 1 {
            suffix = "st"
        } else if ones == 2 {
            suffix = "nd"
        } else if ones == 3 {
            suffix = "rd"
        } else {
            suffix = "th"
        }
        return "\(n)\(suffix)"
    }
}
