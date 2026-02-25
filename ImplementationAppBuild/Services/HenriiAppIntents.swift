import AppIntents
import SwiftData
import SwiftUI

struct LogFeedingIntent: AppIntent {
    static let title: LocalizedStringResource = "Log Feeding"
    static let description = IntentDescription("Log a feeding for your baby")
    static var openAppWhenRun: Bool = true

    @Parameter(title: "Amount (oz)")
    var amountOz: Double?

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let amount = amountOz
        let message: String
        if let oz = amount {
            message = "Logged a \(String(format: "%.1f", oz))oz feeding."
        } else {
            message = "Logged a feeding."
        }

        let defaults = UserDefaults(suiteName: "group.app.rork.henrii") ?? .standard
        var pendingActions = defaults.array(forKey: "pendingIntentActions") as? [[String: String]] ?? []
        var action: [String: String] = ["type": "feeding"]
        if let oz = amount {
            action["amountOz"] = String(oz)
        }
        pendingActions.append(action)
        defaults.set(pendingActions, forKey: "pendingIntentActions")

        return .result(dialog: IntentDialog(stringLiteral: message))
    }
}

struct StartTimerIntent: AppIntent {
    static let title: LocalizedStringResource = "Start Timer"
    static let description = IntentDescription("Start a sleep or feeding timer")
    static var openAppWhenRun: Bool = true

    @Parameter(title: "Timer Type", default: .sleep)
    var timerType: TimerTypeEnum

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let defaults = UserDefaults(suiteName: "group.app.rork.henrii") ?? .standard
        var pendingActions = defaults.array(forKey: "pendingIntentActions") as? [[String: String]] ?? []
        pendingActions.append(["type": "startTimer", "category": timerType.rawValue])
        defaults.set(pendingActions, forKey: "pendingIntentActions")

        return .result(dialog: IntentDialog(stringLiteral: "Starting \(timerType.localizedName) timer."))
    }
}

struct QueryLastEventIntent: AppIntent {
    static let title: LocalizedStringResource = "Check Last Event"
    static let description = IntentDescription("Ask when the last feeding, diaper, or sleep was")
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Event Type", default: .feeding)
    var eventType: QueryEventTypeEnum

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let defaults = UserDefaults(suiteName: "group.app.rork.henrii") ?? .standard

        let key: String
        switch eventType {
        case .feeding: key = "widgetLastFeedText"
        case .diaper: key = "widgetLastDiaperText"
        case .sleep: key = "widgetLastSleepText"
        }

        let lastText = defaults.string(forKey: key) ?? "No data available yet."
        return .result(dialog: IntentDialog(stringLiteral: lastText))
    }
}

struct LogDiaperIntent: AppIntent {
    static let title: LocalizedStringResource = "Log Diaper Change"
    static let description = IntentDescription("Log a diaper change for your baby")
    static var openAppWhenRun: Bool = true

    @Parameter(title: "Type", default: .wet)
    var diaperType: DiaperTypeEnum

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let defaults = UserDefaults(suiteName: "group.app.rork.henrii") ?? .standard
        var pendingActions = defaults.array(forKey: "pendingIntentActions") as? [[String: String]] ?? []
        pendingActions.append(["type": "diaper", "diaperType": diaperType.rawValue])
        defaults.set(pendingActions, forKey: "pendingIntentActions")

        return .result(dialog: IntentDialog(stringLiteral: "Logged a \(diaperType.localizedName) diaper change."))
    }
}

nonisolated enum TimerTypeEnum: String, AppEnum, Sendable {
    case sleep
    case feeding

    nonisolated static var typeDisplayRepresentation: TypeDisplayRepresentation {
        "Timer Type"
    }

    nonisolated static var caseDisplayRepresentations: [TimerTypeEnum: DisplayRepresentation] {
        [
            .sleep: "Sleep",
            .feeding: "Feeding"
        ]
    }

    var localizedName: String {
        switch self {
        case .sleep: return "sleep"
        case .feeding: return "feeding"
        }
    }
}

nonisolated enum QueryEventTypeEnum: String, AppEnum, Sendable {
    case feeding
    case diaper
    case sleep

    nonisolated static var typeDisplayRepresentation: TypeDisplayRepresentation {
        "Event Type"
    }

    nonisolated static var caseDisplayRepresentations: [QueryEventTypeEnum: DisplayRepresentation] {
        [
            .feeding: "Feeding",
            .diaper: "Diaper",
            .sleep: "Sleep"
        ]
    }
}

nonisolated enum DiaperTypeEnum: String, AppEnum, Sendable {
    case wet
    case dirty
    case both

    nonisolated static var typeDisplayRepresentation: TypeDisplayRepresentation {
        "Diaper Type"
    }

    nonisolated static var caseDisplayRepresentations: [DiaperTypeEnum: DisplayRepresentation] {
        [
            .wet: "Wet",
            .dirty: "Dirty",
            .both: "Wet + Dirty"
        ]
    }

    var localizedName: String {
        switch self {
        case .wet: return "wet"
        case .dirty: return "dirty"
        case .both: return "wet + dirty"
        }
    }
}

struct HenriiShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LogFeedingIntent(),
            phrases: [
                "Log a feeding in \(.applicationName)",
                "Tell \(.applicationName) I just fed",
                "Fed baby in \(.applicationName)",
            ],
            shortTitle: "Log Feeding",
            systemImageName: "drop.fill"
        )

        AppShortcut(
            intent: StartTimerIntent(),
            phrases: [
                "Start a timer in \(.applicationName)",
                "Start sleep timer in \(.applicationName)",
                "Start feeding timer in \(.applicationName)",
            ],
            shortTitle: "Start Timer",
            systemImageName: "timer"
        )

        AppShortcut(
            intent: QueryLastEventIntent(),
            phrases: [
                "Ask \(.applicationName) when the last feeding was",
                "Check last diaper in \(.applicationName)",
                "When did baby last eat in \(.applicationName)",
            ],
            shortTitle: "Check Last Event",
            systemImageName: "questionmark.bubble"
        )

        AppShortcut(
            intent: LogDiaperIntent(),
            phrases: [
                "Log a diaper change in \(.applicationName)",
                "Tell \(.applicationName) diaper change",
                "Diaper in \(.applicationName)",
            ],
            shortTitle: "Log Diaper",
            systemImageName: "leaf.fill"
        )
    }
}
