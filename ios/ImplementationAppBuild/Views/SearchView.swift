import SwiftUI
import SwiftData

struct SearchView: View {
    let baby: Baby
    let events: [BabyEvent]
    var autoFocus: Bool = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var searchText: String = ""
    @State private var selectedCategory: EventCategory?
    @State private var answerText: String?
    @State private var answerTopicRaw: String?
    @FocusState private var isSearchFocused: Bool

    private var filteredEvents: [BabyEvent] {
        var result = events
        if let cat = selectedCategory {
            result = result.filter { $0.category == cat }
        }
        if !searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            let query = searchText.lowercased()
            result = result.filter {
                $0.summaryText.localizedStandardContains(query) ||
                ($0.notes?.localizedStandardContains(query) ?? false) ||
                ($0.medicationName?.localizedStandardContains(query) ?? false) ||
                ($0.milestoneDescription?.localizedStandardContains(query) ?? false) ||
                $0.category.rawValue.localizedStandardContains(query)
            }
        }
        return result
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                categoryFilters

                if let answerText, let answerTopicRaw {
                    answerCard(text: answerText, topicRaw: answerTopicRaw)
                        .padding(.horizontal, HenriiSpacing.horizontalMargin(for: sizeClass))
                        .padding(.top, HenriiSpacing.md)
                        .transition(.asymmetric(insertion: .move(edge: .top).combined(with: .opacity), removal: .opacity))
                }

                if filteredEvents.isEmpty && answerText == nil {
                    emptyState
                } else {
                    List {
                        ForEach(filteredEvents) { event in
                            searchResultRow(event)
                                .listRowBackground(HenriiColors.canvasElevated)
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(HenriiColors.canvasPrimary)
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Ask a question or search events...")
            .searchFocused($isSearchFocused)
            .onSubmit(of: .search) {
                handleNLQuery()
            }
            .onChange(of: searchText) { _, newValue in
                if newValue.isEmpty {
                    withAnimation(.spring(duration: 0.25)) {
                        answerText = nil
                        answerTopicRaw = nil
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(HenriiColors.accentPrimary)
                }
            }
            .onAppear {
                if autoFocus {
                    isSearchFocused = true
                }
            }
        }
    }

    private func handleNLQuery() {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        guard let parsed = InputParser.parse(trimmed), parsed.isQuery else {
            withAnimation(.spring(duration: 0.25)) {
                answerText = nil
                answerTopicRaw = nil
            }
            return
        }

        let topic = parsed.queryTopic ?? .general
        let calendar = Calendar.current

        switch topic {
        case .medication:
            let medName = parsed.queryMedicationName ?? "medication"
            let medEvents = events.filter {
                $0.category == .health && $0.medicationName?.lowercased() == medName.lowercased()
            }.sorted { $0.timestamp > $1.timestamp }

            if medEvents.isEmpty {
                setAnswer("No \(medName) doses found.", topic: "health")
            } else {
                let last = medEvents[0]
                let relTime = formatRelativeTime(last.timestamp)
                var text = "\(baby.name) had \(medName)"
                if let dose = last.medicationDose { text += " (\(dose))" }
                text += " \(relTime)."
                if medEvents.count > 1 {
                    text += " \(medEvents.count) doses total."
                }
                setAnswer(text, topic: "health")
                selectedCategory = .health
            }

        case .lastEvent:
            guard let cat = parsed.queryCategory else { return }
            let matching = events.filter { $0.category == cat }.sorted { $0.timestamp > $1.timestamp }

            if matching.isEmpty {
                setAnswer("No \(cat.rawValue) events found.", topic: cat.rawValue)
            } else {
                let last = matching[0]
                let relTime = formatRelativeTime(last.timestamp)
                var text = "Last \(cat.rawValue): \(last.summaryText) \u{2014} \(relTime)."
                if matching.count >= 2 {
                    let gap = last.timestamp.timeIntervalSince(matching[1].timestamp)
                    let gapH = Int(gap / 3600)
                    let gapM = Int((gap.truncatingRemainder(dividingBy: 3600)) / 60)
                    text += gapH > 0 ? " Previous was \(gapH)h \(gapM)m before." : " Previous was \(gapM)m before."
                }
                setAnswer(text, topic: cat.rawValue)
                selectedCategory = cat
            }

        case .feeding:
            let feeds = events.filter { $0.category == .feeding }
            let todayFeeds = feeds.filter { calendar.isDateInToday($0.timestamp) }.count
            let totalOz = feeds.filter { $0.timestamp >= calendar.date(byAdding: .day, value: -7, to: Date())! }.compactMap(\.amountOz).reduce(0, +)
            var text = "\(todayFeeds) feed\(todayFeeds == 1 ? "" : "s") today."
            if totalOz > 0 { text += " \(String(format: "%.0f", totalOz))oz total this week." }
            setAnswer(text, topic: "feeding")
            selectedCategory = .feeding

        case .sleep:
            let sleeps = events.filter { $0.category == .sleep }
            let todayMins = sleeps.filter { calendar.isDateInToday($0.timestamp) }.compactMap(\.durationMinutes).reduce(0, +)
            let text = todayMins > 0 ? String(format: "%.1f hours of sleep today so far.", todayMins / 60) : "No sleep logged today yet."
            setAnswer(text, topic: "sleep")
            selectedCategory = .sleep

        case .diaper:
            let diapers = events.filter { $0.category == .diaper }
            let todayCount = diapers.filter { calendar.isDateInToday($0.timestamp) }.count
            setAnswer("\(todayCount) diaper\(todayCount == 1 ? "" : "s") today.", topic: "diaper")
            selectedCategory = .diaper

        case .weight, .growth:
            let growthEvents = events.filter { $0.category == .growth }.sorted { $0.timestamp < $1.timestamp }
            if let latest = growthEvents.last(where: { $0.weightLbs != nil }) {
                let w = String(format: "%.1f", latest.weightLbs!)
                let who = WHOGrowthData.percentile(weightLbs: latest.weightLbs!, ageMonths: baby.ageInMonths, gender: baby.gender)
                setAnswer("\(baby.name) is at \(w) lbs (~\(who.percentile)th percentile).", topic: "growth")
            } else {
                setAnswer("No weight data logged yet.", topic: "growth")
            }
            selectedCategory = .growth

        case .health:
            let healthEvents = events.filter { $0.category == .health }.sorted { $0.timestamp > $1.timestamp }
            if healthEvents.isEmpty {
                setAnswer("No health entries. That's great!", topic: "health")
            } else {
                var text = "Recent: "
                text += healthEvents.prefix(3).map { "\($0.summaryText) (\($0.timestamp.formatted(.dateTime.month().day())))" }.joined(separator: ". ")
                setAnswer(text, topic: "health")
            }
            selectedCategory = .health

        case .general:
            let todayEvents = events.filter { calendar.isDateInToday($0.timestamp) }
            let feeds = todayEvents.filter { $0.category == .feeding }.count
            let diapers = todayEvents.filter { $0.category == .diaper }.count
            let sleepMins = todayEvents.filter { $0.category == .sleep }.compactMap(\.durationMinutes).reduce(0, +)
            var text = "\(feeds) feed\(feeds == 1 ? "" : "s"), \(diapers) diaper\(diapers == 1 ? "" : "s")"
            if sleepMins > 0 { text += String(format: ", %.1fh sleep", sleepMins / 60) }
            text += " today."
            setAnswer(text, topic: "general")
        }
    }

    private func setAnswer(_ text: String, topic: String) {
        withAnimation(.spring(duration: 0.3)) {
            answerText = text
            answerTopicRaw = topic
        }
    }

    private func formatRelativeTime(_ date: Date) -> String {
        let calendar = Calendar.current
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        let exactTime = timeFormatter.string(from: date)

        if calendar.isDateInToday(date) {
            return "today at \(exactTime)"
        } else if calendar.isDateInYesterday(date) {
            return "yesterday at \(exactTime)"
        } else {
            let dayFormatter = DateFormatter()
            dayFormatter.dateFormat = "MMM d"
            return "\(dayFormatter.string(from: date)) at \(exactTime)"
        }
    }

    private func answerCard(text: String, topicRaw: String) -> some View {
        let color = colorForTopic(topicRaw)
        let icon = iconForTopic(topicRaw)

        return HStack(spacing: HenriiSpacing.md) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 36, height: 36)
                .background(color.opacity(0.12))
                .clipShape(Circle())

            Text(text)
                .font(.henriiCallout)
                .foregroundStyle(HenriiColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(HenriiSpacing.lg)
        .background(color.opacity(0.06))
        .clipShape(.rect(cornerRadius: HenriiRadius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: HenriiRadius.medium)
                .strokeBorder(color.opacity(0.15), lineWidth: 1)
        )
    }

    private var categoryFilters: some View {
        ScrollView(.horizontal) {
            HStack(spacing: HenriiSpacing.sm) {
                filterChip(label: "All", category: nil)
                filterChip(label: "Feeding", category: .feeding)
                filterChip(label: "Sleep", category: .sleep)
                filterChip(label: "Diapers", category: .diaper)
                filterChip(label: "Health", category: .health)
                filterChip(label: "Growth", category: .growth)
                filterChip(label: "Milestones", category: .milestone)
            }
            .padding(.vertical, HenriiSpacing.sm)
        }
        .contentMargins(.horizontal, HenriiSpacing.margin)
        .scrollIndicators(.hidden)
    }

    private func filterChip(label: String, category: EventCategory?) -> some View {
        Button {
            withAnimation(.spring(duration: 0.2)) {
                selectedCategory = category
            }
        } label: {
            Text(label)
                .font(.henriiCallout)
                .foregroundStyle(selectedCategory == category ? .white : HenriiColors.textPrimary)
                .padding(.horizontal, HenriiSpacing.md)
                .padding(.vertical, HenriiSpacing.sm)
                .background(selectedCategory == category ? HenriiColors.accentPrimary : HenriiColors.canvasElevated)
                .clipShape(Capsule())
        }
        .sensoryFeedback(.selection, trigger: selectedCategory)
    }

    private func searchResultRow(_ event: BabyEvent) -> some View {
        HStack(spacing: HenriiSpacing.md) {
            Circle()
                .fill(Color(event.categoryColor).opacity(0.15))
                .frame(width: 36, height: 36)
                .overlay {
                    Image(systemName: event.icon)
                        .font(.callout)
                        .foregroundStyle(Color(event.categoryColor))
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(event.summaryText)
                    .font(.henriiCallout)
                    .foregroundStyle(HenriiColors.textPrimary)

                Text(event.timestamp, format: .dateTime.month(.abbreviated).day().hour().minute())
                    .font(.henriiCaption)
                    .foregroundStyle(HenriiColors.textTertiary)
            }

            Spacer()
        }
    }

    private var emptyState: some View {
        VStack(spacing: HenriiSpacing.lg) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundStyle(HenriiColors.textTertiary)
            Text(searchText.isEmpty ? "Search or ask a question" : "No results found")
                .font(.henriiCallout)
                .foregroundStyle(HenriiColors.textSecondary)
            Text(searchText.isEmpty ? "Try \"when was the last feed?\" or \"Tylenol\"" : "Try a different search term or ask a question")
                .font(.henriiCaption)
                .foregroundStyle(HenriiColors.textTertiary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding(.horizontal, HenriiSpacing.lg)
    }

    private func colorForTopic(_ topic: String) -> Color {
        switch topic {
        case "weight", "growth": return HenriiColors.dataGrowth
        case "feeding": return HenriiColors.dataFeeding
        case "sleep": return HenriiColors.dataSleep
        case "diaper": return HenriiColors.dataDiaper
        case "health": return HenriiColors.semanticAlert
        default: return HenriiColors.accentPrimary
        }
    }

    private func iconForTopic(_ topic: String) -> String {
        switch topic {
        case "weight", "growth": return "chart.line.uptrend.xyaxis"
        case "feeding": return "drop.fill"
        case "sleep": return "moon.fill"
        case "diaper": return "leaf.fill"
        case "health": return "heart.text.clipboard.fill"
        default: return "sparkle"
        }
    }
}
