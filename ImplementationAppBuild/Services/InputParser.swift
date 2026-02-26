import Foundation

nonisolated enum QueryTopic: String, Sendable {
    case weight
    case feeding
    case sleep
    case diaper
    case growth
    case health
    case general
    case medication
    case lastEvent
}

nonisolated struct ParsedEvent: Sendable {
    let category: EventCategory
    let feedingType: FeedingType?
    let amountOz: Double?
    let durationMinutes: Double?
    let diaperType: DiaperType?
    let diaperColor: String?
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
    let customDate: Date?
    let isMultiChild: Bool
    let queryMedicationName: String?
    let queryCategory: EventCategory?
}

struct InputParser {
    static var lastEventCategory: EventCategory?

    static func parse(_ input: String) -> ParsedEvent? {
        var lower = input.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if lower.isEmpty { return nil }

        lower = stripPronouns(lower)

        var cleanedInput = lower
        var customDate: Date?

        if let relative = extractRelativeTime(lower) {
            customDate = relative.date
            cleanedInput = relative.cleanedInput
        } else if var dateResult = extractDate(lower) {
            cleanedInput = dateResult.cleanedInput
            if let timeOfDay = extractTimeOfDay(cleanedInput) {
                let calendar = Calendar.current
                var components = calendar.dateComponents([.year, .month, .day], from: dateResult.date)
                components.hour = timeOfDay.hour
                components.minute = timeOfDay.minute
                customDate = calendar.date(from: components)
                cleanedInput = timeOfDay.cleanedInput
            } else {
                customDate = dateResult.date
            }
        } else if let timeOfDay = extractTimeOfDay(lower) {
            let calendar = Calendar.current
            let now = Date()
            var components = calendar.dateComponents([.year, .month, .day], from: now)
            components.hour = timeOfDay.hour
            components.minute = timeOfDay.minute
            customDate = calendar.date(from: components)
            cleanedInput = timeOfDay.cleanedInput
        }

        let multiChild = detectMultiChild(cleanedInput)

        if let query = parseQuery(cleanedInput) { return query }
        if let correction = parseCorrection(cleanedInput) { return correction }
        if let feeding = parseFeeding(cleanedInput) { trackLast(.feeding); return applyMultiChild(applyDate(feeding, customDate), multiChild) }
        if let sleep = parseSleep(cleanedInput) { trackLast(.sleep); return applyMultiChild(applyDate(sleep, customDate), multiChild) }
        if let diaper = parseDiaper(cleanedInput) { trackLast(.diaper); return applyMultiChild(applyDate(diaper, customDate), multiChild) }
        if let health = parseHealth(cleanedInput) { trackLast(.health); return applyMultiChild(applyDate(health, customDate), multiChild) }
        if let pump = parsePumping(cleanedInput) { trackLast(.pumping); return applyMultiChild(applyDate(pump, customDate), multiChild) }
        if let growth = parseGrowth(cleanedInput) { trackLast(.growth); return applyMultiChild(applyDate(growth, customDate), multiChild) }
        if let activity = parseActivity(cleanedInput, raw: input) { trackLast(.activity); return applyMultiChild(applyDate(activity, customDate), multiChild) }
        if let milestone = parseMilestone(cleanedInput, raw: input) { trackLast(.milestone); return applyMultiChild(applyDate(milestone, customDate), multiChild) }

        return makeEvent(category: .note, notes: input, customDate: customDate)
    }

    private static func trackLast(_ category: EventCategory) {
        lastEventCategory = category
    }

    private static func parseAgain(_ input: String) -> ParsedEvent? {
        let againPatterns = ["again", "same again", "do it again", "repeat", "same thing", "one more", "another one"]
        guard againPatterns.contains(where: { input == $0 || input.hasPrefix($0 + " ") || input.hasSuffix(" " + $0) }) else { return nil }
        guard let lastCategory = lastEventCategory else { return nil }

        switch lastCategory {
        case .feeding:
            return makeEvent(category: .feeding, feedingType: .bottle)
        case .diaper:
            return makeEvent(category: .diaper, diaperType: .wet)
        case .sleep:
            return makeEvent(category: .sleep, isSleepStart: true)
        default:
            return makeEvent(category: lastCategory)
        }
    }

    private static func resolvePronouns(_ input: String) -> String {
        var result = input
        let pronounPatterns = [
            ("she's ", ""), ("he's ", ""), ("she ", ""), ("he ", ""),
            ("her ", ""), ("him ", ""),
        ]
        for (pronoun, _) in pronounPatterns {
            if result.hasPrefix(pronoun) || result.contains(" \(pronoun)") {
                return result
            }
        }
        return result
    }

    private static func detectMultiChild(_ input: String) -> Bool {
        let patterns = ["fed both", "both babies", "both kids", "fed them both", "changed both", "both of them"]
        return patterns.contains(where: { input.contains($0) }) || (input.hasPrefix("both ") || input.contains(" both "))
    }

    private static func applyMultiChild(_ event: ParsedEvent, _ isMulti: Bool) -> ParsedEvent {
        guard isMulti else { return event }
        return ParsedEvent(
            category: event.category, feedingType: event.feedingType, amountOz: event.amountOz,
            durationMinutes: event.durationMinutes, diaperType: event.diaperType, diaperColor: event.diaperColor,
            temperatureF: event.temperatureF,
            medicationName: event.medicationName, medicationDose: event.medicationDose,
            weightLbs: event.weightLbs, heightInches: event.heightInches,
            notes: event.notes, isTimerStart: event.isTimerStart, isTimerStop: event.isTimerStop,
            isSleepStart: event.isSleepStart, isSleepEnd: event.isSleepEnd,
            isCorrection: event.isCorrection, correctionAmount: event.correctionAmount,
            foodType: event.foodType, isQuery: event.isQuery, queryTopic: event.queryTopic,
            customDate: event.customDate, isMultiChild: true,
            queryMedicationName: event.queryMedicationName, queryCategory: event.queryCategory
        )
    }

    private static func applyDate(_ event: ParsedEvent, _ date: Date?) -> ParsedEvent {
        guard let date else { return event }
        return ParsedEvent(
            category: event.category, feedingType: event.feedingType, amountOz: event.amountOz,
            durationMinutes: event.durationMinutes, diaperType: event.diaperType, diaperColor: event.diaperColor,
            temperatureF: event.temperatureF,
            medicationName: event.medicationName, medicationDose: event.medicationDose,
            weightLbs: event.weightLbs, heightInches: event.heightInches,
            notes: event.notes, isTimerStart: event.isTimerStart, isTimerStop: event.isTimerStop,
            isSleepStart: event.isSleepStart, isSleepEnd: event.isSleepEnd,
            isCorrection: event.isCorrection, correctionAmount: event.correctionAmount,
            foodType: event.foodType, isQuery: event.isQuery, queryTopic: event.queryTopic,
            customDate: date, isMultiChild: event.isMultiChild,
            queryMedicationName: event.queryMedicationName, queryCategory: event.queryCategory
        )
    }

    private static func parseQuery(_ input: String) -> ParsedEvent? {
        let questionIndicators = ["how", "when", "what", "how's", "how is", "how are", "show me", "tell me about", "any insight", "summary", "trend", "doing", "status", "report", "update", "average", "pattern", "last time", "last "]
        let hasQuestion = questionIndicators.contains(where: { input.hasPrefix($0) }) || input.contains("?") || input.contains("how is") || input.contains("how's") || input.contains("last time") || (input.hasPrefix("last ") && !input.contains("last night"))
        guard hasQuestion else { return nil }

        let hasActionWord = ["fed", "feed ", "nursed", "bottle ", "diaper change", "log ", "start ", "stop "].contains(where: { input.contains($0) })
        if hasActionWord && !input.contains("?") && !input.contains("when") && !input.contains("last") { return nil }

        let medications = ["tylenol", "advil", "ibuprofen", "acetaminophen", "amoxicillin", "motrin", "benadryl", "zyrtec"]
        var queriedMedName: String?
        for med in medications {
            if input.contains(med) {
                queriedMedName = med.capitalized
                break
            }
        }

        if queriedMedName != nil {
            return ParsedEvent(
                category: .note, feedingType: nil, amountOz: nil, durationMinutes: nil,
                diaperType: nil, diaperColor: nil, temperatureF: nil, medicationName: nil, medicationDose: nil,
                weightLbs: nil, heightInches: nil,
                notes: nil, isTimerStart: false, isTimerStop: false, isSleepStart: false, isSleepEnd: false,
                isCorrection: false, correctionAmount: nil, foodType: nil, isQuery: true, queryTopic: .medication,
                customDate: nil, isMultiChild: false, queryMedicationName: queriedMedName, queryCategory: nil
            )
        }

        var queriedCategory: EventCategory?
        if input.contains("last feed") || input.contains("last bottle") || input.contains("last nurse") || (input.contains("when") && input.contains("fed")) || (input.contains("when") && input.contains("eat")) {
            queriedCategory = .feeding
        } else if input.contains("last diaper") || (input.contains("when") && input.contains("diaper")) || (input.contains("when") && input.contains("change")) {
            queriedCategory = .diaper
        } else if input.contains("last sleep") || input.contains("last nap") || (input.contains("when") && input.contains("sleep")) || (input.contains("when") && input.contains("nap")) {
            queriedCategory = .sleep
        }

        if queriedCategory != nil {
            return ParsedEvent(
                category: .note, feedingType: nil, amountOz: nil, durationMinutes: nil,
                diaperType: nil, diaperColor: nil, temperatureF: nil, medicationName: nil, medicationDose: nil,
                weightLbs: nil, heightInches: nil,
                notes: nil, isTimerStart: false, isTimerStop: false, isSleepStart: false, isSleepEnd: false,
                isCorrection: false, correctionAmount: nil, foodType: nil, isQuery: true, queryTopic: .lastEvent,
                customDate: nil, isMultiChild: false, queryMedicationName: nil, queryCategory: queriedCategory
            )
        }

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
            diaperType: nil, diaperColor: nil, temperatureF: nil, medicationName: nil, medicationDose: nil,
            weightLbs: nil, heightInches: nil,
            notes: nil, isTimerStart: false, isTimerStop: false, isSleepStart: false, isSleepEnd: false,
            isCorrection: false, correctionAmount: nil, foodType: nil, isQuery: true, queryTopic: topic,
            customDate: nil, isMultiChild: false, queryMedicationName: nil, queryCategory: nil
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
            diaperType: nil, diaperColor: nil, temperatureF: nil, medicationName: nil, medicationDose: nil,
            weightLbs: nil, heightInches: nil,
            notes: nil, isTimerStart: false, isTimerStop: false, isSleepStart: false, isSleepEnd: false,
            isCorrection: true, correctionAmount: amount, foodType: nil, isQuery: false, queryTopic: nil,
            customDate: nil, isMultiChild: false, queryMedicationName: nil, queryCategory: nil
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
            diaperType: nil, diaperColor: nil, temperatureF: nil, medicationName: nil, medicationDose: nil,
            weightLbs: nil, heightInches: nil,
            notes: nil, isTimerStart: false, isTimerStop: false, isSleepStart: false, isSleepEnd: false,
            isCorrection: false, correctionAmount: nil, foodType: foodType, isQuery: false, queryTopic: nil,
            customDate: nil, isMultiChild: false, queryMedicationName: nil, queryCategory: nil
        )
    }

    private static func parseSleep(_ input: String) -> ParsedEvent? {
        let sleepStartPatterns = ["asleep", "sleeping", "down for", "nap", "put down", "went to sleep", "bedtime", "fell asleep", "going to sleep", "night night", "lights out"]
        let sleepEndPatterns = ["woke", "awake", "up now", "just woke", "she's up", "he's up", "waking", "woken", "got up", "morning", "wake up", "wakes up", "he woke", "she woke", "he wake", "she wake", "never mind", "wake"]

        if sleepEndPatterns.contains(where: { input.contains($0) }) {
            return makeEvent(category: .sleep, isTimerStop: true, isSleepEnd: true, isQuery: false)
        }

        if sleepStartPatterns.contains(where: { input.contains($0) }) || input == "sleep" {
            return ParsedEvent(
                category: .sleep, feedingType: nil, amountOz: nil, durationMinutes: extractMinutes(input),
                diaperType: nil, diaperColor: nil, temperatureF: nil, medicationName: nil, medicationDose: nil,
                weightLbs: nil, heightInches: nil,
                notes: nil, isTimerStart: true, isTimerStop: false, isSleepStart: true, isSleepEnd: false,
                isCorrection: false, correctionAmount: nil, foodType: nil, isQuery: false, queryTopic: nil,
                customDate: nil, isMultiChild: false, queryMedicationName: nil, queryCategory: nil
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

        var detectedColor: String?
        let colors = ["green", "yellow", "brown", "black", "tarry", "mucus", "blood", "red"]
        for color in colors {
            if input.contains(color) {
                detectedColor = color
                break
            }
        }

        return ParsedEvent(
            category: .diaper, feedingType: nil, amountOz: nil, durationMinutes: nil,
            diaperType: dType, diaperColor: detectedColor,
            temperatureF: nil, medicationName: nil, medicationDose: nil,
            weightLbs: nil, heightInches: nil,
            notes: nil, isTimerStart: false, isTimerStop: false, isSleepStart: false, isSleepEnd: false,
            isCorrection: false, correctionAmount: nil, foodType: nil, isQuery: false, queryTopic: nil,
            customDate: nil, isMultiChild: false, queryMedicationName: nil, queryCategory: nil
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
            diaperType: nil, diaperColor: nil, temperatureF: temp, medicationName: medName, medicationDose: medDose,
            weightLbs: nil, heightInches: nil,
            notes: symptomNotes, isTimerStart: false, isTimerStop: false, isSleepStart: false, isSleepEnd: false,
            isCorrection: false, correctionAmount: nil, foodType: nil, isQuery: false, queryTopic: nil,
            customDate: nil, isMultiChild: false, queryMedicationName: nil, queryCategory: nil
        )
    }

    private static func parsePumping(_ input: String) -> ParsedEvent? {
        guard input.contains("pump") else { return nil }
        return ParsedEvent(
            category: .pumping, feedingType: nil, amountOz: extractOunces(input), durationMinutes: extractMinutes(input),
            diaperType: nil, diaperColor: nil, temperatureF: nil, medicationName: nil, medicationDose: nil,
            weightLbs: nil, heightInches: nil,
            notes: nil, isTimerStart: false, isTimerStop: false, isSleepStart: false, isSleepEnd: false,
            isCorrection: false, correctionAmount: nil, foodType: nil, isQuery: false, queryTopic: nil,
            customDate: nil, isMultiChild: false, queryMedicationName: nil, queryCategory: nil
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
            diaperType: nil, diaperColor: nil, temperatureF: nil, medicationName: nil, medicationDose: nil,
            weightLbs: weight, heightInches: height,
            notes: nil, isTimerStart: false, isTimerStop: false, isSleepStart: false, isSleepEnd: false,
            isCorrection: false, correctionAmount: nil, foodType: nil, isQuery: false, queryTopic: nil,
            customDate: nil, isMultiChild: false, queryMedicationName: nil, queryCategory: nil
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
                    diaperType: nil, diaperColor: nil, temperatureF: nil, medicationName: nil, medicationDose: nil,
                    weightLbs: nil, heightInches: nil,
                    notes: notes, isTimerStart: false, isTimerStop: false, isSleepStart: false, isSleepEnd: false,
                    isCorrection: false, correctionAmount: nil, foodType: nil, isQuery: false, queryTopic: nil,
                    customDate: nil, isMultiChild: false, queryMedicationName: nil, queryCategory: nil
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
            diaperType: nil, diaperColor: nil, temperatureF: nil, medicationName: nil, medicationDose: nil,
            weightLbs: nil, heightInches: nil,
            notes: raw, isTimerStart: false, isTimerStop: false, isSleepStart: false, isSleepEnd: false,
            isCorrection: false, correctionAmount: nil, foodType: nil, isQuery: false, queryTopic: nil,
            customDate: nil, isMultiChild: false, queryMedicationName: nil, queryCategory: nil
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
        queryTopic: QueryTopic? = nil,
        customDate: Date? = nil
    ) -> ParsedEvent {
        ParsedEvent(
            category: category, feedingType: feedingType, amountOz: amountOz, durationMinutes: durationMinutes,
            diaperType: diaperType, diaperColor: nil, temperatureF: temperatureF, medicationName: medicationName, medicationDose: medicationDose,
            weightLbs: weightLbs, heightInches: heightInches,
            notes: notes, isTimerStart: isTimerStart, isTimerStop: isTimerStop, isSleepStart: isSleepStart, isSleepEnd: isSleepEnd,
            isCorrection: isCorrection, correctionAmount: correctionAmount, foodType: foodType, isQuery: isQuery, queryTopic: queryTopic,
            customDate: customDate, isMultiChild: false, queryMedicationName: nil, queryCategory: nil
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

    private static func extractDate(_ input: String) -> (date: Date, cleanedInput: String)? {
        let calendar = Calendar.current
        let now = Date()

        if let match = input.range(of: #"(\d+)\s*(min|minute|minutes)\s*(ago|before)"#, options: .regularExpression) {
            let sub = String(input[match])
            if let numMatch = sub.range(of: #"\d+"#, options: .regularExpression),
               let mins = Int(sub[numMatch]), mins > 0, mins <= 1440 {
                let date = now.addingTimeInterval(-Double(mins) * 60)
                let cleaned = input.replacingOccurrences(of: sub, with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                return (date, cleaned)
            }
        }

        if let match = input.range(of: #"(\d+\.?\d*)\s*(h|hr|hrs|hour|hours)\s*(ago|before)"#, options: .regularExpression) {
            let sub = String(input[match])
            if let numMatch = sub.range(of: #"\d+\.?\d*"#, options: .regularExpression),
               let hours = Double(sub[numMatch]), hours > 0, hours <= 48 {
                let date = now.addingTimeInterval(-hours * 3600)
                let cleaned = input.replacingOccurrences(of: sub, with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                return (date, cleaned)
            }
        }

        let hourAgoPatterns: [(pattern: String, hours: Double)] = [
            ("an hour ago", 1), ("a half hour ago", 0.5), ("half an hour ago", 0.5),
            ("an hour before", 1), ("a half hour before", 0.5), ("half an hour before", 0.5),
        ]
        for phrase in hourAgoPatterns {
            if input.contains(phrase.pattern) {
                let date = now.addingTimeInterval(-phrase.hours * 3600)
                let cleaned = input.replacingOccurrences(of: phrase.pattern, with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                return (date, cleaned)
            }
        }

        let relativePhrases: [(pattern: String, daysAgo: Int)] = [
            ("the day before yesterday", 2),
            ("day before yesterday", 2),
            ("2 days ago", 2),
            ("two days ago", 2),
            ("2 days before", 2),
            ("two days before", 2),
            ("3 days ago", 3),
            ("three days ago", 3),
            ("3 days before", 3),
            ("three days before", 3),
            ("4 days ago", 4),
            ("four days ago", 4),
            ("4 days before", 4),
            ("four days before", 4),
            ("5 days ago", 5),
            ("five days ago", 5),
            ("5 days before", 5),
            ("five days before", 5),
            ("6 days ago", 6),
            ("six days ago", 6),
            ("6 days before", 6),
            ("six days before", 6),
            ("7 days ago", 7),
            ("seven days ago", 7),
            ("a week ago", 7),
            ("last week", 7),
            ("yesterday", 1),
            ("last night", 1),
            ("this morning", 0),
        ]

        for phrase in relativePhrases {
            if input.contains(phrase.pattern) {
                let cleaned = input.replacingOccurrences(of: phrase.pattern, with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                if let date = calendar.date(byAdding: .day, value: -phrase.daysAgo, to: calendar.startOfDay(for: now)) {
                    let timeHour = extractTimeOfDay(cleaned) ?? 12
                    let targetDate = calendar.date(byAdding: .hour, value: timeHour, to: date)!
                    let finalCleaned = stripTimeOfDay(cleaned)
                    return (targetDate, finalCleaned)
                }
            }
        }

        if let match = input.range(of: #"(\d+)\s*days?\s*(ago|before)"#, options: .regularExpression) {
            let sub = String(input[match])
            if let numMatch = sub.range(of: #"\d+"#, options: .regularExpression),
               let days = Int(sub[numMatch]), days > 0, days <= 365 {
                let cleaned = input.replacingOccurrences(of: sub, with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                if let date = calendar.date(byAdding: .day, value: -days, to: calendar.startOfDay(for: now)) {
                    let timeHour = extractTimeOfDay(cleaned) ?? 12
                    let targetDate = calendar.date(byAdding: .hour, value: timeHour, to: date)!
                    let finalCleaned = stripTimeOfDay(cleaned)
                    return (targetDate, finalCleaned)
                }
            }
        }

        let dateFormats = ["M/d/yyyy", "M/d/yy", "M/d", "MM/dd/yyyy", "MM/dd", "MMM d", "MMMM d", "MMM d, yyyy", "MMMM d, yyyy"]
        for format in dateFormats {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = format
            let tokens = input.components(separatedBy: .whitespaces)
            for i in 0..<tokens.count {
                for length in 1...min(4, tokens.count - i) {
                    let candidate = tokens[i..<(i+length)].joined(separator: " ")
                    let cleanCandidate = candidate.trimmingCharacters(in: CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "/,")).inverted)
                    if let parsed = formatter.date(from: cleanCandidate) {
                        var dateComponents = calendar.dateComponents([.month, .day], from: parsed)
                        if !format.contains("y") {
                            dateComponents.year = calendar.component(.year, from: now)
                        } else {
                            dateComponents.year = calendar.component(.year, from: parsed)
                        }
                        dateComponents.hour = 12
                        if let finalDate = calendar.date(from: dateComponents), finalDate <= now {
                            let cleaned = input.replacingOccurrences(of: candidate, with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                            return (finalDate, cleaned)
                        }
                    }
                }
            }
        }

        return nil
    }

    private static func extractTimeOfDay(_ input: String) -> Int? {
        if input.contains("at noon") || input.contains("around noon") { return 12 }
        if input.contains("at midnight") || input.contains("around midnight") { return 0 }

        if let match = input.range(of: #"at\s+(\d{1,2})(?::(\d{2}))?\s*(am|pm|a\.m\.|p\.m\.)"#, options: .regularExpression) {
            let sub = String(input[match])
            if let hourMatch = sub.range(of: #"\d{1,2}"#, options: .regularExpression) {
                var hour = Int(sub[hourMatch]) ?? 12
                let isPM = sub.contains("pm") || sub.contains("p.m.")
                let isAM = sub.contains("am") || sub.contains("a.m.")
                if isPM && hour < 12 { hour += 12 }
                if isAM && hour == 12 { hour = 0 }
                return hour
            }
        }

        if let match = input.range(of: #"at\s+(\d{1,2})\s*(am|pm|a\.m\.|p\.m\.)"#, options: .regularExpression) {
            let sub = String(input[match])
            if let hourMatch = sub.range(of: #"\d{1,2}"#, options: .regularExpression) {
                var hour = Int(sub[hourMatch]) ?? 12
                let isPM = sub.contains("pm") || sub.contains("p.m.")
                let isAM = sub.contains("am") || sub.contains("a.m.")
                if isPM && hour < 12 { hour += 12 }
                if isAM && hour == 12 { hour = 0 }
                return hour
            }
        }

        let namedTimes: [(String, Int)] = [
            ("in the morning", 8), ("in the evening", 18), ("in the afternoon", 14),
            ("this morning", 8), ("this evening", 18), ("this afternoon", 14),
        ]
        for (phrase, hour) in namedTimes {
            if input.contains(phrase) { return hour }
        }

        return nil
    }

    private static func stripTimeOfDay(_ input: String) -> String {
        var result = input
        let patterns = [
            #"at\s+\d{1,2}(?::\d{2})?\s*(?:am|pm|a\.m\.|p\.m\.)"#,
            "at noon", "at midnight", "around noon", "around midnight",
            "in the morning", "in the evening", "in the afternoon",
            "this morning", "this evening", "this afternoon",
        ]
        for pattern in patterns {
            if pattern.contains("\\d") {
                if let range = result.range(of: pattern, options: .regularExpression) {
                    result = result.replacingCharacters(in: range, with: "")
                }
            } else {
                result = result.replacingOccurrences(of: pattern, with: "")
            }
        }
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
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

    private static func extractRelativeTime(_ input: String) -> (date: Date, cleanedInput: String)? {
        let calendar = Calendar.current
        let now = Date()

        if let match = input.range(of: #"(\d+)\s*(min|minutes?|m\b)\s*(ago|before)"#, options: .regularExpression) {
            let sub = String(input[match])
            if let numMatch = sub.range(of: #"\d+"#, options: .regularExpression),
               let mins = Int(sub[numMatch]), mins > 0, mins <= 1440 {
                if let date = calendar.date(byAdding: .minute, value: -mins, to: now) {
                    let cleaned = input.replacingOccurrences(of: sub, with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                    return (date, cleaned)
                }
            }
        }
        if let match = input.range(of: #"(an?\s+)?(\d+)\s*(h|hr|hours?)\s*(ago|before)"#, options: .regularExpression) {
            let sub = String(input[match])
            if let numMatch = sub.range(of: #"\d+"#, options: .regularExpression),
               let hours = Int(sub[numMatch]), hours > 0, hours <= 168 {
                if let date = calendar.date(byAdding: .hour, value: -hours, to: now) {
                    let cleaned = input.replacingOccurrences(of: sub, with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                    return (date, cleaned)
                }
            }
        }
        if input.contains("an hour ago") || input.contains("a hour ago") {
            let cleaned = input.replacingOccurrences(of: "an hour ago", with: "").replacingOccurrences(of: "a hour ago", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            if let date = calendar.date(byAdding: .hour, value: -1, to: now) {
                return (date, cleaned)
            }
        }
        return nil
    }

    private static func extractTimeOfDay(_ input: String) -> (hour: Int, minute: Int, cleanedInput: String)? {
        if input.contains("at noon") || input.contains("at 12 noon") {
            let cleaned = input.replacingOccurrences(of: "at noon", with: "").replacingOccurrences(of: "at 12 noon", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            return (12, 0, cleaned)
        }
        if input.contains("at midnight") {
            let cleaned = input.replacingOccurrences(of: "at midnight", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            return (0, 0, cleaned)
        }
        if let match = input.range(of: #"at\s+(\d{1,2})(?::(\d{2}))?\s*(am|pm)"#, options: .regularExpression) {
            let sub = String(input[match])
            let hourMatch = sub.range(of: #"\d{1,2}"#, options: .regularExpression)
            let minuteMatch = sub.range(of: #":\d{2}"#, options: .regularExpression)
            let ampmMatch = sub.range(of: #"am|pm"#, options: .regularExpression)
            guard let hrRange = hourMatch, let ampmRange = ampmMatch else { return nil }
            let hrStr = String(sub[hrRange])
            let hour = Int(hrStr) ?? 12
            var minute = 0
            if let minRange = minuteMatch {
                let minStr = String(sub[minRange]).dropFirst()
                minute = Int(String(minStr)) ?? 0
            }
            let ampm = String(sub[ampmRange])
            var h = hour
            if ampm == "pm" && hour < 12 { h = hour + 12 }
            else if ampm == "am" && hour == 12 { h = 0 }
            let cleaned = input.replacingOccurrences(of: sub, with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            return (h, minute, cleaned)
        }
        if let match = input.range(of: #"at\s+(\d{1,2}):(\d{2})"#, options: .regularExpression) {
            let sub = String(input[match])
            let parts = sub.components(separatedBy: ":")
            guard parts.count >= 2,
                  let h = Int(parts[0].filter { $0.isNumber }),
                  let m = Int(parts[1].filter { $0.isNumber }), h < 24, m < 60 else { return nil }
            let cleaned = input.replacingOccurrences(of: sub, with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            return (h, m, cleaned)
        }
        return nil
    }

    private static func stripPronouns(_ input: String) -> String {
        let pronouns = [" she ", " he ", " her ", " him "]
        var result = input
        for p in pronouns {
            result = result.replacingOccurrences(of: p, with: " ")
        }
        if result.hasPrefix("she ") { result = String(result.dropFirst(4)) }
        if result.hasPrefix("he ") { result = String(result.dropFirst(3)) }
        if result.hasPrefix("her ") { result = String(result.dropFirst(4)) }
        if result.hasPrefix("him ") { result = String(result.dropFirst(4)) }
        return result.components(separatedBy: .whitespaces).filter { !$0.isEmpty }.joined(separator: " ")
    }

    static func isRepeatRequest(_ input: String) -> Bool {
        let lower = input.lowercased().trimmingCharacters(in: .whitespaces)
        let phrases = ["again", "same again", "same", "repeat", "do it again", "one more", "same thing"]
        return phrases.contains(lower)
    }
}
