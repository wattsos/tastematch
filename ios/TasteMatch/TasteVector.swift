import Foundation

// MARK: - Swipe Direction

enum SwipeDirection: String, Codable {
    case left, right, up
}

// MARK: - Blend Mode

enum BlendMode: String, Codable {
    /// User wants more discovery — swipe vector dominates (0.65 swipe, 0.35 image)
    case wantMore
    /// User already likes their space — image vector dominates (0.75 image, 0.25 swipe)
    case haveLike
}

// MARK: - Taste Vector

struct TasteVector: Codable, Equatable {
    var weights: [String: Double]

    static let zero = TasteVector(
        weights: Dictionary(
            uniqueKeysWithValues: TasteEngine.CanonicalTag.allCases.map { (String(describing: $0), 0.0) }
        )
    )

    mutating func applySwipe(tag: String, direction: SwipeDirection) {
        let current = weights[tag, default: 0.0]
        switch direction {
        case .right: weights[tag] = current + 1.0
        case .left:  weights[tag] = current - 0.8
        case .up:    weights[tag] = current + 2.0
        }
    }

    func normalized() -> TasteVector {
        var result = self
        for (key, value) in result.weights {
            result.weights[key] = min(1, max(-1, value))
        }
        return result
    }

    static func blend(image: TasteVector, swipe: TasteVector, mode: BlendMode) -> TasteVector {
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
        return TasteVector(weights: blended)
    }

    /// Generate 3 deterministic taste variants from this vector.
    func generateVariants() -> [TasteVariant] {
        let sorted = weights.sorted { $0.value > $1.value }
        guard let top = sorted.first else { return [] }
        let second = sorted.dropFirst().first

        var variants: [TasteVariant] = []

        // Variant A: boost top tag by +20%
        var aWeights = weights
        aWeights[top.key] = min(1.0, top.value * 1.2)
        let topScores = AxisMapping.computeAxisScores(from: TasteVector(weights: aWeights))
        let topAxis = topScores.dominantAxis
        let topWord = AxisPresentation.influenceWord(axis: topAxis, positive: topScores.value(for: topAxis) >= 0)
        let aLabel = "More \(topWord)"
        variants.append(TasteVariant(
            label: aLabel,
            subtitle: "Leaning further into your strongest signal",
            vector: TasteVector(weights: aWeights)
        ))

        // Variant B: shift emphasis — top × 0.85, second × 1.15
        if let sec = second {
            var bWeights = weights
            bWeights[top.key] = top.value * 0.85
            bWeights[sec.key] = min(1.0, sec.value * 1.15)
            let secScores = AxisMapping.computeAxisScores(from: TasteVector(weights: bWeights))
            let secAxis = secScores.dominantAxis
            let secWord = AxisPresentation.influenceWord(axis: secAxis, positive: secScores.value(for: secAxis) >= 0)
            let bLabel = "\(secWord) Shift"
            variants.append(TasteVariant(
                label: bLabel,
                subtitle: "Rebalancing toward your secondary thread",
                vector: TasteVector(weights: bWeights)
            ))
        }

        // Variant C: flip avoids — tags < -0.2 get value * -0.5
        var cWeights = weights
        for (key, value) in cWeights where value < -0.2 {
            cWeights[key] = value * -0.5
        }
        variants.append(TasteVariant(
            label: "Contrast Mix",
            subtitle: "Inverting what you usually avoid",
            vector: TasteVector(weights: cWeights)
        ))

        return variants
    }

    /// Tags with weight > 0.3, sorted descending by weight
    var influences: [String] {
        weights
            .filter { $0.value > 0.3 }
            .sorted { $0.value > $1.value }
            .map(\.key)
    }

    /// Tags with weight < -0.2, sorted ascending by weight
    var avoids: [String] {
        weights
            .filter { $0.value < -0.2 }
            .sorted { $0.value < $1.value }
            .map(\.key)
    }

    /// Proportion of tags with |weight| > 0.1
    var confidence: Double {
        guard !weights.isEmpty else { return 0 }
        let significant = weights.values.filter { abs($0) > 0.1 }.count
        return Double(significant) / Double(weights.count)
    }

    /// Gated confidence label based on swipe count and top-tag separation.
    /// - Strong: >= 14 swipes AND (top1 - top2) >= 0.15 after normalization
    /// - Developing: some signal but doesn't meet Strong threshold
    /// - Low: minimal signal
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
}

// MARK: - Taste Variant

struct TasteVariant {
    let label: String
    let subtitle: String
    let vector: TasteVector
}
