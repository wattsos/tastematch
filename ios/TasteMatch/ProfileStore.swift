import Foundation

struct SavedProfile: Codable, Identifiable {
    var id: UUID { tasteProfile.id }
    let tasteProfile: TasteProfile
    let recommendations: [RecommendationItem]
    let savedAt: Date
    let roomContext: RoomContext?
    let designGoal: DesignGoal?
    let domain: TasteDomain?

    enum CodingKeys: String, CodingKey {
        case tasteProfile, recommendations, savedAt, roomContext, designGoal, domain
    }

    init(tasteProfile: TasteProfile, recommendations: [RecommendationItem], savedAt: Date, roomContext: RoomContext?, designGoal: DesignGoal?, domain: TasteDomain? = nil) {
        self.tasteProfile = tasteProfile
        self.recommendations = recommendations
        self.savedAt = savedAt
        self.roomContext = roomContext
        self.designGoal = designGoal
        self.domain = domain
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        tasteProfile = try c.decode(TasteProfile.self, forKey: .tasteProfile)
        recommendations = try c.decode([RecommendationItem].self, forKey: .recommendations)
        savedAt = try c.decode(Date.self, forKey: .savedAt)
        roomContext = try c.decodeIfPresent(RoomContext.self, forKey: .roomContext)
        designGoal = try c.decodeIfPresent(DesignGoal.self, forKey: .designGoal)
        domain = try c.decodeIfPresent(TasteDomain.self, forKey: .domain)
    }
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
        designGoal: DesignGoal? = nil,
        domain: TasteDomain? = nil
    ) {
        var history = loadAll()
        let saved = SavedProfile(
            tasteProfile: profile,
            recommendations: recommendations,
            savedAt: Date(),
            roomContext: roomContext,
            designGoal: designGoal,
            domain: domain
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
            designGoal: all[idx].designGoal,
            domain: all[idx].domain
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

// MARK: - Reveal Store

enum RevealStore {
    private static func key(for profileId: UUID) -> String {
        "didReveal_\(profileId.uuidString)"
    }

    static func isRevealed(_ profileId: UUID) -> Bool {
        UserDefaults.standard.bool(forKey: key(for: profileId))
    }

    static func markRevealed(_ profileId: UUID) {
        UserDefaults.standard.set(true, forKey: key(for: profileId))
    }

    static func clear(_ profileId: UUID) {
        UserDefaults.standard.removeObject(forKey: key(for: profileId))
    }
}
