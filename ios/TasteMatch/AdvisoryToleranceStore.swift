import Foundation

// MARK: - Advisory Tolerance Store

enum AdvisoryToleranceStore {
    private static let toleranceKey = "burgundy.advisoryTolerance"
    private static let lastAdjustedKey = "burgundy.advisoryToleranceLastAdjusted"
    private static let bounds: ClosedRange<Double> = -0.15...0.15

    static var tolerance: Double {
        get { UserDefaults.standard.double(forKey: toleranceKey) }
        set {
            let clamped = min(bounds.upperBound, max(bounds.lowerBound, newValue))
            UserDefaults.standard.set(clamped, forKey: toleranceKey)
        }
    }

    /// Adjusts tolerance based on weekly advisory stats. Runs at most once per day.
    static func adjustIfNeeded() {
        let now = Date()
        if let last = UserDefaults.standard.object(forKey: lastAdjustedKey) as? Date,
           now.timeIntervalSince(last) < 86400 {
            return
        }

        let stats = AdvisorySignalStore.weeklyStats()
        var delta = 0.0
        if stats.overrides >= 3 { delta += 0.03 }
        if stats.nonProceeds >= 5 { delta -= 0.03 }

        if delta != 0 {
            tolerance += delta
        }

        UserDefaults.standard.set(now, forKey: lastAdjustedKey)
    }

    /// Reset for testing.
    static func reset() {
        UserDefaults.standard.removeObject(forKey: toleranceKey)
        UserDefaults.standard.removeObject(forKey: lastAdjustedKey)
    }
}
