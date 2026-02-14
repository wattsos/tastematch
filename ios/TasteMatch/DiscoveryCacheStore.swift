import Foundation

// MARK: - Cache Entry

struct DiscoveryCacheEntry: Codable {
    let profileId: UUID
    let vectorHash: String
    let rankedIds: [String]
    let cachedAt: Date
}

// MARK: - Cache Store

enum DiscoveryCacheStore {

    private static let fileName = "discovery_cache.json"
    private static let ttl: TimeInterval = 3600 // 1 hour

    private static var fileURL: URL {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
    }

    // MARK: - Load

    static func load(profileId: UUID, vectorHash: String) -> DiscoveryCacheEntry? {
        let all = loadAll()
        guard let entry = all.first(where: { $0.profileId == profileId && $0.vectorHash == vectorHash }) else {
            return nil
        }
        guard Date().timeIntervalSince(entry.cachedAt) < ttl else {
            return nil
        }
        return entry
    }

    // MARK: - Save

    static func save(profileId: UUID, vectorHash: String, rankedIds: [String]) {
        var all = loadAll()
        all.removeAll { $0.profileId == profileId }
        let entry = DiscoveryCacheEntry(
            profileId: profileId,
            vectorHash: vectorHash,
            rankedIds: rankedIds,
            cachedAt: Date()
        )
        all.append(entry)
        write(all)
    }

    // MARK: - Invalidate

    static func invalidate(profileId: UUID) {
        var all = loadAll()
        all.removeAll { $0.profileId == profileId }
        write(all)
    }

    // MARK: - Private

    private static func loadAll() -> [DiscoveryCacheEntry] {
        guard let data = try? Data(contentsOf: fileURL) else { return [] }
        return (try? JSONDecoder().decode([DiscoveryCacheEntry].self, from: data)) ?? []
    }

    private static func write(_ entries: [DiscoveryCacheEntry]) {
        do {
            let data = try JSONEncoder().encode(entries)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            // Best-effort persistence.
        }
    }
}
