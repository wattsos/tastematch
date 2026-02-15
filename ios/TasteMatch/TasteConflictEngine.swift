import Foundation

// MARK: - Taste Conflict Engine (Objects Domain)

enum TasteConflictEngine {

    /// Evaluate conflict between user's Object vector and an item's axis weights.
    static func evaluateObjects(
        userScores: ObjectAxisScores,
        itemAxes: [String: Double]
    ) -> ConflictResult {
        // Build normalized dictionaries
        let userDict = normalizedDict(from: userScores)
        let itemDict = normalizedDict(from: itemAxes)

        // Alignment: cosine similarity mapped to 0..1
        let alignment = clamp01(cosineSimilarity(userDict, itemDict))

        // Drift: L2 distance normalized by sqrt(axis count), clamped to 0..1
        let drift = clamp01(normalizedL2(userDict, itemDict))

        // Conflict axes: top 2 by absolute mismatch
        let axes = topConflictAxes(userDict, itemDict, count: 2)

        return ConflictResult(alignment: alignment, drift: drift, conflictAxes: axes)
    }

    // MARK: - Helpers

    private static func normalizedDict(from scores: ObjectAxisScores) -> [String: Double] {
        var dict: [String: Double] = [:]
        for axis in ObjectAxis.allCases {
            dict[axis.rawValue] = scores.value(for: axis)
        }
        return normalize(dict)
    }

    private static func normalizedDict(from raw: [String: Double]) -> [String: Double] {
        var dict: [String: Double] = [:]
        for axis in ObjectAxis.allCases {
            dict[axis.rawValue] = raw[axis.rawValue, default: 0.0]
        }
        return normalize(dict)
    }

    private static func normalize(_ dict: [String: Double]) -> [String: Double] {
        let mag = sqrt(dict.values.reduce(0) { $0 + $1 * $1 })
        guard mag > 0 else { return dict }
        return dict.mapValues { $0 / mag }
    }

    private static func cosineSimilarity(_ a: [String: Double], _ b: [String: Double]) -> Double {
        var dot = 0.0
        var magA = 0.0
        var magB = 0.0

        for axis in ObjectAxis.allCases {
            let key = axis.rawValue
            let va = a[key, default: 0.0]
            let vb = b[key, default: 0.0]
            dot += va * vb
            magA += va * va
            magB += vb * vb
        }

        let denom = sqrt(magA) * sqrt(magB)
        guard denom > 0 else { return 0.5 }
        // Map from [-1, 1] to [0, 1]
        return (dot / denom + 1.0) / 2.0
    }

    private static func normalizedL2(_ a: [String: Double], _ b: [String: Double]) -> Double {
        let n = Double(ObjectAxis.allCases.count)
        var sumSq = 0.0
        for axis in ObjectAxis.allCases {
            let key = axis.rawValue
            let diff = a[key, default: 0.0] - b[key, default: 0.0]
            sumSq += diff * diff
        }
        // Max possible L2 for unit vectors = 2.0; normalize by sqrt(n) for reasonable 0..1 range
        return sqrt(sumSq) / sqrt(n)
    }

    private static func topConflictAxes(_ user: [String: Double], _ item: [String: Double], count: Int) -> [String] {
        ObjectAxis.allCases
            .map { axis -> (ObjectAxis, Double) in
                let key = axis.rawValue
                let diff = abs(user[key, default: 0.0] - item[key, default: 0.0])
                return (axis, diff)
            }
            .sorted { $0.1 > $1.1 }
            .prefix(count)
            .map { axisDisplayName($0.0) }
    }

    private static func axisDisplayName(_ axis: ObjectAxis) -> String {
        axis.rawValue.capitalized
    }

    private static func clamp01(_ v: Double) -> Double {
        min(1.0, max(0.0, v))
    }
}
