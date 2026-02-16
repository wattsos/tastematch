import Foundation

// MARK: - Decision Action

enum DecisionAction: String, Codable {
    case aligned, notForMe, bought
}

// MARK: - Decision Event

struct DecisionEvent: Codable {
    let id: UUID
    let profileId: UUID
    let skuId: String
    let action: DecisionAction
    let timestamp: Date
}

// MARK: - Decision Store

enum DecisionStore {

    private static let fileName = "decision_events.json"

    private static var fileURL: URL {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
    }

    static func record(_ event: DecisionEvent) {
        var all = loadAll()
        all.append(event)
        do {
            let data = try JSONEncoder().encode(all)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            // Best-effort persistence.
        }
    }

    static func loadAll() -> [DecisionEvent] {
        guard let data = try? Data(contentsOf: fileURL) else { return [] }
        return (try? JSONDecoder().decode([DecisionEvent].self, from: data)) ?? []
    }

    static func events(for profileId: UUID) -> [DecisionEvent] {
        loadAll().filter { $0.profileId == profileId }
    }
}
