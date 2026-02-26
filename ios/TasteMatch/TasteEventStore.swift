import Foundation

// MARK: - Taste Event Store
//
// TasteEvaluation IS the canonical event payload (append-only).
// vote/outcome/blocker/notes are updated in-place via update().

enum TasteEventStore {

    private static let fileName = "taste_events.json"

    private static var fileURL: URL {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
    }

    // MARK: - Append (initial evaluation + vote)

    static func append(_ evaluation: TasteEvaluation) {
        var all = loadAll()
        all.append(evaluation)
        persist(all)
    }

    // MARK: - Update (outcome/blocker/notes set after the fact)

    static func update(_ evaluation: TasteEvaluation) {
        var all = loadAll()
        if let idx = all.firstIndex(where: { $0.id == evaluation.id }) {
            all[idx] = evaluation
        }
        persist(all)
    }

    // MARK: - Load

    static func loadAll() -> [TasteEvaluation] {
        guard let data = try? Data(contentsOf: fileURL) else { return [] }
        return (try? JSONDecoder().decode([TasteEvaluation].self, from: data)) ?? []
    }

    // MARK: - Private

    private static func persist(_ evaluations: [TasteEvaluation]) {
        do {
            let data = try JSONEncoder().encode(evaluations)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            // Best-effort persistence.
        }
    }
}
