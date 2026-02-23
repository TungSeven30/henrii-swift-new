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
    }
}

struct MainAppView: View {
    let baby: Baby
    @Bindable var appVM: AppViewModel
    @State private var selectedTab: String = "home"

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Home", systemImage: "message.fill", value: "home") {
                HomeView(baby: baby)
            }

            Tab("Today", systemImage: "calendar", value: "today") {
                NavigationStack {
                    TodayDashboardView(baby: baby)
                }
            }

            Tab("Insights", systemImage: "chart.line.uptrend.xyaxis", value: "insights") {
                NavigationStack {
                    InsightsView(baby: baby)
                }
            }

            Tab("Profile", systemImage: "person.crop.circle", value: "profile") {
                NavigationStack {
                    BabyProfileView(baby: baby)
                }
            }
        }
        .tint(HenriiColors.accentPrimary)
    }
}
