import Foundation
import SwiftUI

@Observable
final class TimerViewModel {
    var isRunning: Bool = false
    var isPaused: Bool = false
    var startTime: Date?
    var elapsedSeconds: Int = 0
    var timerCategory: EventCategory = .feeding
    var feedingSide: FeedingType = .breastLeft

    private var timer: Timer?

    private let startTimeKey = "timerStartTime"
    private let categoryKey = "timerCategory"
    private let sideKey = "timerSide"
    private let runningKey = "timerRunning"

    var formattedTime: String {
        let hours = elapsedSeconds / 3600
        let minutes = (elapsedSeconds % 3600) / 60
        let seconds = elapsedSeconds % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var elapsedMinutes: Double {
        Double(elapsedSeconds) / 60.0
    }

    init() {
        restoreTimerIfNeeded()
    }

    func startTimer(category: EventCategory) {
        timerCategory = category
        startTime = Date()
        isRunning = true
        isPaused = false
        elapsedSeconds = 0
        persistTimerState()
        startTicking()
    }

    func pauseTimer() {
        isPaused = true
        timer?.invalidate()
        timer = nil
    }

    func resumeTimer() {
        isPaused = false
        startTicking()
    }

    func stopTimer() -> (category: EventCategory, duration: Double, side: FeedingType)? {
        guard isRunning else { return nil }
        let result = (category: timerCategory, duration: elapsedMinutes, side: feedingSide)
        timer?.invalidate()
        timer = nil
        isRunning = false
        isPaused = false
        elapsedSeconds = 0
        startTime = nil
        clearPersistedTimer()
        return result
    }

    func toggleSide() {
        feedingSide = feedingSide == .breastLeft ? .breastRight : .breastLeft
        if isRunning {
            UserDefaults.standard.set(feedingSide.rawValue, forKey: sideKey)
        }
    }

    private func startTicking() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, self.isRunning, !self.isPaused else { return }
                if let start = self.startTime {
                    self.elapsedSeconds = Int(Date().timeIntervalSince(start))
                } else {
                    self.elapsedSeconds += 1
                }
            }
        }
    }

    private func persistTimerState() {
        UserDefaults.standard.set(startTime?.timeIntervalSince1970, forKey: startTimeKey)
        UserDefaults.standard.set(timerCategory.rawValue, forKey: categoryKey)
        UserDefaults.standard.set(feedingSide.rawValue, forKey: sideKey)
        UserDefaults.standard.set(true, forKey: runningKey)
    }

    private func clearPersistedTimer() {
        UserDefaults.standard.removeObject(forKey: startTimeKey)
        UserDefaults.standard.removeObject(forKey: categoryKey)
        UserDefaults.standard.removeObject(forKey: sideKey)
        UserDefaults.standard.set(false, forKey: runningKey)
    }

    private func restoreTimerIfNeeded() {
        guard UserDefaults.standard.bool(forKey: runningKey),
              let startInterval = UserDefaults.standard.object(forKey: startTimeKey) as? TimeInterval,
              let catRaw = UserDefaults.standard.string(forKey: categoryKey),
              let cat = EventCategory(rawValue: catRaw) else { return }

        let restored = Date(timeIntervalSince1970: startInterval)
        let elapsed = Int(Date().timeIntervalSince(restored))
        guard elapsed > 0 && elapsed < 86400 else {
            clearPersistedTimer()
            return
        }

        startTime = restored
        timerCategory = cat
        elapsedSeconds = elapsed
        isRunning = true
        isPaused = false

        if let sideRaw = UserDefaults.standard.string(forKey: sideKey),
           let side = FeedingType(rawValue: sideRaw) {
            feedingSide = side
        }

        startTicking()
    }
}
