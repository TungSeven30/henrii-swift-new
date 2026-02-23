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

    func startTimer(category: EventCategory) {
        timerCategory = category
        startTime = Date()
        isRunning = true
        isPaused = false
        elapsedSeconds = 0
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
        return result
    }

    func toggleSide() {
        feedingSide = feedingSide == .breastLeft ? .breastRight : .breastLeft
    }

    private func startTicking() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, self.isRunning, !self.isPaused else { return }
                self.elapsedSeconds += 1
            }
        }
    }
}
