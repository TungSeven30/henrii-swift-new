import Foundation
import SwiftData

nonisolated enum EventCategory: String, Codable, Sendable, CaseIterable {
    case feeding
    case sleep
    case diaper
    case growth
    case health
    case milestone
    case pumping
    case activity
    case note
}

nonisolated enum FeedingType: String, Codable, Sendable {
    case breastLeft
    case breastRight
    case breastBoth
    case bottle
    case solids
    case combo
}

nonisolated enum DiaperType: String, Codable, Sendable {
    case wet
    case dirty
    case both
}

nonisolated enum SleepQuality: String, Codable, Sendable {
    case good
    case fair
    case poor
}

@Model
final class BabyEvent {
    var id: UUID
    var category: EventCategory
    var timestamp: Date
    var endTime: Date?
    var notes: String?
    var createdAt: Date

    var feedingType: FeedingType?
    var amountOz: Double?
    var durationMinutes: Double?

    var diaperType: DiaperType?

    var sleepQuality: SleepQuality?

    var weightLbs: Double?
    var heightInches: Double?
    var headCircumferenceInches: Double?

    var temperatureF: Double?
    var medicationName: String?
    var medicationDose: String?

    var milestoneDescription: String?
    var foodType: String?
    var symptoms: String?

    var baby: Baby?

    init(
        category: EventCategory,
        timestamp: Date = Date(),
        endTime: Date? = nil,
        notes: String? = nil
    ) {
        self.id = UUID()
        self.category = category
        self.timestamp = timestamp
        self.endTime = endTime
        self.notes = notes
        self.createdAt = Date()
    }

    var icon: String {
        switch category {
        case .feeding:
            switch feedingType {
            case .breastLeft, .breastRight, .breastBoth: return "circle.lefthalf.filled"
            case .bottle, .combo: return "drop.fill"
            case .solids: return "fork.knife"
            case .none: return "drop.fill"
            }
        case .sleep: return "moon.fill"
        case .diaper: return "leaf.fill"
        case .growth: return "ruler.fill"
        case .health: return "heart.text.clipboard.fill"
        case .milestone: return "star.fill"
        case .pumping: return "drop.fill"
        case .activity: return "figure.play"
        case .note: return "note.text"
        }
    }

    var categoryColor: String {
        switch category {
        case .feeding, .pumping: return "DataFeeding"
        case .sleep: return "DataSleep"
        case .diaper: return "DataDiaper"
        case .growth, .milestone: return "DataGrowth"
        case .health: return "SemanticAlert"
        case .activity: return "AccentSecondary"
        case .note: return "TextSecondary"
        }
    }

    var summaryText: String {
        switch category {
        case .feeding:
            return feedingSummary
        case .sleep:
            return sleepSummary
        case .diaper:
            return diaperSummary
        case .growth:
            return growthSummary
        case .health:
            return healthSummary
        case .milestone:
            return milestoneDescription ?? "Milestone reached"
        case .pumping:
            return pumpingSummary
        case .activity:
            return notes ?? "Activity"
        case .note:
            return notes ?? "Note"
        }
    }

    private var feedingSummary: String {
        var parts: [String] = []
        switch feedingType {
        case .breastLeft: parts.append("Nursed left")
        case .breastRight: parts.append("Nursed right")
        case .breastBoth: parts.append("Nursed both sides")
        case .bottle: parts.append("Bottle")
        case .solids: parts.append("Solids")
        case .combo: parts.append("Combo feed")
        case .none: parts.append("Fed")
        }
        if let oz = amountOz {
            parts.append(String(format: "%.1foz", oz))
        }
        if let dur = durationMinutes {
            parts.append(String(format: "%.0fm", dur))
        }
        if let food = foodType, !food.isEmpty {
            parts.append(food)
        }
        return parts.joined(separator: " \u{2022} ")
    }

    private var sleepSummary: String {
        if let dur = durationMinutes {
            let hours = Int(dur) / 60
            let mins = Int(dur) % 60
            if hours > 0 {
                return "Slept \(hours)h \(mins)m"
            }
            return "Slept \(mins)m"
        }
        if endTime == nil {
            return "Sleeping..."
        }
        return "Sleep logged"
    }

    private var diaperSummary: String {
        switch diaperType {
        case .wet: return "Wet diaper"
        case .dirty: return "Dirty diaper"
        case .both: return "Wet + dirty diaper"
        case nil: return "Diaper change"
        }
    }

    private var growthSummary: String {
        var parts: [String] = []
        if let w = weightLbs { parts.append(String(format: "%.1f lbs", w)) }
        if let h = heightInches { parts.append(String(format: "%.1f in", h)) }
        if let hc = headCircumferenceInches { parts.append(String(format: "HC %.1f in", hc)) }
        return parts.isEmpty ? "Growth measured" : parts.joined(separator: " \u{2022} ")
    }

    private var healthSummary: String {
        var parts: [String] = []
        if let temp = temperatureF { parts.append(String(format: "%.1f\u{00B0}F", temp)) }
        if let med = medicationName {
            var medStr = med
            if let dose = medicationDose { medStr += " \(dose)" }
            parts.append(medStr)
        }
        if let sym = symptoms, !sym.isEmpty { parts.append(sym) }
        return parts.isEmpty ? (notes ?? "Health note") : parts.joined(separator: " \u{2022} ")
    }

    private var pumpingSummary: String {
        var parts: [String] = ["Pumped"]
        if let oz = amountOz { parts.append(String(format: "%.1foz", oz)) }
        if let dur = durationMinutes { parts.append(String(format: "%.0fm", dur)) }
        return parts.joined(separator: " \u{2022} ")
    }
}
