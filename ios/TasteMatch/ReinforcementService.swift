import Foundation

// MARK: - Taste Action (legacy alias kept for DecisionStore compatibility)

enum TasteAction: String, Codable {
    case bought, rejected, regretted
}

// MARK: - Reinforcement Service

enum ReinforcementService {

    // Primary taste-vote learning rates
    static let α       = 0.18   // me: pull embedding toward candidate
    static let αMaybe  = 0.05   // maybe: weak pull toward candidate
    static let γ       = 0.14   // notMe / returned (style reason): push antiEmbedding toward candidate

    // Anchor multiplier (applied at finalize time, not immediate)
    static let anchorMultiplier = 1.8

    // MARK: - Convenience wrapper (backward-compatible; no anchor logic)

    /// Simple vote application with no category context — used by tests and legacy callers.
    /// Anchor logic is bypassed (treated as non-anchor).
    @discardableResult
    static func applyTasteVote(
        vote: TasteVote,
        candidateEmbedding: StyleEmbedding,
        to identity: TasteIdentity
    ) -> TasteIdentity {
        applyTasteVote(
            vote: vote,
            candidateEmbedding: candidateEmbedding,
            category: .other,
            returnReason: nil,
            evaluationId: UUID(),
            to: identity
        ).identity
    }

    // MARK: - Full API (with anchor + return reason support)

    /// Applies a taste vote, respecting anchor hold logic for sofa/sectional items.
    /// Returns the updated identity AND an optional PendingReinforcement record.
    /// - For anchor items (sofa/sectional) with .me or .notMe: returns unchanged identity + pending record.
    /// - For all other combinations: applies immediate reinforcement, returns nil pending.
    static func applyTasteVote(
        vote: TasteVote,
        candidateEmbedding: StyleEmbedding,
        category: FurnitureCategory,
        returnReason: ReturnReason? = nil,
        evaluationId: UUID,
        to identity: TasteIdentity
    ) -> (identity: TasteIdentity, pending: PendingReinforcement?) {

        var updated = identity
        let before  = identity.embedding.dims
        var pending: PendingReinforcement?

        switch vote {

        case .me:
            if category.isAnchor {
                // Anchor: hold reinforcement; no immediate embedding change
                pending = PendingReinforcement.make(
                    for: evaluationId,
                    identityVersion: identity.version,
                    candidateEmbedding: candidateEmbedding,
                    vote: .me,
                    category: category
                )
                updated.countMe += 1
                // No embedding change; stability unchanged
                updated.version   = identity.version + 1
                updated.updatedAt = Date()
                return (updated, pending)
            } else {
                updated.embedding.blend(toward: candidateEmbedding, weight: α)
                updated.countMe += 1
            }

        case .notMe:
            if category.isAnchor {
                // Anchor: hold reinforcement; no immediate embedding change
                pending = PendingReinforcement.make(
                    for: evaluationId,
                    identityVersion: identity.version,
                    candidateEmbedding: candidateEmbedding,
                    vote: .notMe,
                    category: category
                )
                updated.countNotMe += 1
                updated.version   = identity.version + 1
                updated.updatedAt = Date()
                return (updated, pending)
            } else {
                updated.antiEmbedding.blend(toward: candidateEmbedding, weight: γ)
                updated.countNotMe += 1
            }

        case .maybe:
            // Maybe always applies immediately (even for anchors — it's weak signal)
            updated.embedding.blend(toward: candidateEmbedding, weight: αMaybe)
            updated.countMaybe += 1

        case .returned:
            // Returned: apply anti-signal only for style-related reasons
            if let reason = returnReason, reason.affectsStyleLearning {
                updated.antiEmbedding.blend(toward: candidateEmbedding, weight: γ)
            }
            updated.countNotMe += 1
        }

        updated.stability  = updatedStability(before: before, after: updated.embedding.dims, prior: identity.stability)
        updated.version    = identity.version + 1
        updated.updatedAt  = Date()
        return (updated, nil)
    }

    // MARK: - Finalize Pending (applies anchor reinforcement at full strength)

    static func finalizePending(
        _ record: PendingReinforcement,
        to identity: TasteIdentity
    ) -> TasteIdentity {
        var updated = identity
        let before  = identity.embedding.dims
        let ampAlpha = α * anchorMultiplier   // 0.18 × 1.8 = 0.324
        let ampGamma = γ * anchorMultiplier   // 0.14 × 1.8 = 0.252

        switch record.vote {
        case .me:
            updated.embedding.blend(toward: record.candidateEmbedding, weight: ampAlpha)
        case .notMe:
            updated.antiEmbedding.blend(toward: record.candidateEmbedding, weight: ampGamma)
        default:
            break
        }

        updated.stability  = updatedStability(before: before, after: updated.embedding.dims, prior: identity.stability)
        updated.version    = identity.version + 1
        updated.updatedAt  = Date()
        return updated
    }

    // MARK: - Helpers

    private static func updatedStability(before: [Double], after: [Double], prior: Double) -> Double {
        guard before.count == after.count else { return prior }
        let avgDelta = zip(before, after).map { abs($1 - $0) }.reduce(0, +) / Double(before.count)
        let raw      = 1.0 - avgDelta * 10.0
        let clamped  = max(0.0, min(1.0, raw))
        return 0.9 * prior + 0.1 * clamped
    }
}
