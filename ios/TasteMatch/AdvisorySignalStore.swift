import Foundation

// MARK: - Advisory Signal

struct AdvisorySignal: Codable {
    let timestamp: Date
    let action: String   // "shown", "proceeded", "saved", "intentionalShift"
    let verdict: String  // "green", "yellow", "red"
    let skuId: String
}

// MARK: - Weekly Stats

struct AdvisoryWeeklyStats {
    let nearMisses: Int        // red shown but not proceeded
    let overrides: Int         // red proceeded
    let intentionalShifts: Int // intentionalShift actions
    let nonProceeds: Int       // shown(yellow+red) - proceeded(yellow+red)
}

// MARK: - Advisory Signal Store

enum AdvisorySignalStore {
    private static let key = "burgundy.advisorySignals"

    static func record(_ signal: AdvisorySignal) {
        var signals = loadAll()
        signals.append(signal)
        // Prune older than 14 days
        let cutoff = Date().addingTimeInterval(-14 * 86400)
        signals = signals.filter { $0.timestamp > cutoff }
        save(signals)
    }

    static func weeklyStats() -> AdvisoryWeeklyStats {
        let cutoff = Date().addingTimeInterval(-7 * 86400)
        let recent = loadAll().filter { $0.timestamp > cutoff }

        let shownRed = recent.filter { $0.action == "shown" && $0.verdict == "red" }.count
        let proceededRed = recent.filter { $0.action == "proceeded" && $0.verdict == "red" }.count
        let shownYellowRed = recent.filter {
            $0.action == "shown" && ($0.verdict == "red" || $0.verdict == "yellow")
        }.count
        let proceededYellowRed = recent.filter {
            $0.action == "proceeded" && ($0.verdict == "red" || $0.verdict == "yellow")
        }.count
        let shifts = recent.filter { $0.action == "intentionalShift" }.count

        return AdvisoryWeeklyStats(
            nearMisses: max(0, shownRed - proceededRed),
            overrides: proceededRed,
            intentionalShifts: shifts,
            nonProceeds: max(0, shownYellowRed - proceededYellowRed)
        )
    }

    static func clearAll() {
        UserDefaults.standard.removeObject(forKey: key)
    }

    // MARK: - Private

    private static func loadAll() -> [AdvisorySignal] {
        guard let data = UserDefaults.standard.data(forKey: key) else { return [] }
        return (try? JSONDecoder().decode([AdvisorySignal].self, from: data)) ?? []
    }

    private static func save(_ signals: [AdvisorySignal]) {
        if let data = try? JSONEncoder().encode(signals) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
