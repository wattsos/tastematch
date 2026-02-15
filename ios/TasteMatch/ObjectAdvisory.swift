import SwiftUI

// MARK: - Centralized Object Advisory

enum ObjectAdvisory {

    /// Compute advisory decision for an item, loading calibration from store.
    static func decision(
        for item: RecommendationItem,
        profileId: UUID,
        level: AdvisoryLevel,
        tolerance: Double = 0.0
    ) -> AdvisoryDecision? {
        guard let record = ObjectCalibrationStore.load(for: profileId) else { return nil }
        let scores = ObjectAxisMapping.computeAxisScores(from: record.vector)
        return decision(for: item, scores: scores, level: level, tolerance: tolerance)
    }

    /// Compute advisory decision using pre-computed axis scores.
    static func decision(
        for item: RecommendationItem,
        scores: ObjectAxisScores,
        level: AdvisoryLevel,
        tolerance: Double = 0.0
    ) -> AdvisoryDecision? {
        let catalog = DomainCatalog.items(for: .objects)
        guard let catalogItem = catalog.first(where: { $0.skuId == item.skuId }),
              !catalogItem.objectAxisWeights.isEmpty else { return nil }
        let conflict = TasteConflictEngine.evaluateObjects(
            userScores: scores,
            itemAxes: catalogItem.objectAxisWeights
        )
        return AdvisoryPolicy.decide(level: level, conflict: conflict, tolerance: tolerance)
    }

    /// Apply intentional shift: blend item vector into user's Object calibration at 10% alpha.
    static func applyIntentionalShift(item: RecommendationItem, profileId: UUID) {
        let catalog = DomainCatalog.items(for: .objects)
        guard let catalogItem = catalog.first(where: { $0.skuId == item.skuId }),
              !catalogItem.objectAxisWeights.isEmpty else { return }
        guard var record = ObjectCalibrationStore.load(for: profileId) else { return }

        let alpha = 0.10
        for axis in ObjectAxis.allCases {
            let key = axis.rawValue
            let current = record.vector.weights[key, default: 0.0]
            let itemVal = catalogItem.objectAxisWeights[key, default: 0.0]
            record.vector.weights[key] = current + alpha * itemVal
        }

        ObjectCalibrationStore.save(record)
    }

    static func verdictCue(_ verdict: AdvisoryVerdict) -> String {
        switch verdict {
        case .green:  return "In your lane"
        case .yellow: return "Edges you"
        case .red:    return "High drift"
        }
    }

    static func verdictDotColor(_ verdict: AdvisoryVerdict) -> Color {
        switch verdict {
        case .green:  return Color(red: 0.45, green: 0.55, blue: 0.45)
        case .yellow: return Color(red: 0.65, green: 0.58, blue: 0.38)
        case .red:    return Color(red: 0.60, green: 0.38, blue: 0.38)
        }
    }
}

// MARK: - FIT Badge View

struct ObjectFitBadge: View {
    let decision: AdvisoryDecision
    var compact: Bool = false

    var body: some View {
        if compact {
            HStack(spacing: 3) {
                Circle()
                    .fill(ObjectAdvisory.verdictDotColor(decision.verdict))
                    .frame(width: 4, height: 4)
                Text("FIT")
                    .font(.system(size: 8, weight: .medium, design: .monospaced))
                    .foregroundStyle(Theme.muted)
            }
        } else {
            VStack(alignment: .trailing, spacing: 1) {
                HStack(spacing: 3) {
                    Circle()
                        .fill(ObjectAdvisory.verdictDotColor(decision.verdict))
                        .frame(width: 5, height: 5)
                    Text("FIT \(Int(decision.conflict.alignment * 100))")
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundStyle(Theme.muted)
                }
                Text(ObjectAdvisory.verdictCue(decision.verdict))
                    .font(.caption2)
                    .foregroundStyle(Theme.muted)
            }
        }
    }
}
