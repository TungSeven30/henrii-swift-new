import Foundation
import SwiftData

@Observable
final class AgingOutService {
    static let shared = AgingOutService()

    var isAgingOut: Bool = false
    var reducedChipMode: Bool = false
    var milestoneJournalMode: Bool = false

    private let rollingWindowDays: Int = 7
    private let lowThreshold: Int = 3
    private let consecutiveWeeksRequired: Int = 2

    private let agingOutKey = "agingOutDetected"
    private let lowWeekCountKey = "agingOutLowWeekCount"
    private let lastCheckDateKey = "agingOutLastCheckDate"

    private init() {
        isAgingOut = UserDefaults.standard.bool(forKey: agingOutKey)
        reducedChipMode = isAgingOut
        milestoneJournalMode = isAgingOut
    }

    func evaluateUsage(baby: Baby, context: ModelContext) {
        let calendar = Calendar.current
        if let lastCheck = UserDefaults.standard.object(forKey: lastCheckDateKey) as? Date,
           calendar.isDateInToday(lastCheck) {
            return
        }
        UserDefaults.standard.set(Date(), forKey: lastCheckDateKey)

        let sevenDaysAgo = calendar.date(byAdding: .day, value: -rollingWindowDays, to: Date())!
        let descriptor = FetchDescriptor<BabyEvent>(
            predicate: #Predicate { $0.timestamp >= sevenDaysAgo }
        )
        let recentEvents = ((try? context.fetch(descriptor)) ?? []).filter { $0.baby?.id == baby.id }
        let dailyAvg = Double(recentEvents.count) / Double(rollingWindowDays)

        if dailyAvg < Double(lowThreshold) {
            var weekCount = UserDefaults.standard.integer(forKey: lowWeekCountKey) + 1
            UserDefaults.standard.set(weekCount, forKey: lowWeekCountKey)

            if weekCount >= consecutiveWeeksRequired {
                isAgingOut = true
                reducedChipMode = true
                milestoneJournalMode = true
                UserDefaults.standard.set(true, forKey: agingOutKey)
            }
        } else {
            UserDefaults.standard.set(0, forKey: lowWeekCountKey)
            if isAgingOut {
                isAgingOut = false
                reducedChipMode = false
                milestoneJournalMode = false
                UserDefaults.standard.set(false, forKey: agingOutKey)
            }
        }
    }

    func resetAgingOut() {
        isAgingOut = false
        reducedChipMode = false
        milestoneJournalMode = false
        UserDefaults.standard.set(false, forKey: agingOutKey)
        UserDefaults.standard.set(0, forKey: lowWeekCountKey)
    }
}
