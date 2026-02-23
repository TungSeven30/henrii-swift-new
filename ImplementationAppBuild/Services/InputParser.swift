import Foundation

nonisolated struct ParsedEvent: Sendable {
    let category: EventCategory
    let feedingType: FeedingType?
    let amountOz: Double?
    let durationMinutes: Double?
    let diaperType: DiaperType?
    let temperatureF: Double?
    let medicationName: String?
    let medicationDose: String?
    let notes: String?
    let isTimerStart: Bool
    let isTimerStop: Bool
    let isSleepStart: Bool
    let isSleepEnd: Bool
}

struct InputParser {
    static func parse(_ input: String) -> ParsedEvent? {
        let lower = input.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if lower.isEmpty { return nil }

        if let feeding = parseFeeding(lower) { return feeding }
        if let sleep = parseSleep(lower) { return sleep }
        if let diaper = parseDiaper(lower) { return diaper }
        if let health = parseHealth(lower) { return health }
        if let pump = parsePumping(lower) { return pump }

        return ParsedEvent(
            category: .note, feedingType: nil, amountOz: nil, durationMinutes: nil,
            diaperType: nil, temperatureF: nil, medicationName: nil, medicationDose: nil,
            notes: input, isTimerStart: false, isTimerStop: false, isSleepStart: false, isSleepEnd: false
        )
    }

    private static func parseFeeding(_ input: String) -> ParsedEvent? {
        let feedPatterns = ["fed", "feed", "bottle", "nursed", "nurse", "breast", "ate", "formula", "solids", "oz", "ounce"]
        guard feedPatterns.contains(where: { input.contains($0) }) else { return nil }

        var feedType: FeedingType = .bottle
        if input.contains("left") || input.contains(" l ") || input.hasSuffix(" l") || input.contains("l side") {
            feedType = .breastLeft
        } else if input.contains("right") || input.contains(" r ") || input.hasSuffix(" r") || input.contains("r side") {
            feedType = .breastRight
        } else if input.contains("both side") {
            feedType = .breastBoth
        } else if input.contains("nursed") || input.contains("nurse") || input.contains("breast") {
            feedType = .breastLeft
        } else if input.contains("solid") {
            feedType = .solids
        }

        let amount = extractOunces(input)
        let duration = extractMinutes(input)

        return ParsedEvent(
            category: .feeding, feedingType: feedType, amountOz: amount, durationMinutes: duration,
            diaperType: nil, temperatureF: nil, medicationName: nil, medicationDose: nil,
            notes: nil, isTimerStart: false, isTimerStop: false, isSleepStart: false, isSleepEnd: false
        )
    }

    private static func parseSleep(_ input: String) -> ParsedEvent? {
        let sleepStartPatterns = ["asleep", "sleeping", "down for", "nap", "put down", "went to sleep", "bedtime"]
        let sleepEndPatterns = ["woke", "awake", "up now", "just woke", "she's up", "he's up", "waking"]

        if sleepEndPatterns.contains(where: { input.contains($0) }) {
            return ParsedEvent(
                category: .sleep, feedingType: nil, amountOz: nil, durationMinutes: nil,
                diaperType: nil, temperatureF: nil, medicationName: nil, medicationDose: nil,
                notes: nil, isTimerStart: false, isTimerStop: true, isSleepStart: false, isSleepEnd: true
            )
        }

        if sleepStartPatterns.contains(where: { input.contains($0) }) || input.contains("sleep") {
            return ParsedEvent(
                category: .sleep, feedingType: nil, amountOz: nil, durationMinutes: extractMinutes(input),
                diaperType: nil, temperatureF: nil, medicationName: nil, medicationDose: nil,
                notes: nil, isTimerStart: true, isTimerStop: false, isSleepStart: true, isSleepEnd: false
            )
        }

        return nil
    }

    private static func parseDiaper(_ input: String) -> ParsedEvent? {
        let diaperPatterns = ["diaper", "changed", "blowout", "poop", "pee", "wet", "dirty", "\u{1F4A9}"]
        guard diaperPatterns.contains(where: { input.contains($0) }) else { return nil }

        var dType: DiaperType = .both
        let wetOnly = input.contains("wet") && !input.contains("dirty") && !input.contains("poop") && !input.contains("blowout")
        let dirtyOnly = (input.contains("dirty") || input.contains("poop") || input.contains("blowout") || input.contains("\u{1F4A9}")) && !input.contains("wet")

        if wetOnly { dType = .wet }
        else if dirtyOnly { dType = .dirty }

        return ParsedEvent(
            category: .diaper, feedingType: nil, amountOz: nil, durationMinutes: nil,
            diaperType: dType, temperatureF: nil, medicationName: nil, medicationDose: nil,
            notes: nil, isTimerStart: false, isTimerStop: false, isSleepStart: false, isSleepEnd: false
        )
    }

    private static func parseHealth(_ input: String) -> ParsedEvent? {
        let temp = extractTemperature(input)
        let hasMedKeywords = ["tylenol", "advil", "ibuprofen", "acetaminophen", "medicine", "medication", "gave", "dose"].contains(where: { input.contains($0) })

        guard temp != nil || hasMedKeywords else { return nil }

        var medName: String?
        var medDose: String?
        let medications = ["tylenol", "advil", "ibuprofen", "acetaminophen", "amoxicillin"]
        for med in medications {
            if input.contains(med) {
                medName = med.capitalized
                break
            }
        }
        if let mlMatch = input.range(of: #"\d+\.?\d*\s*ml"#, options: .regularExpression) {
            medDose = String(input[mlMatch])
        }

        return ParsedEvent(
            category: .health, feedingType: nil, amountOz: nil, durationMinutes: nil,
            diaperType: nil, temperatureF: temp, medicationName: medName, medicationDose: medDose,
            notes: nil, isTimerStart: false, isTimerStop: false, isSleepStart: false, isSleepEnd: false
        )
    }

    private static func parsePumping(_ input: String) -> ParsedEvent? {
        guard input.contains("pump") else { return nil }
        return ParsedEvent(
            category: .pumping, feedingType: nil, amountOz: extractOunces(input), durationMinutes: extractMinutes(input),
            diaperType: nil, temperatureF: nil, medicationName: nil, medicationDose: nil,
            notes: nil, isTimerStart: false, isTimerStop: false, isSleepStart: false, isSleepEnd: false
        )
    }

    private static func extractOunces(_ input: String) -> Double? {
        if let match = input.range(of: #"(\d+\.?\d*)\s*(oz|ounce)"#, options: .regularExpression) {
            let numStr = input[match].components(separatedBy: CharacterSet.letters.union(.whitespaces)).first ?? ""
            return Double(numStr)
        }
        if let match = input.range(of: #"(\d+\.?\d*)\s*oz"#, options: .regularExpression) {
            let sub = String(input[match])
            let numStr = sub.replacingOccurrences(of: "oz", with: "").trimmingCharacters(in: .whitespaces)
            return Double(numStr)
        }
        return nil
    }

    private static func extractMinutes(_ input: String) -> Double? {
        if let match = input.range(of: #"(\d+)\s*(min|m\b|minutes)"#, options: .regularExpression) {
            let sub = String(input[match])
            let numStr = sub.components(separatedBy: CharacterSet.letters.union(.whitespaces)).joined()
            return Double(numStr)
        }
        if let match = input.range(of: #"(\d+)\s*(h|hr|hour)"#, options: .regularExpression) {
            let sub = String(input[match])
            let numStr = sub.components(separatedBy: CharacterSet.letters.union(.whitespaces)).joined()
            if let hours = Double(numStr) { return hours * 60 }
        }
        return nil
    }

    private static func extractTemperature(_ input: String) -> Double? {
        if let match = input.range(of: #"(\d{2,3}\.?\d*)\s*(\u{00B0}|deg|f\b)"#, options: .regularExpression) {
            let sub = String(input[match])
            let numStr = sub.components(separatedBy: CharacterSet.letters.union(CharacterSet(charactersIn: "\u{00B0}")).union(.whitespaces)).joined()
            if let temp = Double(numStr), temp >= 95.0, temp <= 110.0 {
                return temp
            }
        }
        if let match = input.range(of: #"temp\w*\s+(\d{2,3}\.?\d*)"#, options: .regularExpression) {
            let sub = String(input[match])
            let numStr = sub.components(separatedBy: CharacterSet.letters.union(.whitespaces)).joined()
            if let temp = Double(numStr), temp >= 95.0, temp <= 110.0 {
                return temp
            }
        }
        return nil
    }
}
