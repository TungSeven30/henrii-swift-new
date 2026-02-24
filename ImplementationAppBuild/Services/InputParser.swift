import Foundation

nonisolated enum QueryTopic: String, Sendable {
    case weight
    case feeding
    case sleep
    case diaper
    case growth
    case health
    case general
}

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
    let foodType: String?
    let isQuery: Bool
    let queryTopic: QueryTopic?
}

struct InputParser {
    static func parse(_ input: String) -> ParsedEvent? {
        let lower = input.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if lower.isEmpty { return nil }

        if let query = parseQuery(lower) { return query }
        if let correction = parseCorrection(lower) { return correction }
        if let feeding = parseFeeding(lower) { return feeding }
        if let sleep = parseSleep(lower) { return sleep }
        if let diaper = parseDiaper(lower) { return diaper }
        if let health = parseHealth(lower) { return health }
        if let pump = parsePumping(lower) { return pump }
        if let growth = parseGrowth(lower) { return growth }
        if let activity = parseActivity(lower, raw: input) { return activity }
        if let milestone = parseMilestone(lower, raw: input) { return milestone }

        return makeEvent(category: .note, notes: input)
    }

    private static func parseQuery(_ input: String) -> ParsedEvent? {
        let questionIndicators = ["how", "when", "what", "how's", "how is", "how are", "show me", "tell me about", "any insight", "summary", "trend", "doing", "status", "report", "update", "average", "pattern"]
        let hasQuestion = questionIndicators.contains(where: { input.hasPrefix($0) }) || input.contains("?") || input.contains("how is") || input.contains("how's")
        guard hasQuestion else { return nil }

        let hasActionWord = ["fed", "feed ", "nursed", "bottle ", "diaper change", "log ", "start ", "stop "].contains(where: { input.contains($0) })
        if hasActionWord && !input.contains("?") { return nil }

        var topic: QueryTopic = .general
        if input.contains("weight") || input.contains("heavy") || input.contains("weigh") {
            topic = .weight
        } else if input.contains("feed") || input.contains("eat") || input.contains("bottle") || input.contains("nurse") || input.contains("formula") || input.contains("hungry") {
            topic = .feeding
        } else if input.contains("sleep") || input.contains("nap") || input.contains("rest") || input.contains("night") {
            topic = .sleep
        } else if input.contains("diaper") || input.contains("poop") || input.contains("pee") {
            topic = .diaper
        } else if input.contains("grow") || input.contains("height") || input.contains("tall") || input.contains("percentile") {
            topic = .growth
        } else if input.contains("health") || input.contains("sick") || input.contains("temp") || input.contains("fever") || input.contains("medicine") || input.contains("medication") {
            topic = .health
        }

        return ParsedEvent(
            category: .note, feedingType: nil, amountOz: nil, durationMinutes: nil,
            diaperType: nil, temperatureF: nil, medicationName: nil, medicationDose: nil,
            weightLbs: nil, heightInches: nil,
            notes: nil, isTimerStart: false, isTimerStop: false, isSleepStart: false, isSleepEnd: false,
            isCorrection: false, correctionAmount: nil, foodType: nil, isQuery: true, queryTopic: topic
        )
    }

    private static func parseCorrection(_ input: String) -> ParsedEvent? {
        let hasCorrection = input.hasPrefix("actually") ||
            input.hasPrefix("wait,") || input.hasPrefix("wait ") ||
            input.hasPrefix("no,") || input.hasPrefix("no ") ||
            input.contains("meant") || input.contains("correction")

        let hasNotPattern: Bool = {
            guard let range = input.range(of: #"not\s+\d"#, options: .regularExpression) else { return false }
            return !range.isEmpty
        }()

        guard hasCorrection || hasNotPattern else { return nil }

        let amount = extractOunces(input) ?? extractNumber(input)
        guard let amount else { return nil }

        return ParsedEvent(
            category: .feeding, feedingType: nil, amountOz: amount, durationMinutes: nil,
            diaperType: nil, temperatureF: nil, medicationName: nil, medicationDose: nil,
            weightLbs: nil, heightInches: nil,
            notes: nil, isTimerStart: false, isTimerStop: false, isSleepStart: false, isSleepEnd: false,
            isCorrection: true, correctionAmount: amount, foodType: nil, isQuery: false, queryTopic: nil
        )
    }

    private static func parseFeeding(_ input: String) -> ParsedEvent? {
        let feedPatterns = ["fed", "feed", "bottle", "nursed", "nurse", "breast", "ate", "formula", "solids", "oz", "ounce", "nursing"]
        guard feedPatterns.contains(where: { input.contains($0) }) else { return nil }

        var feedType: FeedingType = .bottle
        let hasNurseKeywords = input.contains("nursed") || input.contains("nurse") || input.contains("nursing") || input.contains("breast")
        let hasBottleKeywords = input.contains("bottle") || input.contains("formula")

        if hasNurseKeywords && hasBottleKeywords {
            feedType = .combo
        } else if input.contains("left") && input.contains("right") || input.contains("both side") {
            feedType = .breastBoth
        } else if input.contains("left") || input.contains(" l ") || input.hasSuffix(" l") || input.contains("l side") {
            feedType = .breastLeft
        } else if input.contains("right") || input.contains(" r ") || input.hasSuffix(" r") || input.contains("r side") {
            feedType = .breastRight
        } else if hasNurseKeywords && input.contains("then") && (hasBottleKeywords || input.contains("oz")) {
            feedType = .combo
        } else if hasNurseKeywords {
            feedType = .breastBoth
        } else if input.contains("solid") {
            feedType = .solids
        }

        let amount = extractOunces(input)
        let duration = extractMinutes(input)

        var foodType: String?
        if feedType == .solids {
            let foods = ["cereal", "puree", "banana", "avocado", "sweet potato", "apple", "pear", "oatmeal", "rice", "carrots", "peas", "yogurt"]
            for food in foods {
                if input.contains(food) {
                    foodType = food.capitalized
                    break
                }
            }
        }

        return ParsedEvent(
            category: .feeding, feedingType: feedType, amountOz: amount, durationMinutes: duration,
            diaperType: nil, temperatureF: nil, medicationName: nil, medicationDose: nil,
            weightLbs: nil, heightInches: nil,
            notes: nil, isTimerStart: false, isTimerStop: false, isSleepStart: false, isSleepEnd: false,
            isCorrection: false, correctionAmount: nil, foodType: foodType, isQuery: false, queryTopic: nil
        )
    }

    private static func parseSleep(_ input: String) -> ParsedEvent? {
        let sleepStartPatterns = ["asleep", "sleeping", "down for", "nap", "put down", "went to sleep", "bedtime", "fell asleep", "going to sleep", "night night", "lights out"]
        let sleepEndPatterns = ["woke", "awake", "up now", "just woke", "she's up", "he's up", "waking", "woken", "got up", "morning"]

        if sleepEndPatterns.contains(where: { input.contains($0) }) {
            return makeEvent(category: .sleep, isTimerStop: true, isSleepEnd: true, isQuery: false)
        }

        if sleepStartPatterns.contains(where: { input.contains($0) }) || input == "sleep" {
            return ParsedEvent(
                category: .sleep, feedingType: nil, amountOz: nil, durationMinutes: extractMinutes(input),
                diaperType: nil, temperatureF: nil, medicationName: nil, medicationDose: nil,
                weightLbs: nil, heightInches: nil,
                notes: nil, isTimerStart: true, isTimerStop: false, isSleepStart: true, isSleepEnd: false,
                isCorrection: false, correctionAmount: nil, foodType: nil, isQuery: false, queryTopic: nil
            )
        }

        return nil
    }

    private static func parseDiaper(_ input: String) -> ParsedEvent? {
        let diaperPatterns = ["diaper", "changed", "blowout", "poop", "pee", "wet", "dirty", "\u{1F4A9}", "pooped", "poopy"]
        guard diaperPatterns.contains(where: { input.contains($0) }) else { return nil }

        let hasWet = input.contains("wet") || input.contains("pee")
        let hasDirty = input.contains("dirty") || input.contains("poop") || input.contains("blowout") || input.contains("\u{1F4A9}") || input.contains("poopy")

        var dType: DiaperType
        if hasWet && hasDirty {
            dType = .both
        } else if hasWet {
            dType = .wet
        } else if hasDirty {
            dType = .dirty
        } else {
            dType = .wet
        }

        var notes: String?
        let colors = ["green", "yellow", "brown", "black", "tarry", "mucus", "blood", "red"]
        for color in colors {
            if input.contains(color) {
                notes = "Color: \(color)"
                break
            }
        }

        return ParsedEvent(
            category: .diaper, feedingType: nil, amountOz: nil, durationMinutes: nil,
            diaperType: dType, temperatureF: nil, medicationName: nil, medicationDose: nil,
            weightLbs: nil, heightInches: nil,
            notes: notes, isTimerStart: false, isTimerStop: false, isSleepStart: false, isSleepEnd: false,
            isCorrection: false, correctionAmount: nil, foodType: nil, isQuery: false, queryTopic: nil
        )
    }

    private static func parseHealth(_ input: String) -> ParsedEvent? {
        let temp = extractTemperature(input)
        let hasMedKeywords = ["tylenol", "advil", "ibuprofen", "acetaminophen", "medicine", "medication", "gave", "dose", "amoxicillin", "motrin"].contains(where: { input.contains($0) })
        let hasFever = input.contains("fever")
        let hasSymptoms = ["cough", "congestion", "rash", "vomit", "throwing up", "diarrhea", "ear infection", "runny nose", "stuffy"].contains(where: { input.contains($0) })

        guard temp != nil || hasMedKeywords || hasFever || hasSymptoms else { return nil }

        var medName: String?
        var medDose: String?
        let medications = ["tylenol", "advil", "ibuprofen", "acetaminophen", "amoxicillin", "motrin", "benadryl", "zyrtec"]
        for med in medications {
            if input.contains(med) {
                medName = med.capitalized
                break
            }
        }
        if let mlMatch = input.range(of: #"\d+\.?\d*\s*ml"#, options: .regularExpression) {
            medDose = String(input[mlMatch])
        }

        var symptomNotes: String?
        if hasSymptoms || hasFever {
            var symptoms: [String] = []
            if hasFever { symptoms.append("fever") }
            let symptomList = ["cough", "congestion", "rash", "vomit", "throwing up", "diarrhea", "ear infection", "runny nose", "stuffy"]
            for s in symptomList {
                if input.contains(s) { symptoms.append(s) }
            }
            symptomNotes = symptoms.joined(separator: ", ")
        }

        return ParsedEvent(
            category: .health, feedingType: nil, amountOz: nil, durationMinutes: nil,
            diaperType: nil, temperatureF: temp, medicationName: medName, medicationDose: medDose,
            weightLbs: nil, heightInches: nil,
            notes: symptomNotes, isTimerStart: false, isTimerStop: false, isSleepStart: false, isSleepEnd: false,
            isCorrection: false, correctionAmount: nil, foodType: nil, isQuery: false, queryTopic: nil
        )
    }

    private static func parsePumping(_ input: String) -> ParsedEvent? {
        guard input.contains("pump") else { return nil }
        return ParsedEvent(
            category: .pumping, feedingType: nil, amountOz: extractOunces(input), durationMinutes: extractMinutes(input),
            diaperType: nil, temperatureF: nil, medicationName: nil, medicationDose: nil,
            weightLbs: nil, heightInches: nil,
            notes: nil, isTimerStart: false, isTimerStop: false, isSleepStart: false, isSleepEnd: false,
            isCorrection: false, correctionAmount: nil, foodType: nil, isQuery: false, queryTopic: nil
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
            isCorrection: false, correctionAmount: nil, foodType: nil, isQuery: false, queryTopic: nil
        )
    }

    private static func parseActivity(_ input: String, raw: String) -> ParsedEvent? {
        let activityMap: [(pattern: String, label: String)] = [
            ("tummy time", "Tummy time"),
            ("tummy", "Tummy time"),
            ("bath", "Bath"),
            ("outing", "Outing"),
            ("walk", "Walk"),
            ("playtime", "Playtime"),
            ("play time", "Playtime"),
            ("playing", "Playtime"),
            ("reading", "Reading"),
            ("read to", "Reading"),
            ("swim", "Swimming"),
            ("park", "Park outing"),
            ("daycare", "Daycare"),
            ("picked up", "Picked up from daycare"),
        ]

        for item in activityMap {
            if input.contains(item.pattern) {
                let duration = extractMinutes(input)
                var notes = item.label
                if let duration {
                    notes += " (\(Int(duration))m)"
                }
                return ParsedEvent(
                    category: .activity, feedingType: nil, amountOz: nil, durationMinutes: duration,
                    diaperType: nil, temperatureF: nil, medicationName: nil, medicationDose: nil,
                    weightLbs: nil, heightInches: nil,
                    notes: notes, isTimerStart: false, isTimerStop: false, isSleepStart: false, isSleepEnd: false,
                    isCorrection: false, correctionAmount: nil, foodType: nil, isQuery: false, queryTopic: nil
                )
            }
        }
        return nil
    }

    private static func parseMilestone(_ input: String, raw: String) -> ParsedEvent? {
        let milestonePatterns = ["milestone", "first time", "first step", "first word", "rolled over", "crawl", "stood up", "smiled", "first tooth", "laughed", "sat up", "clapped"]
        guard milestonePatterns.contains(where: { input.contains($0) }) else { return nil }

        return ParsedEvent(
            category: .milestone, feedingType: nil, amountOz: nil, durationMinutes: nil,
            diaperType: nil, temperatureF: nil, medicationName: nil, medicationDose: nil,
            weightLbs: nil, heightInches: nil,
            notes: raw, isTimerStart: false, isTimerStop: false, isSleepStart: false, isSleepEnd: false,
            isCorrection: false, correctionAmount: nil, foodType: nil, isQuery: false, queryTopic: nil
        )
    }

    private static func makeEvent(
        category: EventCategory,
        feedingType: FeedingType? = nil,
        amountOz: Double? = nil,
        durationMinutes: Double? = nil,
        diaperType: DiaperType? = nil,
        temperatureF: Double? = nil,
        medicationName: String? = nil,
        medicationDose: String? = nil,
        weightLbs: Double? = nil,
        heightInches: Double? = nil,
        notes: String? = nil,
        isTimerStart: Bool = false,
        isTimerStop: Bool = false,
        isSleepStart: Bool = false,
        isSleepEnd: Bool = false,
        isCorrection: Bool = false,
        correctionAmount: Double? = nil,
        foodType: String? = nil,
        isQuery: Bool = false,
        queryTopic: QueryTopic? = nil
    ) -> ParsedEvent {
        ParsedEvent(
            category: category, feedingType: feedingType, amountOz: amountOz, durationMinutes: durationMinutes,
            diaperType: diaperType, temperatureF: temperatureF, medicationName: medicationName, medicationDose: medicationDose,
            weightLbs: weightLbs, heightInches: heightInches,
            notes: notes, isTimerStart: isTimerStart, isTimerStop: isTimerStop, isSleepStart: isSleepStart, isSleepEnd: isSleepEnd,
            isCorrection: isCorrection, correctionAmount: correctionAmount, foodType: foodType, isQuery: isQuery, queryTopic: queryTopic
        )
    }

    static func extractOunces(_ input: String) -> Double? {
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
        if let match = input.range(of: #"(temp|fever)\w*\s+(\d{2,3}\.?\d*)"#, options: .regularExpression) {
            let sub = String(input[match])
            let numStr = sub.components(separatedBy: CharacterSet.letters.union(.whitespaces)).joined()
            if let temp = Double(numStr), temp >= 95.0, temp <= 110.0 {
                return temp
            }
        }
        return nil
    }
}
