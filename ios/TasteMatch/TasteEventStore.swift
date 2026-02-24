import Foundation

// MARK: - Taste Event

struct TasteEvent: Codable, Identifiable {
    var id: UUID
    var action: TasteAction
    var evaluation: TasteEvaluatedObject    // full evaluation embedded for detail views
    var identityVersionBefore: Int
    var identityVersionAfter: Int
    var timestamp: Date

    // Convenience accessors (spec-listed fields)
    var evaluatedObjectId: UUID { evaluation.id }
    var alignmentScore: Int     { evaluation.alignmentScore }
    var confidence: Double      { evaluation.confidence }
    var riskOfRegret: Double    { evaluation.riskOfRegret }
    var tensionFlags: [String]  { evaluation.tensionFlags }
}

// MARK: - Taste Event Store

enum TasteEventStore {

    private static let fileName = "taste_events.json"

    private static var fileURL: URL {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
    }

    // MARK: - Append

    static func append(event: TasteEvent) {
        var all = loadAll()
        all.append(event)
        do {
            let data = try JSONEncoder().encode(all)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            // Best-effort persistence.
        }
    }

    // MARK: - Load

    static func loadAll() -> [TasteEvent] {
        guard let data = try? Data(contentsOf: fileURL) else { return [] }
        return (try? JSONDecoder().decode([TasteEvent].self, from: data)) ?? []
    }
}
