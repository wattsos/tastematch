import Foundation

// MARK: - Pending Reinforcement

/// A reinforcement update that is held for 14 days before being applied to the identity.
/// Created for anchor items (sofa / sectional) when the user votes me or notMe.
struct PendingReinforcement: Codable, Identifiable {
    var id: UUID
    var evaluationId: UUID
    var identityVersionAtTime: Int
    var candidateEmbedding: StyleEmbedding
    var vote: TasteVote          // .me or .notMe only
    var category: FurnitureCategory
    var createdAt: Date
    var unlockAt: Date           // createdAt + holdDuration

    static let holdDuration: TimeInterval = 14 * 24 * 3600  // 14 days

    var isReady: Bool { Date() >= unlockAt }

    static func make(
        for evaluationId: UUID,
        identityVersion: Int,
        candidateEmbedding: StyleEmbedding,
        vote: TasteVote,
        category: FurnitureCategory
    ) -> PendingReinforcement {
        let now = Date()
        return PendingReinforcement(
            id: UUID(),
            evaluationId: evaluationId,
            identityVersionAtTime: identityVersion,
            candidateEmbedding: candidateEmbedding,
            vote: vote,
            category: category,
            createdAt: now,
            unlockAt: now.addingTimeInterval(holdDuration)
        )
    }
}

// MARK: - Store

enum PendingReinforcementStore {

    private static let key = "pendingReinforcements_v1"

    static func append(_ record: PendingReinforcement) {
        var all = loadAll()
        all.append(record)
        save(all)
    }

    static func remove(id: UUID) {
        var all = loadAll()
        all.removeAll { $0.id == id }
        save(all)
    }

    static func removeAll(for evaluationId: UUID) {
        var all = loadAll()
        all.removeAll { $0.evaluationId == evaluationId }
        save(all)
    }

    static func loadAll() -> [PendingReinforcement] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let records = try? JSONDecoder().decode([PendingReinforcement].self, from: data) else {
            return []
        }
        return records
    }

    static func pending(for evaluationId: UUID) -> PendingReinforcement? {
        loadAll().first { $0.evaluationId == evaluationId }
    }

    private static func save(_ records: [PendingReinforcement]) {
        if let data = try? JSONEncoder().encode(records) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
