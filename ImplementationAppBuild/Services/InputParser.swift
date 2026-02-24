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
    let weightLbs: Double?
    let heightInches: Double?
    let notes: String?
    let isTimerStart: Bool
    let isTimerStop: Bool
    let isSleepStart: Bool
    let isSleepEnd: Bool
    let isCorrection: Bool
    let correctionAmount: Double?
}

struct InputParser {
    static func parse(_ input: String) -> ParsedEvent? {
        let lower = input.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if lower.isEmpty { return nil }

        if let correction = parseCorrection(lower) { return correction }
        if let feeding = parseFeeding(lower) { return feeding }
        if let sleep = parseSleep(lower) { return sleep }
        if let diaper = parseDiaper(lower) { return diaper }
        if let health = parseHealth(lower) { return health }
        if let pump = parsePumping(lower) { return pump }
        if let growth = parseGrowth(lower) { return growth }

        return ParsedEvent(
            category: .note, feedingType: nil, amountOz: nil, durationMinutes: nil,
            diaperType: nil, temperatureF: nil, medicationName: nil, medicationDose: nil,
            weightLbs: nil, heightInches: nil,
            notes: input, isTimerStart: false, isTimerStop: false, isSleepStart: false, isSleepEnd: false,
            isCorrection: false, correctionAmount: nil
        )
    }

    private static func parseCorrection(_ input: String) -> ParsedEvent? {
        let correctionPatterns = ["actually", "wait,", "wait ", "no,", "no ", "meant", "correction", "not \\d"]
        guard correctionPatterns.contains(where: { input.contains($0) }) else { return nil }

        let amount = extractOunces(input) ?? extractNumber(input)
        guard let amount else { return nil }

        return ParsedEvent(
            category: .feeding, feedingType: nil, amountOz: amount, durationMinutes: nil,
            diaperType: nil, temperatureF: nil, medicationName: nil, medicationDose: nil,
            weightLbs: nil, heightInches: nil,
            notes: nil, isTimerStart: false, isTimerStop: false, isSleepStart: false, isSleepEnd: false,
            isCorrection: true, correctionAmount: amount
        )
    }

    private static func parseFeeding(_ input: String) -> ParsedEvent? {
        let feedPatterns = ["fed", "feed", "bottle", "nursed", "nurse", "breast", "ate", "formula", "solids", "oz", "ounce"]
        guard feedPatterns.contains(where: { input.contains($0) }) else { return nil }

        var feedType: FeedingType = .bottle
        let hasNurseKeywords = input.contains("nursed") || input.contains("nurse") || input.contains("breast")

        if input.contains("left") && input.contains("right") || input.contains("both side") {
            feedType = .breastBoth
        } else if input.contains("left") || input.contains(" l ") || input.hasSuffix(" l") || input.contains("l side") {
            feedType = .breastLeft
        } else if input.contains("right") || input.contains(" r ") || input.hasSuffix(" r") || input.contains("r side") {
            feedType = .breastRight
        } else if hasNurseKeywords && input.contains("then") && (input.contains("bottle") || input.contains("oz")) {
            feedType = .combo
        } else if hasNurseKeywords {
            feedType = .breastBoth
        } else if input.contains("solid") {
            feedType = .solids
        }

        let amount = extractOunces(input)
        let duration = extractMinutes(input)

        return ParsedEvent(
            category: .feeding, feedingType: feedType, amountOz: amount, durationMinutes: duration,
            diaperType: nil, temperatureF: nil, medicationName: nil, medicationDose: nil,
            weightLbs: nil, heightInches: nil,
            notes: nil, isTimerStart: false, isTimerStop: false, isSleepStart: false, isSleepEnd: false,
            isCorrection: false, correctionAmount: nil
        )
    }

    private static func parseSleep(_ input: String) -> ParsedEvent? {
        let sleepStartPatterns = ["asleep", "sleeping", "down for", "nap", "put down", "went to sleep", "bedtime", "fell asleep"]
        let sleepEndPatterns = ["woke", "awake", "up now", "just woke", "she's up", "he's up", "waking", "woken"]

        if sleepEndPatterns.contains(where: { input.contains($0) }) {
            return ParsedEvent(
                category: .sleep, feedingType: nil, amountOz: nil, durationMinutes: nil,
                diaperType: nil, temperatureF: nil, medicationName: nil, medicationDose: nil,
                weightLbs: nil, heightInches: nil,
                notes: nil, isTimerStart: false, isTimerStop: true, isSleepStart: false, isSleepEnd: true,
                isCorrection: false, correctionAmount: nil
            )
        }

        if sleepStartPatterns.contains(where: { input.contains($0) }) || input == "sleep" {
            return ParsedEvent(
                category: .sleep, feedingType: nil, amountOz: nil, durationMinutes: extractMinutes(input),
                diaperType: nil, temperatureF: nil, medicationName: nil, medicationDose: nil,
                weightLbs: nil, heightInches: nil,
                notes: nil, isTimerStart: true, isTimerStop: false, isSleepStart: true, isSleepEnd: false,
                isCorrection: false, correctionAmount: nil
            )
        }

        return nil
    }

    private static func parseDiaper(_ input: String) -> ParsedEvent? {
        let diaperPatterns = ["diaper", "changed", "blowout", "poop", "pee", "wet", "dirty", "\u{1F4A9}"]
        guard diaperPatterns.contains(where: { input.contains($0) }) else { return nil }

        let hasWet = input.contains("wet") || input.contains("pee")
        let hasDirty = input.contains("dirty") || input.contains("poop") || input.contains("blowout") || input.contains("\u{1F4A9}")

        var dType: DiaperType?
        if hasWet && hasDirty {
            dType = .both
        } else if hasWet {
            dType = .wet
        } else if hasDirty {
            dType = .dirty
        }

        return ParsedEvent(
            category: .diaper, feedingType: nil, amountOz: nil, durationMinutes: nil,
            diaperType: dType, temperatureF: nil, medicationName: nil, medicationDose: nil,
            weightLbs: nil, heightInches: nil,
            notes: nil, isTimerStart: false, isTimerStop: false, isSleepStart: false, isSleepEnd: false,
            isCorrection: false, correctionAmount: nil
        )
    }

    private static func parseHealth(_ input: String) -> ParsedEvent? {
        let temp = extractTemperature(input)
        let hasMedKeywords = ["tylenol", "advil", "ibuprofen", "acetaminophen", "medicine", "medication", "gave", "dose"].contains(where: { input.contains($0) })

        guard temp != nil || hasMedKeywords else { return nil }

        var medName: String?
        var medDose: String?
        let medications = ["tylenol", "advil", "ibuprofen", "acetaminophen", "amoxicillin", "motrin"]
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
            weightLbs: nil, heightInches: nil,
            notes: nil, isTimerStart: false, isTimerStop: false, isSleepStart: false, isSleepEnd: false,
            isCorrection: false, correctionAmount: nil
        )
    }

    private static func parsePumping(_ input: String) -> ParsedEvent? {
        guard input.contains("pump") else { return nil }
        return ParsedEvent(
            category: .pumping, feedingType: nil, amountOz: extractOunces(input), durationMinutes: extractMinutes(input),
            diaperType: nil, temperatureF: nil, medicationName: nil, medicationDose: nil,
            weightLbs: nil, heightInches: nil,
            notes: nil, isTimerStart: false, isTimerStop: false, isSleepStart: false, isSleepEnd: false,
            isCorrection: false, correctionAmount: nil
        )
    }

    private static func parseGrowth(_ input: String) -> ParsedEvent? {
        let weightPatterns = ["weigh", "weight", "lbs", "pounds", "lb"]
        let heightPatterns = ["height", "inches", "inch", "tall", "long", "length"]

        let hasWeight = weightPatterns.contains(where: { input.contains($0) })
        let hasHeight = heightPatterns.contains(where: { input.contains($0) })

        guard hasWeight || hasHeight else { return nil }

        var weight: Double?
        var height: Double?

        if hasWeight {
            if let match = input.range(of: #"(\d+\.?\d*)\s*(lbs?|pounds?)"#, options: .regularExpression) {
                let sub = String(input[match])
                let numStr = sub.components(separatedBy: CharacterSet.letters.union(.whitespaces)).joined()
                weight = Double(numStr)
            } else if let match = input.range(of: #"weigh\w*\s+(\d+\.?\d*)"#, options: .regularExpression) {
                let sub = String(input[match])
                let numStr = sub.components(separatedBy: CharacterSet.letters.union(.whitespaces)).joined()
                weight = Double(numStr)
            }
        }

        if hasHeight {
            if let match = input.range(of: #"(\d+\.?\d*)\s*(in|inch|inches)"#, options: .regularExpression) {
                let sub = String(input[match])
                let numStr = sub.components(separatedBy: CharacterSet.letters.union(.whitespaces)).joined()
                height = Double(numStr)
            } else if let match = input.range(of: #"(height|tall|long|length)\s+(\d+\.?\d*)"#, options: .regularExpression) {
                let sub = String(input[match])
                let numStr = sub.components(separatedBy: CharacterSet.letters.union(.whitespaces)).joined()
                height = Double(numStr)
            }
        }

        guard weight != nil || height != nil else { return nil }

        return ParsedEvent(
            category: .growth, feedingType: nil, amountOz: nil, durationMinutes: nil,
            diaperType: nil, temperatureF: nil, medicationName: nil, medicationDose: nil,
            weightLbs: weight, heightInches: height,
            notes: nil, isTimerStart: false, isTimerStop: false, isSleepStart: false, isSleepEnd: false,
            isCorrection: false, correctionAmount: nil
        )
    }

    private static func extractOunces(_ input: String) -> Double? {
        if let match = input.range(of: #"(\d+\.?\d*)\s*(oz|ounce)"#, options: .regularExpression) {
            let sub = String(input[match])
            let numStr = sub.replacingOccurrences(of: "oz", with: "")
                .replacingOccurrences(of: "ounce", with: "")
                .trimmingCharacters(in: .whitespaces)
            return Double(numStr)
        }
        return nil
    }

    private static func extractNumber(_ input: String) -> Double? {
        if let match = input.range(of: #"\d+\.?\d*"#, options: .regularExpression) {
            return Double(input[match])
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
