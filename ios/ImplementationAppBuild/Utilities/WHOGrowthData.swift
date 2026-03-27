import Foundation

struct WHOPercentileResult {
    let percentile: Int
    let description: String
}

enum WHOGrowthData {
    private static let weightForAgeBoys: [(month: Int, p3: Double, p15: Double, p50: Double, p85: Double, p97: Double)] = [
        (0,  5.5,  6.4,  7.3,  8.6,  9.5),
        (1,  7.5,  8.6,  9.9, 11.2, 12.8),
        (2,  9.5, 10.8, 12.3, 13.9, 15.7),
        (3, 11.0, 12.6, 14.1, 15.9, 17.6),
        (4, 12.3, 13.7, 15.4, 17.2, 19.2),
        (5, 13.2, 14.8, 16.5, 18.5, 20.5),
        (6, 14.1, 15.7, 17.4, 19.4, 21.6),
        (7, 14.9, 16.4, 18.3, 20.3, 22.5),
        (8, 15.4, 17.0, 18.9, 21.0, 23.4),
        (9, 15.7, 17.4, 19.6, 21.8, 24.0),
        (10, 16.1, 17.9, 20.1, 22.4, 24.7),
        (11, 16.5, 18.3, 20.5, 22.9, 25.2),
        (12, 17.0, 19.0, 21.2, 23.8, 26.0),
        (15, 17.9, 20.0, 22.5, 25.3, 27.8),
        (18, 19.4, 21.6, 24.0, 26.9, 29.8),
        (21, 20.5, 22.9, 25.5, 28.7, 31.7),
        (24, 21.4, 23.8, 26.9, 30.0, 33.3),
    ]

    private static let weightForAgeGirls: [(month: Int, p3: Double, p15: Double, p50: Double, p85: Double, p97: Double)] = [
        (0,  5.1,  5.9,  7.1,  8.1,  9.1),
        (1,  7.1,  8.0,  9.4, 10.6, 11.8),
        (2,  8.8,  9.9, 11.3, 12.8, 14.3),
        (3, 10.2, 11.4, 12.8, 14.6, 16.2),
        (4, 11.2, 12.6, 14.1, 15.9, 17.6),
        (5, 12.1, 13.5, 15.2, 17.0, 18.9),
        (6, 12.9, 14.3, 16.1, 18.0, 20.1),
        (7, 13.5, 15.0, 16.8, 18.8, 21.0),
        (8, 14.0, 15.6, 17.5, 19.6, 21.8),
        (9, 14.5, 16.1, 18.1, 20.2, 22.5),
        (10, 14.9, 16.5, 18.6, 20.8, 23.1),
        (11, 15.2, 16.9, 19.0, 21.3, 23.7),
        (12, 15.7, 17.4, 19.6, 22.0, 24.4),
        (15, 16.6, 18.5, 20.9, 23.5, 26.2),
        (18, 17.9, 20.0, 22.5, 25.3, 28.2),
        (21, 19.0, 21.2, 23.9, 26.9, 30.0),
        (24, 20.1, 22.4, 25.3, 28.6, 32.0),
    ]

    static func percentile(weightLbs: Double, ageMonths: Int, gender: BabyGender = .boy) -> WHOPercentileResult {
        let data = gender == .girl ? weightForAgeGirls : weightForAgeBoys
        return calculatePercentile(weightLbs: weightLbs, ageMonths: ageMonths, data: data)
    }

    private static func calculatePercentile(
        weightLbs: Double,
        ageMonths: Int,
        data: [(month: Int, p3: Double, p15: Double, p50: Double, p85: Double, p97: Double)]
    ) -> WHOPercentileResult {
        let clampedAge = max(0, min(24, ageMonths))

        var lower = data[0]
        var upper = data[0]
        for i in 0..<data.count {
            if data[i].month <= clampedAge {
                lower = data[i]
            }
            if data[i].month >= clampedAge {
                upper = data[i]
                break
            }
        }

        let p3: Double
        let p15: Double
        let p50: Double
        let p85: Double
        let p97: Double

        if lower.month == upper.month {
            p3 = lower.p3; p15 = lower.p15; p50 = lower.p50; p85 = lower.p85; p97 = lower.p97
        } else {
            let ratio = Double(clampedAge - lower.month) / Double(upper.month - lower.month)
            p3 = lower.p3 + ratio * (upper.p3 - lower.p3)
            p15 = lower.p15 + ratio * (upper.p15 - lower.p15)
            p50 = lower.p50 + ratio * (upper.p50 - lower.p50)
            p85 = lower.p85 + ratio * (upper.p85 - lower.p85)
            p97 = lower.p97 + ratio * (upper.p97 - lower.p97)
        }

        let percentile: Int
        let desc: String

        if weightLbs < p3 {
            percentile = 1
            desc = "below the 3rd percentile (below average)"
        } else if weightLbs < p15 {
            percentile = interpolate(value: weightLbs, low: p3, high: p15, pLow: 3, pHigh: 15)
            desc = "between the 3rd and 15th percentile"
        } else if weightLbs < p50 {
            percentile = interpolate(value: weightLbs, low: p15, high: p50, pLow: 15, pHigh: 50)
            desc = "between the 15th and 50th percentile"
        } else if weightLbs < p85 {
            percentile = interpolate(value: weightLbs, low: p50, high: p85, pLow: 50, pHigh: 85)
            desc = "between the 50th and 85th percentile"
        } else if weightLbs < p97 {
            percentile = interpolate(value: weightLbs, low: p85, high: p97, pLow: 85, pHigh: 97)
            desc = "between the 85th and 97th percentile"
        } else {
            percentile = 99
            desc = "above the 97th percentile"
        }

        return WHOPercentileResult(percentile: percentile, description: desc)
    }

    private static func interpolate(value: Double, low: Double, high: Double, pLow: Int, pHigh: Int) -> Int {
        guard high > low else { return pLow }
        let ratio = (value - low) / (high - low)
        return pLow + Int(ratio * Double(pHigh - pLow))
    }
}
