import Foundation

struct TasteEvaluatedObject: Codable, Identifiable, Equatable {
    var id: UUID
    var alignmentScore: Int       // 0–100
    var confidence: Double        // 0–1
    var tensionFlags: [String]
    var riskOfRegret: Double      // 0–1
    var reasons: [String]
    var identityVersionUsed: Int
    var createdAt: Date

    init(
        id: UUID = UUID(),
        alignmentScore: Int,
        confidence: Double,
        tensionFlags: [String],
        riskOfRegret: Double,
        reasons: [String],
        identityVersionUsed: Int,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.alignmentScore = max(0, min(100, alignmentScore))
        self.confidence = max(0.0, min(1.0, confidence))
        self.tensionFlags = tensionFlags
        self.riskOfRegret = max(0.0, min(1.0, riskOfRegret))
        self.reasons = reasons
        self.identityVersionUsed = identityVersionUsed
        self.createdAt = createdAt
    }
}
