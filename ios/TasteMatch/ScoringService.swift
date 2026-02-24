import Foundation

enum ScoringService {

    static func score(
        candidateVector: TasteVector,
        identity: TasteIdentity
    ) -> TasteEvaluatedObject {

        let normCandidate = candidateVector.normalized()
        let normIdentity  = identity.vector.normalized()

        // --- Cosine similarity over union of keys ---
        let allKeys = Set(normCandidate.weights.keys).union(normIdentity.weights.keys)
        var dotProduct = 0.0
        var magA = 0.0
        var magB = 0.0
        for key in allKeys {
            let a = normCandidate.weights[key, default: 0.0]
            let b = normIdentity.weights[key, default: 0.0]
            dotProduct += a * b
            magA += a * a
            magB += b * b
        }
        let magnitude = sqrt(magA) * sqrt(magB)
        let cosine = magnitude > 0 ? dotProduct / magnitude : 0.0

        // Map cosine [-1, 1] → alignment [0, 100]
        var alignment = Int(((cosine + 1.0) / 2.0) * 100.0)

        // --- Avoid-hit penalty ---
        let candidateInfluences = Set(normCandidate.influences)
        let identityAvoids      = Set(identity.avoids)
        let avoidHits           = candidateInfluences.intersection(identityAvoids)
        alignment = max(0, min(100, alignment - avoidHits.count * 8))

        // --- Confidence (weighted combination) ---
        let confidence = max(0.0, min(1.0,
            normCandidate.confidence * 0.5 + normIdentity.confidence * 0.5
        ))

        // --- Risk of regret ---
        var riskOfRegret = 0.0
        if alignment >= 40 && alignment <= 70 { riskOfRegret += 0.30 }
        riskOfRegret += Double(avoidHits.count) * 0.20
        if confidence < 0.35               { riskOfRegret += 0.25 }
        riskOfRegret = max(0.0, min(1.0, riskOfRegret))

        // --- Reasons ---
        var reasons: [String] = []
        let topOverlap = normCandidate.influences.filter { normIdentity.influences.contains($0) }
        if !topOverlap.isEmpty {
            reasons.append("Matching signals: \(topOverlap.prefix(3).joined(separator: ", "))")
        }
        if !avoidHits.isEmpty {
            reasons.append("Conflicts with avoided signals: \(avoidHits.sorted().prefix(3).joined(separator: ", "))")
        }
        reasons.append("Confidence: \(confidenceLabel(confidence))")

        // --- Tension flags ---
        let tensionFlags = avoidHits.sorted()

        return TasteEvaluatedObject(
            alignmentScore: alignment,
            confidence: confidence,
            tensionFlags: tensionFlags,
            riskOfRegret: riskOfRegret,
            reasons: reasons,
            identityVersionUsed: identity.version
        )
    }

    // MARK: - Helpers

    static func alignmentLabel(_ score: Int) -> String {
        switch score {
        case 70...: return "ALIGNED"
        case 40...: return "MODERATE"
        default:    return "TENSION"
        }
    }

    static func confidenceLabel(_ confidence: Double) -> String {
        switch confidence {
        case 0.65...: return "High"
        case 0.35...: return "Moderate"
        default:      return "Low"
        }
    }

    static func riskLabel(_ risk: Double) -> String {
        switch risk {
        case 0.5...: return "High"
        case 0.25...: return "Moderate"
        default:     return "Low"
        }
    }
}
