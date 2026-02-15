import Foundation

// MARK: - Object Axis

enum ObjectAxis: String, CaseIterable, Codable {
    case precision       // -1 rough/imprecise → +1 exacting/tight-tolerance
    case patina          // -1 factory-new → +1 aged/worn/wabi-sabi
    case utility         // -1 decorative/display → +1 daily-carry/functional
    case formality       // -1 casual/streetwear → +1 formal/ceremonial
    case subculture      // -1 mainstream → +1 niche/subculture-coded
    case ornament        // -1 austere/blank → +1 embellished/detailed
    case heritage        // -1 contemporary/new-gen → +1 legacy/storied-house
    case technicality    // -1 lo-fi/analog → +1 hi-tech/engineered
    case minimalism      // -1 maximal/layered → +1 stripped/essential
}

// MARK: - Object Axis Scores

struct ObjectAxisScores: Equatable {
    var precision: Double
    var patina: Double
    var utility: Double
    var formality: Double
    var subculture: Double
    var ornament: Double
    var heritage: Double
    var technicality: Double
    var minimalism: Double

    static let zero = ObjectAxisScores(
        precision: 0, patina: 0, utility: 0, formality: 0,
        subculture: 0, ornament: 0, heritage: 0, technicality: 0, minimalism: 0
    )

    func value(for axis: ObjectAxis) -> Double {
        switch axis {
        case .precision:    return precision
        case .patina:       return patina
        case .utility:      return utility
        case .formality:    return formality
        case .subculture:   return subculture
        case .ornament:     return ornament
        case .heritage:     return heritage
        case .technicality: return technicality
        case .minimalism:   return minimalism
        }
    }

    var dominantAxis: ObjectAxis {
        ObjectAxis.allCases.max(by: { abs(value(for: $0)) < abs(value(for: $1)) })!
    }

    var secondaryAxis: ObjectAxis? {
        let sorted = ObjectAxis.allCases.sorted { abs(value(for: $0)) > abs(value(for: $1)) }
        guard sorted.count >= 2, abs(value(for: sorted[1])) > 0.15 else { return nil }
        return sorted[1]
    }
}

// MARK: - Object Vector

struct ObjectVector: Codable, Equatable {
    var weights: [String: Double]

    static let zero = ObjectVector(
        weights: Dictionary(
            uniqueKeysWithValues: ObjectAxis.allCases.map { ($0.rawValue, 0.0) }
        )
    )

    mutating func applySwipe(axis: ObjectAxis, direction: SwipeDirection) {
        let key = axis.rawValue
        let current = weights[key, default: 0.0]
        switch direction {
        case .right: weights[key] = current + 1.0
        case .left:  weights[key] = current - 0.8
        case .up:    weights[key] = current + 2.0
        }
    }

    func normalized() -> ObjectVector {
        var result = self
        for (key, value) in result.weights {
            result.weights[key] = min(1, max(-1, value))
        }
        return result
    }

    static func blend(image: ObjectVector, swipe: ObjectVector, mode: BlendMode) -> ObjectVector {
        let (imageWeight, swipeWeight): (Double, Double) = {
            switch mode {
            case .wantMore: return (0.35, 0.65)
            case .haveLike: return (0.75, 0.25)
            }
        }()

        let allKeys = Set(image.weights.keys).union(swipe.weights.keys)
        var blended: [String: Double] = [:]
        for key in allKeys {
            let i = image.weights[key, default: 0.0]
            let s = swipe.weights[key, default: 0.0]
            blended[key] = i * imageWeight + s * swipeWeight
        }
        return ObjectVector(weights: blended)
    }

    func confidenceLevel(swipeCount: Int) -> String {
        let norm = normalized()
        let sorted = norm.weights.values.sorted(by: >)
        let top1 = sorted.first ?? 0
        let top2 = sorted.dropFirst().first ?? 0
        let separation = top1 - top2

        if swipeCount >= 14 && separation >= 0.15 {
            return "Strong"
        } else if swipeCount >= 7 || confidence > 0.2 {
            return "Developing"
        } else {
            return "Low"
        }
    }

    func stabilityLevel(swipeCount: Int) -> String {
        let norm = normalized()
        let sorted = norm.weights.values.sorted(by: >)
        let top1 = sorted.first ?? 0
        let top2 = sorted.dropFirst().first ?? 0
        let separation = top1 - top2

        if swipeCount >= 14 && separation >= 0.15 {
            return "Stable"
        } else if swipeCount >= 7 || confidence > 0.2 {
            return "Developing"
        } else {
            return "Low"
        }
    }

    var influences: [String] {
        weights
            .filter { $0.value > 0.3 }
            .sorted { $0.value > $1.value }
            .map(\.key)
    }

    var avoids: [String] {
        weights
            .filter { $0.value < -0.2 }
            .sorted { $0.value < $1.value }
            .map(\.key)
    }

    var confidence: Double {
        guard !weights.isEmpty else { return 0 }
        let significant = weights.values.filter { abs($0) > 0.1 }.count
        return Double(significant) / Double(weights.count)
    }
}

// MARK: - Object Axis Mapping

enum ObjectAxisMapping {

    static func computeAxisScores(from vector: ObjectVector) -> ObjectAxisScores {
        let w = vector.normalized().weights
        return ObjectAxisScores(
            precision:    clamp(w[ObjectAxis.precision.rawValue] ?? 0),
            patina:       clamp(w[ObjectAxis.patina.rawValue] ?? 0),
            utility:      clamp(w[ObjectAxis.utility.rawValue] ?? 0),
            formality:    clamp(w[ObjectAxis.formality.rawValue] ?? 0),
            subculture:   clamp(w[ObjectAxis.subculture.rawValue] ?? 0),
            ornament:     clamp(w[ObjectAxis.ornament.rawValue] ?? 0),
            heritage:     clamp(w[ObjectAxis.heritage.rawValue] ?? 0),
            technicality: clamp(w[ObjectAxis.technicality.rawValue] ?? 0),
            minimalism:   clamp(w[ObjectAxis.minimalism.rawValue] ?? 0)
        )
    }

    private static func clamp(_ v: Double) -> Double { min(1, max(-1, v)) }
}
