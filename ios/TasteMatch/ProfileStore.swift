import Foundation

struct SavedProfile: Codable, Identifiable {
    var id: UUID { tasteProfile.id }
    let tasteProfile: TasteProfile
    let recommendations: [RecommendationItem]
    let savedAt: Date
    let roomContext: RoomContext?
    let designGoal: DesignGoal?
}

enum ProfileStore {

    private static let fileName = "profile_history.json"

    private static var fileURL: URL {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
    }

    // MARK: - Save

    static func save(
        profile: TasteProfile,
        recommendations: [RecommendationItem],
        roomContext: RoomContext? = nil,
        designGoal: DesignGoal? = nil
    ) {
        var history = loadAll()
        let saved = SavedProfile(
            tasteProfile: profile,
            recommendations: recommendations,
            savedAt: Date(),
            roomContext: roomContext,
            designGoal: designGoal
        )
        history.append(saved)
        write(history)
    }

    // MARK: - Load

    static func loadLatest() -> SavedProfile? {
        loadAll().last
    }

    static func loadAll() -> [SavedProfile] {
        guard let data = try? Data(contentsOf: fileURL) else { return [] }
        return (try? JSONDecoder().decode([SavedProfile].self, from: data)) ?? []
    }

    // MARK: - Update Naming

    static func updateNaming(profileId: UUID, result: ProfileNamingResult) {
        var all = loadAll()
        guard let idx = all.firstIndex(where: { $0.id == profileId }) else { return }
        var tp = all[idx].tasteProfile
        tp.profileName = result.name
        tp.profileNameVersion = result.version
        tp.profileNameUpdatedAt = result.updatedAt
        tp.profileNameBasisHash = result.basisHash
        tp.previousNames = result.previousNames
        all[idx] = SavedProfile(
            tasteProfile: tp,
            recommendations: all[idx].recommendations,
            savedAt: all[idx].savedAt,
            roomContext: all[idx].roomContext,
            designGoal: all[idx].designGoal
        )
        write(all)
    }

    // MARK: - Delete

    static func delete(id: UUID) {
        var history = loadAll()
        history.removeAll { $0.id == id }
        write(history)
    }

    // MARK: - Clear

    static func clear() {
        try? FileManager.default.removeItem(at: fileURL)
    }

    // MARK: - Private

    private static func write(_ history: [SavedProfile]) {
        do {
            let data = try JSONEncoder().encode(history)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            // Fail silently — persistence is best-effort for MVP.
        }
    }
}
