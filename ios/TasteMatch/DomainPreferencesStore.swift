import Foundation

enum DomainPreferencesStore {

    struct Preferences: Codable {
        var enabledDomains: Set<TasteDomain>
        var primaryDomain: TasteDomain
        var onboardingComplete: Bool
        var lastViewedDomain: [String: String]  // profileId -> domain rawValue
    }

    private static let fileName = "domain_preferences.json"

    private static var fileURL: URL {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
    }

    private static var cached: Preferences?

    // MARK: - Load / Save

    static func load() -> Preferences {
        if let cached { return cached }
        if let data = try? Data(contentsOf: fileURL),
           let prefs = try? JSONDecoder().decode(Preferences.self, from: data) {
            cached = prefs
            return prefs
        }
        // Migration: check if existing user
        let migrated = migrateIfNeeded()
        cached = migrated
        save(migrated)
        return migrated
    }

    static func save(_ prefs: Preferences) {
        cached = prefs
        do {
            let data = try JSONEncoder().encode(prefs)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            // Best-effort persistence
        }
    }

    // MARK: - Convenience Accessors

    static var enabledDomains: Set<TasteDomain> {
        load().enabledDomains
    }

    static var primaryDomain: TasteDomain {
        load().primaryDomain
    }

    static var isOnboardingComplete: Bool {
        load().onboardingComplete
    }

    static func setEnabled(_ domains: Set<TasteDomain>) {
        var prefs = load()
        prefs.enabledDomains = domains
        // Primary domain = first in canonical order that's enabled
        let canonical: [TasteDomain] = [.space, .objects, .art]
        prefs.primaryDomain = canonical.first(where: { domains.contains($0) }) ?? .space
        save(prefs)
    }

    static func setLastViewed(domain: TasteDomain, for profileId: UUID) {
        var prefs = load()
        prefs.lastViewedDomain[profileId.uuidString] = domain.rawValue
        save(prefs)
    }

    static func lastViewed(for profileId: UUID) -> TasteDomain? {
        let prefs = load()
        guard let raw = prefs.lastViewedDomain[profileId.uuidString] else { return nil }
        let domain = TasteDomain(rawValue: raw)
        // Only return if still enabled
        if let domain, prefs.enabledDomains.contains(domain) { return domain }
        return nil
    }

    static func markOnboardingComplete() {
        var prefs = load()
        prefs.onboardingComplete = true
        save(prefs)
    }

    static func clear() {
        cached = nil
        try? FileManager.default.removeItem(at: fileURL)
    }

    // MARK: - Migration

    private static func migrateIfNeeded() -> Preferences {
        let hasExisting = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        if hasExisting {
            // Existing user: enable all 3 domains, mark onboarding complete
            return Preferences(
                enabledDomains: Set(TasteDomain.allCases),
                primaryDomain: DomainStore.current,
                onboardingComplete: true,
                lastViewedDomain: [:]
            )
        }
        // Fresh user: needs goal selection
        return Preferences(
            enabledDomains: [.space],
            primaryDomain: .space,
            onboardingComplete: false,
            lastViewedDomain: [:]
        )
    }
}
