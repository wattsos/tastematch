import Foundation

struct TasteIdentity: Codable, Identifiable, Equatable {

    var id: UUID
    var embedding: StyleEmbedding       // what I tend toward
    var antiEmbedding: StyleEmbedding   // what I tend to avoid
    var version: Int
    var stability: Double               // EMA of 1-delta; 0..1
    var countMe: Int
    var countNotMe: Int
    var countMaybe: Int
    var updatedAt: Date

    /// Total taste votes recorded.
    var totalDecisions: Int { countMe + countNotMe + countMaybe }

    // MARK: - Convenience init (fresh identity)

    init(
        id: UUID = UUID(),
        embedding: StyleEmbedding = .zero,
        antiEmbedding: StyleEmbedding = .zero
    ) {
        self.id = id
        self.embedding = embedding
        self.antiEmbedding = antiEmbedding
        self.version = 1
        self.stability = 0.5
        self.countMe = 0
        self.countNotMe = 0
        self.countMaybe = 0
        self.updatedAt = Date()
    }
}
