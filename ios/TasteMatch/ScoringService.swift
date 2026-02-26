import Foundation

enum ScoringService {

    static func score(
        candidate: StyleEmbedding,
        signals: StyleSignals,
        identity: TasteIdentity,
        category: FurnitureCategory? = nil,
        context: EvaluationContext? = nil
    ) -> TasteEvaluation {

        let normCandidate = candidate.normalized()
        let normEmbedding = identity.embedding.normalized()
        let normAnti      = identity.antiEmbedding.normalized()

        // --- Alignment: cosine(candidate, identity.embedding) ---
        let cosAlign  = normCandidate.cosine(with: normEmbedding)
        var alignmentScore = Int(((cosAlign + 1.0) / 2.0) * 100.0)

        // --- Tension: cosine(candidate, identity.antiEmbedding) ---
        let tensionScore: Int
        if normAnti.isZero {
            tensionScore = 0
        } else {
            let cosTension = normCandidate.cosine(with: normAnti)
            tensionScore = Int(((cosTension + 1.0) / 2.0) * 100.0)
        }

        // Tension penalty applied to alignment
        alignmentScore = max(0, min(100, alignmentScore - tensionScore / 3))

        // --- Budget stress + scale fit (from EvaluationContext) ---
        let budgetStressVal = context.map { budgetStress(context: $0) } ?? 0.5
        let scaleFitVal     = context.map { scaleFit(context: $0) }     ?? 0.5

        // --- Confidence: sigmoid over total decisions ---
        let decisions  = identity.totalDecisions
        let confidence = 1.0 / (1.0 + exp(-0.3 * Double(decisions - 5)))

        // --- Purchase Confidence ---
        let styleAlignment = Double(alignmentScore) / 100.0
        let purchaseConf   = styleAlignment * 0.40
                           + scaleFitVal   * 0.25
                           + (1.0 - budgetStressVal) * 0.25
                           + identity.stability      * 0.10
        let purchaseConfidence = max(0.0, min(1.0, purchaseConf))

        // --- Risk of regret = complement of purchaseConfidence + tension penalty ---
        var riskOfRegret = 1.0 - purchaseConfidence
        if tensionScore > 50 { riskOfRegret += 0.15 }
        riskOfRegret = max(0.0, min(1.0, riskOfRegret))

        // --- Tension flags (signal-level explanations) ---
        var tensionFlags: [String] = []
        if tensionScore > 50 {
            if signals.ornateVsMinimal > 0.6  { tensionFlags.append("ornate against minimal identity") }
            if signals.clutter > 0.6          { tensionFlags.append("high clutter") }
            if signals.materialHardness > 0.7 { tensionFlags.append("hard materials vs soft preference") }
        }

        // --- Reasons ---
        var reasons: [String] = []
        let topSignal = topSignalName(signals)
        if !topSignal.isEmpty { reasons.append("Dominant signal: \(topSignal)") }
        reasons.append("Alignment: \(alignmentLabel(alignmentScore))")
        if tensionScore > 40 { reasons.append("Tension present: \(riskLabel(riskOfRegret)) risk") }
        reasons.append("Confidence: \(confidenceLabel(confidence))")

        // --- Assemble ---
        let candidateSnap = TasteEvaluation.CandidateSnapshot(embedding: candidate, signals: signals)
        let identitySnap  = TasteEvaluation.IdentitySnapshot(
            version:    identity.version,
            stability:  identity.stability,
            countMe:    identity.countMe,
            countNotMe: identity.countNotMe,
            countMaybe: identity.countMaybe
        )
        let scoreSnap = TasteEvaluation.ScoreSnapshot(
            alignmentScore:    alignmentScore,
            tensionScore:      tensionScore,
            confidence:        confidence,
            riskOfRegret:      riskOfRegret,
            purchaseConfidence: purchaseConfidence,
            budgetStressScore:  budgetStressVal,
            scaleFitScore:      scaleFitVal,
            tensionFlags:       tensionFlags,
            reasons:            reasons
        )
        return TasteEvaluation(
            id:               UUID(),
            candidate:        candidateSnap,
            identity:         identitySnap,
            score:            scoreSnap,
            tasteVote:        nil,
            returnReason:     nil,
            furnitureCategory: category,
            purchaseContext:   context,
            notes:             nil,
            createdAt:         Date()
        )
    }

    // MARK: - Labels

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
        case 0.5...:  return "High"
        case 0.25...: return "Moderate"
        default:      return "Low"
        }
    }

    static func purchaseConfidenceLabel(_ confidence: Double) -> String {
        switch confidence {
        case 0.70...: return "Strong"
        case 0.45...: return "Moderate"
        default:      return "Uncertain"
        }
    }

    // MARK: - Budget Stress Heuristic (0 = no stress, 1 = max stress)

    private static func budgetStress(context: EvaluationContext) -> Double {
        guard let price = context.itemPrice else { return 0.5 }
        if let maxBudget = context.declaredBudgetMax, maxBudget > 0 {
            if price > maxBudget { return 1.0 }
            let comfortZone = maxBudget * 0.70
            if price <= comfortZone { return 0.0 }
            return (price - comfortZone) / (maxBudget - comfortZone)
        }
        if let minBudget = context.declaredBudgetMin, price < minBudget { return 0.1 }
        return 0.5
    }

    // MARK: - Scale Fit Heuristic (0 = poor fit, 1 = ideal fit)

    private static func scaleFit(context: EvaluationContext) -> Double {
        guard let iw = context.itemWidth, let id = context.itemDepth,
              let rw = context.roomWidth, let rl = context.roomLength,
              rw > 0, rl > 0 else { return 0.5 }
        let roomArea = rw * rl
        let itemArea = iw * id
        let ratio    = itemArea / roomArea
        switch ratio {
        case ..<0.05:          return 0.3   // too small
        case 0.05..<0.10:      return 0.6
        case 0.10..<0.25:      return 1.0   // ideal
        case 0.25..<0.35:      return 0.7
        default:               return 0.2   // too large
        }
    }

    // MARK: - Helpers

    private static func topSignalName(_ signals: StyleSignals) -> String {
        let named: [(String, Double)] = [
            ("minimal",    1.0 - signals.ornateVsMinimal),
            ("ornate",     signals.ornateVsMinimal),
            ("warm",       signals.warmth),
            ("cool",       1.0 - signals.warmth),
            ("bright",     signals.brightness),
            ("dark",       1.0 - signals.brightness),
            ("organic",    signals.organicVsIndustrial),
            ("industrial", 1.0 - signals.organicVsIndustrial),
            ("vintage",    signals.vintageVsModern),
            ("modern",     1.0 - signals.vintageVsModern),
        ]
        return named.max(by: { $0.1 < $1.1 })?.0 ?? ""
    }
}
