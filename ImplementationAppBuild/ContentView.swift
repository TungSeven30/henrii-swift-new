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
                MainAppView(baby: baby, appVM: appVM)
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
    @Bindable var appVM: AppViewModel
    @State private var showToday: Bool = false
    @State private var showInsights: Bool = false
    @State private var showProfile: Bool = false

    var body: some View {
        NavigationStack {
            HomeView(
                baby: baby,
                onShowToday: { showToday = true },
                onShowInsights: { showInsights = true },
                onShowProfile: { showProfile = true }
            )
            .navigationDestination(isPresented: $showToday) {
                TodayDashboardView(baby: baby)
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
        .tint(HenriiColors.accentPrimary)
    }
}
