import Foundation
import SwiftData
import SwiftUI

@Observable
final class AppViewModel {
    var hasCompletedOnboarding: Bool {
        get { UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") }
        set { UserDefaults.standard.set(newValue, forKey: "hasCompletedOnboarding") }
    }

    var currentBabyID: String? {
        get { UserDefaults.standard.string(forKey: "currentBabyID") }
        set { UserDefaults.standard.set(newValue, forKey: "currentBabyID") }
    }

    var selectedTab: AppTab = .home

    func completeOnboarding(babyID: UUID) {
        currentBabyID = babyID.uuidString
        hasCompletedOnboarding = true
    }

    func resetOnboarding() {
        hasCompletedOnboarding = false
        currentBabyID = nil
    }
}

nonisolated enum AppTab: String, Sendable {
    case home
    case today
    case insights
    case profile
}
