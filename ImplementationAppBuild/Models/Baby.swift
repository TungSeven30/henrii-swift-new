import Foundation
import SwiftData

nonisolated enum BabyGender: String, Codable, Sendable, CaseIterable {
    case boy
    case girl

    var displayName: String {
        switch self {
        case .boy: return "Boy"
        case .girl: return "Girl"
        }
    }
}

@Model
final class Baby {
    var id: UUID
    var name: String
    var birthDate: Date
    var gender: BabyGender
    var photoData: Data?
    var isPremature: Bool
    var dueDate: Date?
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \BabyEvent.baby)
    var events: [BabyEvent]

    init(name: String, birthDate: Date, gender: BabyGender = .boy, isPremature: Bool = false, dueDate: Date? = nil) {
        self.id = UUID()
        self.name = name
        self.birthDate = birthDate
        self.gender = gender
        self.isPremature = isPremature
        self.dueDate = dueDate
        self.createdAt = Date()
        self.events = []
    }

    var ageDescription: String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month, .day], from: birthDate, to: Date())
        let months = components.month ?? 0
        let days = components.day ?? 0
        if months < 1 {
            return "\(days) day\(days == 1 ? "" : "s") old"
        } else if months < 12 {
            return "\(months) month\(months == 1 ? "" : "s") old"
        } else {
            let years = months / 12
            let remainingMonths = months % 12
            if remainingMonths == 0 {
                return "\(years) year\(years == 1 ? "" : "s") old"
            }
            return "\(years)y \(remainingMonths)m old"
        }
    }

    var ageInWeeks: Int {
        Calendar.current.dateComponents([.weekOfYear], from: birthDate, to: Date()).weekOfYear ?? 0
    }

    var ageInMonths: Int {
        Calendar.current.dateComponents([.month], from: birthDate, to: Date()).month ?? 0
    }
}
