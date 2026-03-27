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

    var feedingReminderIntervalHours: Double {
        get {
            let val = UserDefaults.standard.double(forKey: "feedingReminderIntervalHours")
            return val == 0 ? 3.0 : val
        }
        set { UserDefaults.standard.set(newValue, forKey: "feedingReminderIntervalHours") }
    }

    var medicationPreAlertMinutes: Int {
        get {
            let val = UserDefaults.standard.integer(forKey: "medicationPreAlertMinutes")
            return val == 0 ? 15 : val
        }
        set { UserDefaults.standard.set(newValue, forKey: "medicationPreAlertMinutes") }
    }

    var sleepNotifications: Bool {
        get { UserDefaults.standard.object(forKey: "sleepNotifications") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "sleepNotifications") }
    }

    var medicationNotifications: Bool {
        get { UserDefaults.standard.object(forKey: "medicationNotifications") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "medicationNotifications") }
    }

    var pediatricianPhone: String {
        get { UserDefaults.standard.string(forKey: "pediatricianPhone") ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: "pediatricianPhone") }
    }

    var insightConfidenceThreshold: Double {
        get {
            let value = UserDefaults.standard.double(forKey: "insightConfidenceThreshold")
            return value == 0 ? 0.85 : value
        }
        set { UserDefaults.standard.set(newValue, forKey: "insightConfidenceThreshold") }
    }

    var lastAutoInsightDate: Date? {
        get { UserDefaults.standard.object(forKey: "lastAutoInsightDate") as? Date }
        set { UserDefaults.standard.set(newValue, forKey: "lastAutoInsightDate") }
    }

    var caregiversEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "caregiversEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "caregiversEnabled") }
    }

    var appleHealthSyncEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "appleHealthSyncEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "appleHealthSyncEnabled") }
    }

    var siriShortcutsEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "siriShortcutsEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "siriShortcutsEnabled") }
    }

    var appleWatchEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "appleWatchEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "appleWatchEnabled") }
    }

    var dailySummaryHour: Int {
        get {
            let stored = UserDefaults.standard.integer(forKey: "dailySummaryHour")
            return stored == 0 ? 18 : stored
        }
        set { UserDefaults.standard.set(newValue.clamped(to: 16...23), forKey: "dailySummaryHour") }
    }

    private init() {}
}

private extension Int {
    func clamped(to range: ClosedRange<Int>) -> Int {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}
