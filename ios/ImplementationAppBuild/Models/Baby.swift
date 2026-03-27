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
    var apgarScore: String
    var birthWeightLbs: Double?
    var birthLengthInches: Double?
    var bloodType: String?
    var allergies: String?
    var pediatricianName: String?
    var pediatricianPhone: String?
    var nextPediatricianAppointment: Date?
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \BabyEvent.baby)
    var events: [BabyEvent]

    @Relationship(deleteRule: .cascade, inverse: \Vaccination.baby)
    var vaccinations: [Vaccination]

    init(name: String, birthDate: Date, gender: BabyGender = .boy, isPremature: Bool = false, dueDate: Date? = nil, apgarScore: String = "", birthWeightLbs: Double? = nil, birthLengthInches: Double? = nil, bloodType: String? = nil, allergies: String? = nil, pediatricianName: String? = nil, pediatricianPhone: String? = nil, nextPediatricianAppointment: Date? = nil) {
        self.id = UUID()
        self.name = name
        self.birthDate = birthDate
        self.gender = gender
        self.isPremature = isPremature
        self.dueDate = dueDate
        self.apgarScore = apgarScore
        self.birthWeightLbs = birthWeightLbs
        self.birthLengthInches = birthLengthInches
        self.bloodType = bloodType
        self.allergies = allergies
        self.pediatricianName = pediatricianName
        self.pediatricianPhone = pediatricianPhone
        self.nextPediatricianAppointment = nextPediatricianAppointment
        self.createdAt = Date()
        self.events = []
        self.vaccinations = []
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
