import Foundation
import ActivityKit

nonisolated struct HenriiTimerActivityAttributes: ActivityAttributes, Sendable {
    public nonisolated struct ContentState: Codable, Hashable, Sendable {
        let elapsedSeconds: Int
        let categoryRawValue: String
        let isPaused: Bool
        let sideRawValue: String
    }

    let babyName: String
}

nonisolated final class HenriiLiveActivityManager: Sendable {
    static let shared: HenriiLiveActivityManager = .init()

    private init() {}

    func startTimerActivity(babyName: String, category: EventCategory, elapsedSeconds: Int, isPaused: Bool, side: FeedingType) async {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let attributes = HenriiTimerActivityAttributes(babyName: babyName)
        let content = HenriiTimerActivityAttributes.ContentState(
            elapsedSeconds: elapsedSeconds,
            categoryRawValue: category.rawValue,
            isPaused: isPaused,
            sideRawValue: side.rawValue
        )

        do {
            _ = try Activity<HenriiTimerActivityAttributes>.request(
                attributes: attributes,
                content: .init(state: content, staleDate: nil),
                pushType: nil
            )
        } catch {
            return
        }
    }

    func updateTimerActivity(category: EventCategory, elapsedSeconds: Int, isPaused: Bool, side: FeedingType) async {
        let content = HenriiTimerActivityAttributes.ContentState(
            elapsedSeconds: elapsedSeconds,
            categoryRawValue: category.rawValue,
            isPaused: isPaused,
            sideRawValue: side.rawValue
        )

        for activity in Activity<HenriiTimerActivityAttributes>.activities {
            await activity.update(.init(state: content, staleDate: nil))
        }
    }

    func endTimerActivity(category: EventCategory, elapsedSeconds: Int, side: FeedingType) async {
        let finalState = HenriiTimerActivityAttributes.ContentState(
            elapsedSeconds: elapsedSeconds,
            categoryRawValue: category.rawValue,
            isPaused: false,
            sideRawValue: side.rawValue
        )

        for activity in Activity<HenriiTimerActivityAttributes>.activities {
            await activity.end(.init(state: finalState, staleDate: nil), dismissalPolicy: .immediate)
        }
    }
}
