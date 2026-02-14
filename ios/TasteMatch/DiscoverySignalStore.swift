import Foundation

// MARK: - Discovery Signals

struct DiscoverySignals: Codable {
    let profileId: UUID
    var viewedIds: Set<String>
    var savedIds: Set<String>
    var dismissedIds: Set<String>

    init(profileId: UUID, viewedIds: Set<String> = [], savedIds: Set<String> = [], dismissedIds: Set<String> = []) {
        self.profileId = profileId
        self.viewedIds = viewedIds
        self.savedIds = savedIds
        self.dismissedIds = dismissedIds
    }
}

// MARK: - Signal Store

enum DiscoverySignalStore {

    private static let fileName = "discovery_signals.json"

    private static var fileURL: URL {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
    }

    // MARK: - Record

    static func recordViewed(_ itemId: String, profileId: UUID, item: DiscoveryItem? = nil) {
        var signals = load(for: profileId)
        signals.viewedIds.insert(itemId)
        save(signals)
        if let item = item {
            EventLogger.shared.logEvent(
                "discovery_viewed",
                tasteProfileId: profileId,
                metadata: ["itemId": itemId, "type": item.type.rawValue]
            )
        }
    }

    static func recordSaved(_ itemId: String, profileId: UUID, item: DiscoveryItem? = nil) {
        var signals = load(for: profileId)
        signals.savedIds.insert(itemId)
        save(signals)
        if let item = item {
            EventLogger.shared.logEvent(
                "discovery_saved",
                tasteProfileId: profileId,
                metadata: ["itemId": itemId, "type": item.type.rawValue]
            )
        }
    }

    static func recordDismissed(_ itemId: String, profileId: UUID, item: DiscoveryItem? = nil) {
        var signals = load(for: profileId)
        signals.dismissedIds.insert(itemId)
        save(signals)
        if let item = item {
            EventLogger.shared.logEvent(
                "discovery_dismissed",
                tasteProfileId: profileId,
                metadata: ["itemId": itemId, "type": item.type.rawValue]
            )
        }
    }

    // MARK: - Load

    static func load(for profileId: UUID) -> DiscoverySignals {
        let all = loadAll()
        return all.first { $0.profileId == profileId }
            ?? DiscoverySignals(profileId: profileId)
    }

    // MARK: - Private

    private static func loadAll() -> [DiscoverySignals] {
        guard let data = try? Data(contentsOf: fileURL) else { return [] }
        return (try? JSONDecoder().decode([DiscoverySignals].self, from: data)) ?? []
    }

    private static func save(_ signals: DiscoverySignals) {
        var all = loadAll()
        all.removeAll { $0.profileId == signals.profileId }
        all.append(signals)
        do {
            let data = try JSONEncoder().encode(all)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            // Best-effort persistence.
        }
    }
}
