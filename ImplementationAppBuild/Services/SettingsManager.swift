import Foundation
import SwiftUI

nonisolated enum AITone: String, CaseIterable, Sendable {
    case direct = "Direct"
    case warm = "Warm"
    case playful = "Playful"
}

@Observable
final class SettingsManager {
    static let shared = SettingsManager()

    var insightFrequency: Double {
        get { UserDefaults.standard.double(forKey: "insightFrequency").isZero ? 0.5 : UserDefaults.standard.double(forKey: "insightFrequency") }
        set { UserDefaults.standard.set(newValue, forKey: "insightFrequency") }
    }

    var aiTone: AITone {
        get {
            guard let raw = UserDefaults.standard.string(forKey: "aiTone"),
                  let tone = AITone(rawValue: raw) else { return .warm }
            return tone
        }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: "aiTone") }
    }

    var use24Hour: Bool {
        get { UserDefaults.standard.bool(forKey: "use24Hour") }
        set { UserDefaults.standard.set(newValue, forKey: "use24Hour") }
    }

    var useMetric: Bool {
        get { UserDefaults.standard.bool(forKey: "useMetric") }
        set { UserDefaults.standard.set(newValue, forKey: "useMetric") }
    }

    var feedingNotifications: Bool {
        get { UserDefaults.standard.object(forKey: "feedingNotifications") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "feedingNotifications") }
    }

    var sleepNotifications: Bool {
        get { UserDefaults.standard.object(forKey: "sleepNotifications") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "sleepNotifications") }
    }

    var medicationNotifications: Bool {
        get { UserDefaults.standard.object(forKey: "medicationNotifications") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "medicationNotifications") }
    }

    private init() {}
}
