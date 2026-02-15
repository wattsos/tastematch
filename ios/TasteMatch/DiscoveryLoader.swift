import Foundation

// MARK: - Provider Protocol

protocol DiscoveryInventoryProvider {
    func loadItems() -> [DiscoveryItem]
}

// MARK: - Local NDJSON Provider

struct LocalNDJSONProvider: DiscoveryInventoryProvider {

    private let filename: String
    private let bundle: Bundle

    init(filename: String = "discovery_space", bundle: Bundle = .main) {
        self.filename = filename
        self.bundle = bundle
    }

    func loadItems() -> [DiscoveryItem] {
        // Try NDJSON first
        if let url = bundle.url(forResource: filename, withExtension: "ndjson"),
           let content = try? String(contentsOf: url, encoding: .utf8) {
            return parseNDJSON(content)
        }

        // Fall back to JSON array
        if let url = bundle.url(forResource: filename, withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let items = try? JSONDecoder().decode([DiscoveryItem].self, from: data) {
            return items
        }

        return []
    }

    private func parseNDJSON(_ content: String) -> [DiscoveryItem] {
        let decoder = JSONDecoder()
        var items: [DiscoveryItem] = []
        for line in content.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }
            guard let data = trimmed.data(using: .utf8),
                  let item = try? decoder.decode(DiscoveryItem.self, from: data) else {
                continue
            }
            items.append(item)
        }
        return items
    }
}
