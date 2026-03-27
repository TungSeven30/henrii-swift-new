import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var appVM = AppViewModel()
    @Query private var babies: [Baby]
    @Environment(\.modelContext) private var modelContext

    private var currentBaby: Baby? {
        if let idStr = appVM.currentBabyID,
           let uuid = UUID(uuidString: idStr) {
            return babies.first { $0.id == uuid }
        }
        return babies.first
    }

    var body: some View {
        Group {
            if appVM.hasCompletedOnboarding, let baby = currentBaby {
                MainAppView(baby: baby, babies: babies, appVM: appVM)
            } else {
                OnboardingView { babyID in
                    appVM.completeOnboarding(babyID: babyID)
                }
            }
        }
        .tint(HenriiColors.accentPrimary)
        .modifier(ReduceMotionModifier())
    }
}

struct MainAppView: View {
    let baby: Baby
    let babies: [Baby]
    @Bindable var appVM: AppViewModel
    @State private var showToday: Bool = false
    @State private var showInsights: Bool = false
    @State private var showProfile: Bool = false
    @State private var focusComposer: Bool = false
    @Namespace private var dashboardTransitionNamespace
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        Group {
            if sizeClass == .regular {
                iPadLayout
            } else {
                iPhoneLayout
            }
        }
        .tint(HenriiColors.accentPrimary)
    }

    private var iPhoneLayout: some View {
        NavigationStack {
            HomeView(
                baby: baby,
                babies: babies,
                onShowToday: { showToday = true },
                onShowInsights: { showInsights = true },
                onShowProfile: { showProfile = true },
                onSwitchBaby: { newBaby in
                    appVM.currentBabyID = newBaby.id.uuidString
                },
                dashboardTransitionNamespace: dashboardTransitionNamespace
            )
            .navigationDestination(isPresented: $showToday) {
                TodayDashboardView(baby: baby, onPinchBack: { showToday = false }, dashboardTransitionNamespace: dashboardTransitionNamespace)
            }
            .navigationDestination(isPresented: $showInsights) {
                InsightsView(baby: baby)
            }
            .sheet(isPresented: $showProfile) {
                NavigationStack {
                    BabyProfileView(baby: baby)
                }
            }
        }
        .keyboardShortcut("n", modifiers: .command, action: { focusComposer = true })
    }

    private var iPadLayout: some View {
        NavigationSplitView {
            List {
                Section {
                    Button {
                        appVM.selectedTab = .today
                    } label: {
                        Label("Today", systemImage: "calendar")
                    }
                    .listRowBackground(appVM.selectedTab == .today ? HenriiColors.accentPrimary.opacity(0.12) : Color.clear)

                    Button {
                        appVM.selectedTab = .insights
                    } label: {
                        Label("Insights", systemImage: "chart.line.uptrend.xyaxis")
                    }
                    .listRowBackground(appVM.selectedTab == .insights ? HenriiColors.accentPrimary.opacity(0.12) : Color.clear)

                    Button {
                        appVM.selectedTab = .profile
                    } label: {
                        Label("Profile", systemImage: "person.circle")
                    }
                    .listRowBackground(appVM.selectedTab == .profile ? HenriiColors.accentPrimary.opacity(0.12) : Color.clear)
                } header: {
                    HStack(spacing: HenriiSpacing.sm) {
                        Circle()
                            .fill(HenriiColors.accentPrimary.opacity(0.15))
                            .frame(width: 36, height: 36)
                            .overlay {
                                Text(baby.name.prefix(1))
                                    .font(.henriiHeadline)
                                    .foregroundStyle(HenriiColors.accentPrimary)
                            }
                        Text(baby.name)
                            .font(.henriiHeadline)
                            .foregroundStyle(HenriiColors.textPrimary)
                    }
                }
            }
            .navigationTitle("Henrii")
        } detail: {
            NavigationStack {
                switch appVM.selectedTab {
                case .home, .today:
                    TodayDashboardView(baby: baby, dashboardTransitionNamespace: dashboardTransitionNamespace)
                case .insights:
                    InsightsView(baby: baby)
                case .profile:
                    BabyProfileView(baby: baby)
                }
            }
        }
        .keyboardShortcut("n", modifiers: .command, action: { focusComposer = true })
    }
}

extension View {
    func keyboardShortcut(_ key: KeyEquivalent, modifiers: EventModifiers, action: @escaping () -> Void) -> some View {
        self.background {
            Button("") { action() }
                .keyboardShortcut(key, modifiers: modifiers)
                .frame(width: 0, height: 0)
                .opacity(0)
        }
    }
}
