import SwiftUI
import SwiftData

struct HomeView: View {
    let baby: Baby
    @Environment(\.modelContext) private var modelContext
    @State private var conversationVM = ConversationViewModel()
    @State private var timerVM = TimerViewModel()
    @Query(sort: \ConversationEntry.timestamp) private var entries: [ConversationEntry]
    @Query(sort: \BabyEvent.timestamp, order: .reverse) private var allEvents: [BabyEvent]

    var body: some View {
        ZStack(alignment: .bottom) {
            HenriiColors.canvasPrimary
                .ignoresSafeArea()

            VStack(spacing: 0) {
                StatusHeaderView(baby: baby, events: allEvents)

                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: HenriiSpacing.md) {
                            ForEach(entries) { entry in
                                ConversationBubbleView(
                                    entry: entry,
                                    event: eventFor(entry),
                                    onDelete: {
                                        if let event = eventFor(entry) {
                                            conversationVM.deleteEvent(event, context: modelContext)
                                        }
                                        modelContext.delete(entry)
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
                        if let last = entries.last {
                            withAnimation(.spring(duration: 0.3)) {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                }
            }

            VStack(spacing: 0) {
                if timerVM.isRunning {
                    TimerCardView(timerVM: timerVM) { result in
                        handleTimerStop(result)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.horizontal, HenriiSpacing.margin)
                }

                ContextChipsView(baby: baby, events: allEvents) { action in
                    handleChipAction(action)
                }
                .padding(.horizontal, HenriiSpacing.margin)

                ComposerView(
                    text: $conversationVM.composerText,
                    timerRunning: timerVM.isRunning
                ) { text in
                    withAnimation(.spring(duration: 0.35, bounce: 0.2)) {
                        conversationVM.processInput(text, baby: baby, context: modelContext)
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
        .animation(.spring(duration: 0.35, bounce: 0.2), value: timerVM.isRunning)
    }

    private func eventFor(_ entry: ConversationEntry) -> BabyEvent? {
        guard let eventID = entry.eventID else { return nil }
        return allEvents.first { $0.id == eventID }
    }

    private func handleChipAction(_ action: ChipAction) {
        switch action {
        case .startFeed:
            timerVM.startTimer(category: .feeding)
        case .startSleep:
            timerVM.startTimer(category: .sleep)
        case .logDiaper:
            withAnimation(.spring(duration: 0.35, bounce: 0.2)) {
                conversationVM.quickLog(category: .diaper, baby: baby, context: modelContext, diaperType: .both)
            }
        case .logBottle:
            withAnimation(.spring(duration: 0.35, bounce: 0.2)) {
                conversationVM.quickLog(category: .feeding, baby: baby, context: modelContext, feedingType: .bottle)
            }
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
            eventID: event.id
        )
        modelContext.insert(confirmation)
    }
}
