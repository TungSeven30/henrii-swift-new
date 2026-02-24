import SwiftUI
import SwiftData

struct HomeView: View {
    let baby: Baby
    let babies: [Baby]
    let onShowToday: () -> Void
    let onShowInsights: () -> Void
    let onShowProfile: () -> Void
    let onSwitchBaby: (Baby) -> Void
    @Environment(\.modelContext) private var modelContext
    @Environment(\.henriiReduceMotion) private var reduceMotion
    @State private var conversationVM = ConversationViewModel()
    @State private var timerVM = TimerViewModel()
    @State private var showSearch: Bool = false
    @State private var showGrowthSheet: Bool = false
    @State private var showCustomBottleAlert: Bool = false
    @State private var customBottleText: String = ""
    @State private var selectedBabyIDs: Set<UUID> = []
    @GestureState private var pinchScale: CGFloat = 1.0
    @State private var searchDragOffset: CGFloat = 0
    @Query(sort: \ConversationEntry.timestamp, order: .reverse) private var allEntries: [ConversationEntry]
    @Query(sort: \BabyEvent.timestamp, order: .reverse) private var allEvents: [BabyEvent]

    private var entries: [ConversationEntry] {
        allEntries.filter { $0.babyID == nil || $0.babyID == baby.id }.reversed()
    }

    private var babyEvents: [BabyEvent] {
        allEvents.filter { $0.baby?.id == baby.id }
    }

    private var hasMultipleBabies: Bool {
        babies.count > 1
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
                    onSwitchBaby: onSwitchBaby
                )

                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: HenriiSpacing.md) {
                            if entries.isEmpty {
                                emptyConversationState
                            }

                            ForEach(Array(entries), id: \.id) { entry in
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
                                    }
                                )
                                .id(entry.id)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .bottom).combined(with: .opacity),
                                    removal: .opacity
                                ))
                            }
                        }
                        .padding(.horizontal, HenriiSpacing.margin)
                        .padding(.top, HenriiSpacing.md)
                        .padding(.bottom, timerVM.isRunning ? 220 : 160)
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
                    }
                }
            }
            .scaleEffect(pinchScale > 1.0 ? min(pinchScale, 1.15) : 1.0)
            .opacity(pinchScale > 1.0 ? max(1.0 - (pinchScale - 1.0) * CGFloat(3), 0.5) : 1.0)

            VStack(spacing: 0) {
                if timerVM.isRunning {
                    TimerCardView(timerVM: timerVM) { result in
                        handleTimerStop(result)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.horizontal, HenriiSpacing.margin)
                }

                if hasMultipleBabies {
                    BabyToggleView(
                        babies: babies,
                        selectedBabyIDs: $selectedBabyIDs,
                        onSwitch: onSwitchBaby
                    )
                }

                ContextChipsView(baby: baby, events: babyEvents) { action in
                    handleChipAction(action)
                }

                ComposerView(
                    text: $conversationVM.composerText,
                    timerRunning: timerVM.isRunning
                ) { text in
                    withAnimation(.spring(duration: 0.35, bounce: 0.2)) {
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
        .toolbar(.hidden, for: .navigationBar)
        .gesture(pinchGesture)
        .simultaneousGesture(swipeLeftGesture)
        .sheet(isPresented: $showSearch) {
            SearchView(baby: baby, events: babyEvents)
        }
        .sheet(isPresented: $showGrowthSheet) {
            GrowthLogSheet(baby: baby)
        }
        .alert("Custom Amount", isPresented: $showCustomBottleAlert) {
            TextField("Ounces", text: $customBottleText)
                .keyboardType(.decimalPad)
            Button("Log") {
                if let oz = Double(customBottleText), oz > 0 {
                    withAnimation(.spring(duration: 0.35, bounce: 0.2)) {
                        conversationVM.quickLog(category: .feeding, baby: baby, context: modelContext, feedingType: .bottle, amountOz: oz)
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Enter the amount in ounces")
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
                if value.translation.height > 80 && abs(value.translation.width) < 60 {
                    showSearch = true
                }
            }
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        if let last = entries.last {
            withAnimation(.spring(duration: 0.3)) {
                proxy.scrollTo(last.id, anchor: .bottom)
            }
        }
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
                timerVM.startTimer(category: .sleep)
            }
        } else {
            conversationVM.processInput(text, baby: baby, context: modelContext)
        }
    }

    private func handleChipAction(_ action: ChipAction) {
        switch action {
        case .startFeed:
            timerVM.startTimer(category: .feeding)
        case .startSleep:
            timerVM.startTimer(category: .sleep)
        case .logDiaper(let type):
            withAnimation(.spring(duration: 0.35, bounce: 0.2)) {
                logForSelectedBabies { targetBaby in
                    conversationVM.quickLog(category: .diaper, baby: targetBaby, context: modelContext, diaperType: type)
                }
            }
        case .logBottle(let oz):
            withAnimation(.spring(duration: 0.35, bounce: 0.2)) {
                logForSelectedBabies { targetBaby in
                    conversationVM.quickLog(category: .feeding, baby: targetBaby, context: modelContext, feedingType: .bottle, amountOz: oz)
                }
            }
        case .logBottleCustom:
            customBottleText = ""
            showCustomBottleAlert = true
        case .logGrowth:
            showGrowthSheet = true
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
}
