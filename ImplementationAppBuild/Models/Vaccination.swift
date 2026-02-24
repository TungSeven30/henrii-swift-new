import Foundation
import SwiftData

@Model
final class Vaccination {
    var id: UUID
    var name: String
    var date: Date
    var notes: String?
    var baby: Baby?

    init(name: String, date: Date, notes: String? = nil) {
        self.id = UUID()
        self.name = name
        self.date = date
        self.notes = notes
    }
}
