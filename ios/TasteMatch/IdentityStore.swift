import Foundation

enum IdentityStore {

    private static let fileName = "taste_identity.json"

    private static var fileURL: URL {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
    }

    // MARK: - Load

    static func load() -> TasteIdentity? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? JSONDecoder().decode(TasteIdentity.self, from: data)
    }

    // MARK: - Save

    static func save(_ identity: TasteIdentity) {
        do {
            let data = try JSONEncoder().encode(identity)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            // Best-effort persistence.
        }
    }

    // MARK: - Clear

    static func clear() {
        try? FileManager.default.removeItem(at: fileURL)
    }
}
