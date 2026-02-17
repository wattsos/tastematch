import Foundation

// MARK: - Deck Kind

enum StyleDeckKind: String, Codable {
    case menswear
    case womenswear
    case any

    static var stored: StyleDeckKind? {
        guard let raw = UserDefaults.standard.string(forKey: "styleDeckKind") else { return nil }
        return StyleDeckKind(rawValue: raw)
    }

    func save() {
        UserDefaults.standard.set(rawValue, forKey: "styleDeckKind")
    }
}

// MARK: - Style Card

struct StyleCard: Identifiable {
    let id = UUID()
    let imageName: String   // Asset catalog name (fit_001 ... fit_053)
}

// MARK: - Seed Decks

enum StyleSeedDeck {

    /// Full deck of all identity-fit images.
    static let allCards: [StyleCard] = IdentityFitsCatalog.all.map { StyleCard(imageName: $0) }

    /// Returns the full card pool for the given deck kind.
    /// All kinds currently share the same 53-image pool.
    static func deck(for kind: StyleDeckKind) -> [StyleCard] {
        allCards
    }
}
