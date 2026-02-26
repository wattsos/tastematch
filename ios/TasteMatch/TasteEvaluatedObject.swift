import Foundation

// MARK: - Taste Vote (4 first-class actions)

enum TasteVote: String, Codable {
    case me, notMe, maybe, returned
}

// MARK: - Return Reason (required when tasteVote == .returned)

enum ReturnReason: String, Codable, CaseIterable {
    case tooLarge, tooSmall
    case colorMismatch, materialMismatch
    case priceDiscomfort, spaceConflict, qualityDisappointment
    case other

    var displayLabel: String {
        switch self {
        case .tooLarge:              return "Too large"
        case .tooSmall:              return "Too small"
        case .colorMismatch:         return "Color mismatch"
        case .materialMismatch:      return "Material mismatch"
        case .priceDiscomfort:       return "Price discomfort"
        case .spaceConflict:         return "Space conflict"
        case .qualityDisappointment: return "Quality disappointment"
        case .other:                 return "Other"
        }
    }

    /// True when the reason is style-related → triggers anti-embedding update
    var affectsStyleLearning: Bool {
        switch self {
        case .colorMismatch, .materialMismatch, .qualityDisappointment, .spaceConflict:
            return true
        default:
            return false
        }
    }
}

// MARK: - Furniture Category

enum FurnitureCategory: String, Codable, CaseIterable {
    case sofa, sectional, coffeeTable, loungeChair, rug, mediaConsole, other

    var displayLabel: String {
        switch self {
        case .sofa:         return "Sofa"
        case .sectional:    return "Sectional"
        case .coffeeTable:  return "Coffee Table"
        case .loungeChair:  return "Lounge Chair"
        case .rug:          return "Rug"
        case .mediaConsole: return "Media Console"
        case .other:        return "Other"
        }
    }

    /// Anchor pieces get a 14-day reinforcement hold before locking in identity updates
    var isAnchor: Bool { self == .sofa || self == .sectional }

    /// Applied at finalization time for anchor pieces (not used for immediate nudges)
    var anchorMultiplier: Double { isAnchor ? 1.8 : 1.0 }
}

// MARK: - Evaluation Context (budget + scale; all fields optional / placeholder)

struct EvaluationContext: Codable, Equatable {
    var declaredBudgetMin: Double?
    var declaredBudgetMax: Double?
    var roomWidth: Double?          // feet
    var roomLength: Double?         // feet
    var itemWidth: Double?          // feet
    var itemDepth: Double?          // feet
    var itemPrice: Double?
}

// MARK: - TasteEvaluation (canonical event payload)

/// The complete result of evaluating a candidate item against the user's TasteIdentity.
/// Serves as both the evaluation result AND the append-only history event.
struct TasteEvaluation: Codable, Identifiable, Equatable {

    var id: UUID

    // Sub-snapshots captured at evaluation time
    var candidate: CandidateSnapshot
    var identity: IdentitySnapshot
    var score: ScoreSnapshot

    // Set on the evaluation screen
    var tasteVote: TasteVote?
    var returnReason: ReturnReason?         // required when tasteVote == .returned
    var furnitureCategory: FurnitureCategory?
    var purchaseContext: EvaluationContext?
    var notes: String?

    var createdAt: Date

    // MARK: - Snapshots

    struct CandidateSnapshot: Codable, Equatable {
        var embedding: StyleEmbedding
        var signals: StyleSignals
    }

    struct IdentitySnapshot: Codable, Equatable {
        var version: Int
        var stability: Double
        var countMe: Int
        var countNotMe: Int
        var countMaybe: Int
    }

    struct ScoreSnapshot: Codable, Equatable {
        var alignmentScore: Int         // 0–100
        var tensionScore: Int           // 0–100
        var confidence: Double          // 0–1
        var riskOfRegret: Double        // 0–1
        var purchaseConfidence: Double  // 0–1
        var budgetStressScore: Double   // 0–1; 0.5 = unknown
        var scaleFitScore: Double       // 0–1; 0.5 = unknown
        var tensionFlags: [String]
        var reasons: [String]
    }

    // MARK: - Convenience Accessors

    var alignmentScore: Int           { score.alignmentScore }
    var tensionScore: Int             { score.tensionScore }
    var confidence: Double            { score.confidence }
    var riskOfRegret: Double          { score.riskOfRegret }
    var purchaseConfidence: Double    { score.purchaseConfidence }
    var budgetStressScore: Double     { score.budgetStressScore }
    var scaleFitScore: Double         { score.scaleFitScore }
    var tensionFlags: [String]        { score.tensionFlags }
    var reasons: [String]             { score.reasons }
    var identityVersionUsed: Int      { identity.version }
}

// MARK: - Legacy alias (keeps any residual TasteEvaluatedObject references compiling)
typealias TasteEvaluatedObject = TasteEvaluation
