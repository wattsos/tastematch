import Foundation

struct TasteIdentity: Codable, Identifiable, Equatable {
    var id: UUID
    var vector: TasteVector
    var version: Int
    var stability: Double
    var updatedAt: Date

    var avoids: [String] { vector.avoids }
    var influences: [String] { vector.influences }

    // Convenience init — starts a new identity from a seed vector
    init(vector: TasteVector = .zero) {
        self.id = UUID()
        self.vector = vector
        self.version = 1
        self.stability = 0.5
        self.updatedAt = Date()
    }

    // Full init — used by ReinforcementService when producing updated copies
    init(id: UUID, vector: TasteVector, version: Int, stability: Double, updatedAt: Date) {
        self.id = id
        self.vector = vector
        self.version = version
        self.stability = stability
        self.updatedAt = updatedAt
    }
}
