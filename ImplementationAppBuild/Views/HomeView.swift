import SwiftUI
import SwiftData

struct HomeView: View {
    let baby: Baby
    let babies: [Baby]
    let onShowToday: () -> Void
    let onShowInsights: () -> Void
    let onShowProfile: () -> Void
    let onSwitchBaby: (Baby) -> Void
    let dashboardTransitionNamespace: Namespace.ID
    @Environment(\.modelContext) private var modelContext
    @Environment(\.henriiReduceMotion) private var reduceMotion
    @State private var conversationVM = ConversationViewModel()
    @State private var timerVM = TimerViewModel()
    @State private var handoffService = HandoffService()
    @State private var agingOutService = AgingOutService.shared
    @State private var showSearch: Bool = false
    @State private var searchAutoFocus: Bool = false
    @State private var showGrowthSheet: Bool = false
    @State private var showCustomBottleAlert: Bool = false
    @State private var customBottleText: String = ""
    @State private var selectedBabyIDs: Set<UUID> = []
    @State private var showCalendarStrip: Bool = false
    @State private var filterDate: Date? = nil
    @State private var milestoneEventToEdit: BabyEvent?
    @State private var searchPullProgress: CGFloat = 0
    @GestureState private var pinchScale: CGFloat = 1.0
    @FocusState private var composerFocused: Bool
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Query(sort: \ConversationEntry.timestamp, order: .reverse) private var allEntries: [ConversationEntry]
    @Query(sort: \BabyEvent.timestamp, order: .reverse) private var allEvents: [BabyEvent]

    private var entries: [ConversationEntry] {
        var base = allEntries.filter { $0.babyID == nil || $0.babyID == baby.id }

        if let filterDate {
            let calendar = Calendar.current
            let start = calendar.startOfDay(for: filterDate)
            let end = calendar.date(byAdding: .day, value: 1, to: start)!
            base = base.filter { $0.timestamp >= start && $0.timestamp < end }
        }

        base = base.filter { !($0.type == .medicalFlag && $0.isDismissed) }

        return base.reversed()
    }

    private var babyEvents: [BabyEvent] {
        allEvents.filter { $0.baby?.id == baby.id }
    }

    private var hasMultipleBabies: Bool {
        babies.count > 1
    }

    private var journalFilteredEntries: [ConversationEntry] {
        guard agingOutService.milestoneJournalMode else { return entries }
        return entries.filter { entry in
            switch entry.type {
            case .userMessage, .daySeparator, .system, .celebration, .medicalFlag, .handoffSummary, .dailySummary:
                return true
            case .confirmation:
                guard let event = eventFor(entry) else { return true }
                return event.category == .milestone || event.category == .growth || event.category == .health
            case .insight, .nudge, .collapsedGroup, .queryResponse:
                return true
            }
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            HenriiColors.canvasPrimary
                .ignoresSafeArea()

            VStack(spacing: 0) {
                StatusHeaderView(
                    baby: baby,
                    babies: babies,
                    events: babyEvents,
                    onTapStatus: onShowToday,
                    onTapInsights: onShowInsights,
                    onTapAvatar: onShowProfile,
                    onTapSearch: { showSearch = true },
                    onSwitchBaby: onSwitchBaby,
                    isOffline: !NetworkMonitor.shared.isConnected
                )

                if showCalendarStrip {
                    CalendarStripView { date in
                        let calendar = Calendar.current
                        if calendar.isDateInToday(date) {
                            filterDate = nil
                        } else {
                            filterDate = date
                        }
                    }
                    .padding(.vertical, HenriiSpacing.xs)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                ScrollViewReader { proxy in
                    ScrollView {
                        if searchPullProgress > 0 {
                            searchPullIndicator
                                .padding(.top, HenriiSpacing.sm)
                                .padding(.bottom, HenriiSpacing.xs)
                        }
                        LazyVStack(spacing: HenriiSpacing.md) {
                            if agingOutService.milestoneJournalMode {
                                milestoneJournalBanner
                            }

                            if entries.isEmpty {
                                emptyConversationState
                            }

                            ForEach(Array(journalFilteredEntries), id: \.id) { entry in
                                ConversationBubbleView(
                                    entry: entry,
                                    event: eventFor(entry),
                                    onDelete: {
                                        withAnimation {
                                            if let event = eventFor(entry) {
                                                conversationVM.deleteEvent(event, context: modelContext)
                                            }
                                            modelContext.delete(entry)
                                        }
                                    },
                                    onDismissMedical: {
                                        withAnimation(reduceMotion ? .easeInOut(duration: 0.15) : .spring(duration: 0.3)) {
                                            conversationVM.dismissMedicalFlag(entry)
                                        }
                                    },
                                    onEditMilestone: { event in
                                        milestoneEventToEdit = event
                                    }
                                )
                                .id(entry.id)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .bottom).combined(with: .opacity),
                                    removal: .opacity
                                ))
                            }
                        }
                        .padding(.horizontal, HenriiSpacing.horizontalMargin(for: sizeClass))
                        .padding(.top, HenriiSpacing.md)
                        .padding(.bottom, timerVM.isRunning ? 220 : 160)
                    }
                    .accessibilityRotor("Conversation Entries") {
                        ForEach(entries, id: \.id) { entry in
                            AccessibilityRotorEntry(entry.text, id: entry.id)
                        }
                    }
                    .accessibilityRotor("Edit Entry") {
                        ForEach(entries.filter { $0.type == .confirmation }, id: \.id) { entry in
                            AccessibilityRotorEntry("Edit \(entry.text)", id: entry.id) {
                                milestoneEventToEdit = eventFor(entry)
                            }
                        }
                    }
                    .accessibilityRotor("Delete Entry") {
                        ForEach(entries.filter { $0.type == .confirmation }, id: \.id) { entry in
                            AccessibilityRotorEntry("Delete \(entry.text)", id: entry.id) {
                                withAnimation {
                                    if let event = eventFor(entry) {
                                        conversationVM.deleteEvent(event, context: modelContext)
                                    }
                                    modelContext.delete(entry)
                                }
                            }
                        }
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .onChange(of: entries.count) { _, _ in
                        scrollToBottom(proxy)
                    }
                    .onAppear {
                        scrollToBottom(proxy)
                        if selectedBabyIDs.isEmpty {
                            selectedBabyIDs = [baby.id]
                        }
                        scheduleDailySummaryIfNeeded()
                        DailyIntelligenceService.shared.maybeInsertMorningBriefing(baby: baby, context: modelContext)
                        handoffService.checkForHandoff(baby: baby, context: modelContext)
                        agingOutService.evaluateUsage(baby: baby, context: modelContext)
                        processPendingIntentActions()
                    }
                }
            }
            .scaleEffect(pinchScale > 1.0 ? min(pinchScale, 1.15) : 1.0)
            .opacity(pinchScale > 1.0 ? max(1.0 - (pinchScale - 1.0) * CGFloat(3), 0.5) : 1.0)
            .matchedGeometryEffect(id: "home.timeline.surface", in: dashboardTransitionNamespace, isSource: true)

            VStack(spacing: 0) {
                if timerVM.isRunning {
                    TimerCardView(timerVM: timerVM) { result in
                        handleTimerStop(result)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.horizontal, HenriiSpacing.horizontalMargin(for: sizeClass))
                }

                if hasMultipleBabies {
                    BabyToggleView(
                        babies: babies,
                        selectedBabyIDs: $selectedBabyIDs,
                        onSwitch: onSwitchBaby
                    )
                }

                ContextChipsView(baby: baby, events: babyEvents, reducedMode: agingOutService.reducedChipMode) { action in
                    handleChipAction(action)
                }

                ComposerView(
                    text: $conversationVM.composerText,
                    timerRunning: timerVM.isRunning,
                    isFocused: $composerFocused
                ) { text in
                    withAnimation(reduceMotion ? .easeInOut(duration: 0.15) : .spring(duration: 0.35, bounce: 0.2)) {
                        handleComposerInput(text)
                    }
                }
            }
            .background(
                LinearGradient(
                    stops: [
                        .init(color: HenriiColors.canvasPrimary.opacity(0), location: 0),
                        .init(color: HenriiColors.canvasPrimary, location: 0.15)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )

            if conversationVM.showUndoToast {
                UndoToastView {
                    withAnimation {
                        conversationVM.undoLastEvent(context: modelContext)
                    }
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .padding(.top, 60)
                .frame(maxHeight: .infinity, alignment: .top)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        withAnimation {
                            conversationVM.showUndoToast = false
                        }
                    }
                }
            }
        }
        .sensoryFeedback(.success, trigger: conversationVM.showUndoToast)
        .animation(reduceMotion ? .easeInOut(duration: 0.15) : .spring(duration: 0.35, bounce: 0.2), value: timerVM.isRunning)
        .animation(reduceMotion ? .easeInOut(duration: 0.15) : .spring(duration: 0.25), value: showCalendarStrip)
        .toolbar(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showCalendarStrip.toggle()
                } label: {
                    Image(systemName: showCalendarStrip ? "calendar.circle.fill" : "calendar.circle")
                        .font(.title3)
                        .foregroundStyle(HenriiColors.accentPrimary)
                }
            }
        }
        .gesture(pinchGesture)
        .simultaneousGesture(swipeLeftGesture)
        .simultaneousGesture(searchPullGesture)
        .sheet(isPresented: $showSearch) {
            SearchView(baby: baby, events: babyEvents, autoFocus: searchAutoFocus)
        }
        .onChange(of: showSearch) { _, isShowing in
            if !isShowing { searchAutoFocus = false }
        }
        .sheet(isPresented: $showGrowthSheet) {
            GrowthLogSheet(baby: baby, useMetric: SettingsManager.shared.useMetric)
        }
        .sheet(item: $milestoneEventToEdit) { event in
            MilestoneDetailSheet(event: event)
        }
        .background {
            Group {
                Button("") { showSearch = true; searchAutoFocus = true }
                    .keyboardShortcut("f", modifiers: .command)
                Button("") {
                    if !timerVM.isRunning {
                        timerVM.startTimer(category: .feeding, babyName: baby.name)
                    }
                }
                    .keyboardShortcut("t", modifiers: .command)
            }
            .frame(width: 0, height: 0)
            .opacity(0)
        }
        .alert("Custom Amount", isPresented: $showCustomBottleAlert) {
            TextField("Ounces", text: $customBottleText)
                .keyboardType(.decimalPad)
            Button("Log") {
                if let oz = Double(customBottleText), oz > 0 {
                    withAnimation(reduceMotion ? .easeInOut(duration: 0.15) : .spring(duration: 0.35, bounce: 0.2)) {
                        conversationVM.quickLog(category: .feeding, baby: baby, context: modelContext, feedingType: .bottle, amountOz: oz)
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Enter the amount in ounces")
        }
        .overlay {
            Group {
                Button { composerFocused = true } label: { EmptyView() }
                    .keyboardShortcut("n", modifiers: .command)
                Button {
                    if timerVM.isRunning {
                        if let result = timerVM.stopTimer() {
                            handleTimerStop(result)
                        }
                    } else {
                        timerVM.startTimer(category: .sleep, babyName: baby.name)
                    }
                } label: { EmptyView() }
                    .keyboardShortcut("t", modifiers: .command)
                Button {
                    searchAutoFocus = true
                    showSearch = true
                } label: { EmptyView() }
                    .keyboardShortcut("f", modifiers: .command)
            }
            .frame(width: 0, height: 0)
            .opacity(0)
        }
    }

    private var pinchGesture: some Gesture {
        MagnifyGesture()
            .updating($pinchScale) { value, state, _ in
                state = value.magnification
            }
            .onEnded { value in
                if value.magnification > 1.15 {
                    onShowToday()
                }
            }
    }

    private var swipeLeftGesture: some Gesture {
        DragGesture(minimumDistance: 60)
            .onEnded { value in
                if value.translation.width < -60 && abs(value.translation.height) < 80 {
                    onShowInsights()
                }
            }
    }

    private var searchPullGesture: some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { value in
                let startsInMidScreen = value.startLocation.y > 180 && value.startLocation.y < 460
                let verticalOnly = abs(value.translation.width) < 60
                guard startsInMidScreen, verticalOnly, value.translation.height > 0 else {
                    if searchPullProgress > 0 {
                        searchPullProgress = 0
                    }
                    return
                }
                searchPullProgress = min(value.translation.height / 110, 1)
            }
            .onEnded { value in
                defer {
                    withAnimation(.spring(duration: 0.25, bounce: 0.15)) {
                        searchPullProgress = 0
                    }
                }
                let startsInMidScreen = value.startLocation.y > 180 && value.startLocation.y < 460
                let verticalOnly = abs(value.translation.width) < 60
                guard startsInMidScreen, verticalOnly else { return }
                if value.translation.height > 110 {
                    searchAutoFocus = true
                    showSearch = true
                }
            }
    }

    private var searchPullIndicator: some View {
        HStack(spacing: HenriiSpacing.xs) {
            Image(systemName: "magnifyingglass")
                .font(.caption)
            Text(searchPullProgress >= 1 ? "Release to search" : "Pull down to search")
                .font(.henriiCaption)
        }
        .foregroundStyle(HenriiColors.textSecondary)
        .padding(.horizontal, HenriiSpacing.md)
        .padding(.vertical, HenriiSpacing.xs)
        .background(HenriiColors.canvasElevated)
        .clipShape(.capsule)
        .opacity(searchPullProgress)
        .scaleEffect(0.92 + (searchPullProgress * 0.08))
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        if let last = entries.last {
            withAnimation(reduceMotion ? .easeInOut(duration: 0.15) : .spring(duration: 0.3)) {
                proxy.scrollTo(last.id, anchor: .bottom)
            }
        }
    }

    private var milestoneJournalBanner: some View {
        VStack(alignment: .leading, spacing: HenriiSpacing.sm) {
            HStack(spacing: HenriiSpacing.sm) {
                Image(systemName: "star.circle.fill")
                    .font(.title3)
                    .foregroundStyle(HenriiColors.semanticCelebration)
                Text("Milestone Journal Mode")
                    .font(.henriiHeadline)
                    .foregroundStyle(HenriiColors.textPrimary)
            }
            Text("\(baby.name) is growing up! Focus on capturing milestones, firsts, and special moments.")
                .font(.henriiCallout)
                .foregroundStyle(HenriiColors.textSecondary)

            let milestoneCount = babyEvents.filter { $0.category == .milestone }.count
            HStack(spacing: HenriiSpacing.md) {
                Label("\(milestoneCount) milestones", systemImage: "star.fill")
                    .font(.henriiCaption)
                    .foregroundStyle(HenriiColors.semanticCelebration)
                Spacer()
                Button {
                    conversationVM.composerText = "milestone: "
                } label: {
                    Text("Log Milestone")
                        .font(.henriiCaption)
                        .foregroundStyle(.white)
                        .padding(.horizontal, HenriiSpacing.md)
                        .frame(height: 30)
                        .background(HenriiColors.semanticCelebration)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(HenriiSpacing.lg)
        .background(
            LinearGradient(
                colors: [HenriiColors.semanticCelebration.opacity(0.1), HenriiColors.semanticCelebration.opacity(0.03)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(.rect(cornerRadius: HenriiRadius.medium))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Milestone journal mode active. \(baby.name) has \(babyEvents.filter { $0.category == .milestone }.count) milestones logged.")
    }

    private var emptyConversationState: some View {
        VStack(spacing: HenriiSpacing.xl) {
            Spacer()
                .frame(height: 60)

            Image(systemName: "bubble.left.and.text.bubble.right")
                .font(.system(size: 56))
                .foregroundStyle(HenriiColors.accentPrimary.opacity(0.3))

            VStack(spacing: HenriiSpacing.sm) {
                Text("Hi there \u{1F44B}")
                    .font(.henriiTitle2)
                    .foregroundStyle(HenriiColors.textPrimary)

                Text("Tell me what's happening with \(baby.name) and I'll handle the rest. Try saying \"fed 4oz\" or \"diaper change\".")
                    .font(.henriiBody)
                    .foregroundStyle(HenriiColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()
                .frame(height: 20)
        }
        .padding(.horizontal, HenriiSpacing.lg)
    }

    private func eventFor(_ entry: ConversationEntry) -> BabyEvent? {
        guard let eventID = entry.eventID else { return nil }
        return allEvents.first { $0.id == eventID }
    }

    private func handleComposerInput(_ text: String) {
        let parsed = InputParser.parse(text)

        if selectedBabyIDs.count > 1 && hasMultipleBabies {
            let targetBabies = babies.filter { selectedBabyIDs.contains($0.id) }
            if let parsed, parsed.isMultiChild || targetBabies.count > 1 {
                for targetBaby in targetBabies {
                    processSingleBabyInput(text, parsed: parsed, baby: targetBaby)
                }
                return
            }
        }

        if let parsed, parsed.isMultiChild && hasMultipleBabies {
            for targetBaby in babies {
                processSingleBabyInput(text, parsed: parsed, baby: targetBaby)
            }
            return
        }

        processSingleBabyInput(text, parsed: parsed, baby: baby)
    }

    private func processSingleBabyInput(_ text: String, parsed: ParsedEvent?, baby: Baby) {
        if let parsed, parsed.isSleepEnd, timerVM.isRunning, timerVM.timerCategory == .sleep {
            let _ = timerVM.stopTimer()
            conversationVM.processInput(text, baby: baby, context: modelContext)
        } else if let parsed, parsed.isSleepStart {
            conversationVM.processInput(text, baby: baby, context: modelContext)
            if !timerVM.isRunning {
                timerVM.startTimer(category: .sleep, babyName: baby.name)
            }
        } else {
            conversationVM.processInput(text, baby: baby, context: modelContext)
        }
    }

    private func handleChipAction(_ action: ChipAction) {
        switch action {
        case .startFeed:
            timerVM.startTimer(category: .feeding, babyName: baby.name)
        case .startSleep:
            timerVM.startTimer(category: .sleep, babyName: baby.name)
        case .logDiaper(let type):
            withAnimation(reduceMotion ? .easeInOut(duration: 0.15) : .spring(duration: 0.35, bounce: 0.2)) {
                logForSelectedBabies { targetBaby in
                    conversationVM.quickLog(category: .diaper, baby: targetBaby, context: modelContext, diaperType: type)
                }
            }
        case .logBottle(let oz):
            withAnimation(reduceMotion ? .easeInOut(duration: 0.15) : .spring(duration: 0.35, bounce: 0.2)) {
                logForSelectedBabies { targetBaby in
                    conversationVM.quickLog(category: .feeding, baby: targetBaby, context: modelContext, feedingType: .bottle, amountOz: oz)
                }
            }
        case .logBottleCustom:
            customBottleText = ""
            showCustomBottleAlert = true
        case .logGrowth:
            showGrowthSheet = true
        case .logBurp:
            withAnimation(reduceMotion ? .easeInOut(duration: 0.15) : .spring(duration: 0.35, bounce: 0.2)) {
                logForSelectedBabies { targetBaby in
                    conversationVM.quickLog(category: .note, baby: targetBaby, context: modelContext, notes: "Burp")
                }
            }
        case .logSpitUp:
            withAnimation(reduceMotion ? .easeInOut(duration: 0.15) : .spring(duration: 0.35, bounce: 0.2)) {
                logForSelectedBabies { targetBaby in
                    conversationVM.quickLog(category: .note, baby: targetBaby, context: modelContext, notes: "Spit-up")
                }
            }
        }
    }

    private func logForSelectedBabies(_ action: (Baby) -> Void) {
        if selectedBabyIDs.count > 1 && hasMultipleBabies {
            for targetBaby in babies where selectedBabyIDs.contains(targetBaby.id) {
                action(targetBaby)
            }
        } else {
            action(baby)
        }
    }

    private func handleTimerStop(_ result: (category: EventCategory, duration: Double, side: FeedingType)?) {
        guard let result else { return }
        let event = BabyEvent(category: result.category)
        event.durationMinutes = result.duration
        event.baby = baby
        if result.category == .feeding {
            event.feedingType = result.side
        }
        modelContext.insert(event)
        let confirmation = ConversationEntry(
            type: .confirmation,
            text: event.summaryText,
            eventID: event.id,
            babyID: baby.id
        )
        modelContext.insert(confirmation)
    }

    private func scheduleDailySummaryIfNeeded() {
        let hour = Calendar.current.component(.hour, from: Date())
        guard hour >= SettingsManager.shared.dailySummaryHour else { return }
        conversationVM.generateDailySummary(baby: baby, context: modelContext)
    }

    private func processPendingIntentActions() {
        let defaults = UserDefaults(suiteName: "group.app.rork.henrii") ?? .standard
        guard let actions = defaults.array(forKey: "pendingIntentActions") as? [[String: String]], !actions.isEmpty else { return }
        defaults.removeObject(forKey: "pendingIntentActions")

        for action in actions {
            guard let type = action["type"] else { continue }
            switch type {
            case "feeding":
                let oz = action["amountOz"].flatMap { Double($0) }
                withAnimation {
                    conversationVM.quickLog(category: .feeding, baby: baby, context: modelContext, feedingType: .bottle, amountOz: oz)
                }
            case "diaper":
                let dType: DiaperType
                switch action["diaperType"] {
                case "dirty": dType = .dirty
                case "both": dType = .both
                default: dType = .wet
                }
                withAnimation {
                    conversationVM.quickLog(category: .diaper, baby: baby, context: modelContext, diaperType: dType)
                }
            case "startTimer":
                let category: EventCategory = action["category"] == "feeding" ? .feeding : .sleep
                if !timerVM.isRunning {
                    timerVM.startTimer(category: category, babyName: baby.name)
                }
            default:
                break
            }
        }
    }
}
