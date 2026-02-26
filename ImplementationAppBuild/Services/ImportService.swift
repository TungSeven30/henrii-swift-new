import Foundation
import SwiftData
import UniformTypeIdentifiers

@Observable
final class ImportService {
    var importResult: ImportResult?
    var isImporting: Bool = false

    func importCSV(data: Data, baby: Baby, context: ModelContext) {
        isImporting = true
        defer { isImporting = false }

        guard let content = String(data: data, encoding: .utf8) else {
            importResult = ImportResult(success: false, count: 0, message: "Could not read file.")
            return
        }

        let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
        guard lines.count > 1 else {
            importResult = ImportResult(success: false, count: 0, message: "File is empty or has no data rows.")
            return
        }

        let _ = lines[0].lowercased()
        let rows = Array(lines.dropFirst())
        var importedCount = 0

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        let altFormatter = DateFormatter()
        altFormatter.dateFormat = "MM/dd/yyyy HH:mm"
        let dateOnlyFormatter = DateFormatter()
        dateOnlyFormatter.dateFormat = "yyyy-MM-dd"

        for row in rows {
            let columns = parseCSVRow(row)
            guard columns.count >= 2 else { continue }

            let typeStr = columns[0].lowercased().trimmingCharacters(in: .whitespaces)
            let dateStr = columns[1].trimmingCharacters(in: .whitespaces)

            guard let date = dateFormatter.date(from: dateStr)
                    ?? altFormatter.date(from: dateStr)
                    ?? dateOnlyFormatter.date(from: dateStr) else { continue }

            let category: EventCategory
            switch typeStr {
            case "feed", "feeding", "bottle", "breast", "nursing":
                category = .feeding
            case "sleep", "nap":
                category = .sleep
            case "diaper", "change":
                category = .diaper
            case "growth", "weight", "height":
                category = .growth
            case "health", "temperature", "medication", "med":
                category = .health
            case "milestone":
                category = .milestone
            case "note":
                category = .note
            default:
                continue
            }

            let event = BabyEvent(category: category, timestamp: date)
            event.baby = baby

            if columns.count > 2 {
                let detail = columns[2].trimmingCharacters(in: .whitespaces)
                if !detail.isEmpty {
                    switch category {
                    case .feeding:
                        if let oz = Double(detail) { event.amountOz = oz }
                    case .sleep:
                        if let mins = Double(detail) { event.durationMinutes = mins }
                    case .diaper:
                        switch detail.lowercased() {
                        case "wet": event.diaperType = .wet
                        case "dirty": event.diaperType = .dirty
                        case "both": event.diaperType = .both
                        default: break
                        }
                    case .growth:
                        if let lbs = Double(detail) { event.weightLbs = lbs }
                    case .health:
                        if let temp = Double(detail) { event.temperatureF = temp }
                        else { event.medicationName = detail }
                    default:
                        event.notes = detail
                    }
                }
            }

            if columns.count > 3 {
                let extra = columns[3].trimmingCharacters(in: .whitespaces)
                if !extra.isEmpty { event.notes = extra }
            }

            context.insert(event)
            importedCount += 1
        }

        importResult = ImportResult(
            success: importedCount > 0,
            count: importedCount,
            message: importedCount > 0 ? "Imported \(importedCount) entries." : "No valid entries found."
        )
    }

    private func parseCSVRow(_ row: String) -> [String] {
        var result: [String] = []
        var current = ""
        var inQuotes = false

        for char in row {
            if char == "\"" {
                inQuotes.toggle()
            } else if char == "," && !inQuotes {
                result.append(current)
                current = ""
            } else {
                current.append(char)
            }
        }
        result.append(current)
        return result
    }
}

nonisolated struct ImportResult: Sendable {
    let success: Bool
    let count: Int
    let message: String
}
