import Foundation

// MARK: - Taste Action

enum TasteAction: String, Codable {
    case bought, rejected, regretted
}

// MARK: - Reinforcement Service

enum ReinforcementService {

    static func apply(
        action: TasteAction,
        candidateVector: TasteVector,
        to identity: TasteIdentity
    ) -> TasteIdentity {

        let learningRate: Double
        switch action {
        case .bought:    learningRate =  0.12
        case .rejected:  learningRate = -0.08
        case .regretted: learningRate = -0.20
        }

        var updatedWeights = identity.vector.weights
        let allKeys = Set(candidateVector.weights.keys).union(updatedWeights.keys)

        var totalDelta  = 0.0
        var deltaCount  = 0

        for key in allKeys {
            let candidateWeight = candidateVector.weights[key, default: 0.0]
            guard abs(candidateWeight) > 0.1 else { continue }

            let current = updatedWeights[key, default: 0.0]
            let nudge   = learningRate * candidateWeight
            let updated = max(-1.0, min(1.0, current + nudge))

            totalDelta += abs(updated - current)
            deltaCount += 1
            updatedWeights[key] = updated
        }

        let newVector  = TasteVector(weights: updatedWeights)
        let stability: Double = deltaCount > 0
            ? max(0.0, min(1.0, 1.0 - (totalDelta / Double(deltaCount))))
            : identity.stability

        return TasteIdentity(
            id: identity.id,
            vector: newVector,
            version: identity.version + 1,
            stability: stability,
            updatedAt: Date()
        )
    }
}
