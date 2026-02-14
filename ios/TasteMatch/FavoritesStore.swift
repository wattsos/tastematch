import Foundation

enum FavoritesStore {

    private static let fileName = "favorites.json"

    private static var fileURL: URL {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
    }

    // MARK: - Load

    static func loadAll() -> [RecommendationItem] {
        guard let data = try? Data(contentsOf: fileURL) else { return [] }
        return (try? JSONDecoder().decode([RecommendationItem].self, from: data)) ?? []
    }

    // MARK: - Add

    static func add(_ item: RecommendationItem) {
        var favorites = loadAll()
        guard !favorites.contains(where: { $0.title == item.title && $0.subtitle == item.subtitle }) else { return }
        favorites.append(item)
        write(favorites)
    }

    // MARK: - Remove

    static func remove(id: String) {
        var favorites = loadAll()
        favorites.removeAll { $0.id == id }
        write(favorites)
    }

    // MARK: - Check

    static func isFavorited(_ item: RecommendationItem) -> Bool {
        loadAll().contains(where: { $0.title == item.title && $0.subtitle == item.subtitle })
    }

    // MARK: - Clear

    static func clear() {
        try? FileManager.default.removeItem(at: fileURL)
    }

    // MARK: - Private

    private static func write(_ favorites: [RecommendationItem]) {
        do {
            let data = try JSONEncoder().encode(favorites)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            // Fail silently — best-effort for MVP.
        }
    }
}
