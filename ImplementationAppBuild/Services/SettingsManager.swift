import Foundation
import SwiftUI

@Observable
final class SettingsManager {
    static let shared = SettingsManager()

    var insightFrequency: Double {
        get { UserDefaults.standard.double(forKey: "insightFrequency").isZero ? 0.5 : UserDefaults.standard.double(forKey: "insightFrequency") }
        set { UserDefaults.standard.set(newValue, forKey: "insightFrequency") }
    }

    var use24Hour: Bool {
        get { UserDefaults.standard.bool(forKey: "use24Hour") }
        set { UserDefaults.standard.set(newValue, forKey: "use24Hour") }
    }

    var useMetric: Bool {
        get { UserDefaults.standard.bool(forKey: "useMetric") }
        set { UserDefaults.standard.set(newValue, forKey: "useMetric") }
    }

    private init() {}
}
