import Foundation

struct SavedProfile: Codable {
    let tasteProfile: TasteProfile
    let recommendations: [RecommendationItem]
    let savedAt: Date
}

enum ProfileStore {

    private static let fileName = "saved_profile.json"

    private static var fileURL: URL {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
    }

    // MARK: - Save

    static func save(profile: TasteProfile, recommendations: [RecommendationItem]) {
        let saved = SavedProfile(
            tasteProfile: profile,
            recommendations: recommendations,
            savedAt: Date()
        )
        do {
            let data = try JSONEncoder().encode(saved)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            // Fail silently — persistence is best-effort for MVP.
        }
    }

    // MARK: - Load

    static func loadLatest() -> SavedProfile? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? JSONDecoder().decode(SavedProfile.self, from: data)
    }

    // MARK: - Clear

    static func clear() {
        try? FileManager.default.removeItem(at: fileURL)
    }
}
