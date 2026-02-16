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
    let title: String
    let subtitle: String
    let imageName: String   // Asset catalog name (placeholder for now)
    let symbol: String      // SF Symbol fallback while assets are missing
}

// MARK: - Seed Decks

enum StyleSeedDeck {

    static func deck(for kind: StyleDeckKind) -> [StyleCard] {
        switch kind {
        case .menswear:  return menswear
        case .womenswear: return womenswear
        case .any:       return any
        }
    }

    // MARK: Menswear — 16 cards

    static let menswear: [StyleCard] = [
        StyleCard(title: "Oversized Wool Coat", subtitle: "Layered", imageName: "mens_wool_coat", symbol: "figure.stand"),
        StyleCard(title: "Raw Denim & White Tee", subtitle: "Minimal", imageName: "mens_raw_denim", symbol: "tshirt"),
        StyleCard(title: "Tailored Linen Suit", subtitle: "Summer Formal", imageName: "mens_linen_suit", symbol: "figure.stand.dress"),
        StyleCard(title: "Workwear Chore Jacket", subtitle: "Utility", imageName: "mens_chore_jacket", symbol: "hammer"),
        StyleCard(title: "Leather Bomber", subtitle: "Vintage", imageName: "mens_leather_bomber", symbol: "airplane"),
        StyleCard(title: "Relaxed Pleated Trousers", subtitle: "Wide Leg", imageName: "mens_pleated_trousers", symbol: "figure.walk"),
        StyleCard(title: "Cable Knit Fisherman", subtitle: "Heritage", imageName: "mens_cable_knit", symbol: "cloud"),
        StyleCard(title: "Black Turtleneck", subtitle: "Uniform", imageName: "mens_turtleneck", symbol: "circle.fill"),
        StyleCard(title: "Camp Collar Shirt", subtitle: "Resort", imageName: "mens_camp_collar", symbol: "sun.max"),
        StyleCard(title: "Waxed Cotton Parka", subtitle: "Outdoor", imageName: "mens_waxed_parka", symbol: "cloud.rain"),
        StyleCard(title: "Double-Breasted Blazer", subtitle: "Sharp", imageName: "mens_db_blazer", symbol: "rectangle.portrait"),
        StyleCard(title: "Track Pants & Loafers", subtitle: "Contrast", imageName: "mens_track_loafer", symbol: "shoe"),
        StyleCard(title: "Cropped Trucker Jacket", subtitle: "Street", imageName: "mens_trucker", symbol: "car"),
        StyleCard(title: "Silk Pajama Set", subtitle: "Louche", imageName: "mens_silk_pajama", symbol: "moon"),
        StyleCard(title: "Military Cargo Fit", subtitle: "Tactical", imageName: "mens_cargo", symbol: "shield"),
        StyleCard(title: "Knit Polo & Slacks", subtitle: "Smart Casual", imageName: "mens_knit_polo", symbol: "person"),
    ]

    // MARK: Womenswear — 16 cards

    static let womenswear: [StyleCard] = [
        StyleCard(title: "Draped Midi Dress", subtitle: "Fluid", imageName: "womens_midi_dress", symbol: "figure.dress.line.vertical.figure"),
        StyleCard(title: "Oversized Blazer & Jeans", subtitle: "Power Casual", imageName: "womens_blazer_jeans", symbol: "rectangle.portrait"),
        StyleCard(title: "Knit Co-ord Set", subtitle: "Elevated Lounge", imageName: "womens_knit_coord", symbol: "circle.grid.2x2"),
        StyleCard(title: "Leather Trench", subtitle: "Edge", imageName: "womens_leather_trench", symbol: "bolt"),
        StyleCard(title: "Linen Wide-Leg Pants", subtitle: "Effortless", imageName: "womens_linen_wide", symbol: "wind"),
        StyleCard(title: "Silk Slip Dress", subtitle: "Evening", imageName: "womens_silk_slip", symbol: "moon.stars"),
        StyleCard(title: "Tailored Jumpsuit", subtitle: "Structured", imageName: "womens_jumpsuit", symbol: "figure.stand"),
        StyleCard(title: "Cropped Boxy Jacket", subtitle: "Architectural", imageName: "womens_boxy_jacket", symbol: "square"),
        StyleCard(title: "Pleated Maxi Skirt", subtitle: "Movement", imageName: "womens_pleated_maxi", symbol: "figure.walk"),
        StyleCard(title: "Cashmere Hoodie Layer", subtitle: "Luxury Casual", imageName: "womens_cashmere_hoodie", symbol: "cloud"),
        StyleCard(title: "Statement Shoulder Top", subtitle: "Bold", imageName: "womens_shoulder_top", symbol: "arrow.up.left.and.arrow.down.right"),
        StyleCard(title: "High-Waist Trousers", subtitle: "Classic", imageName: "womens_hw_trousers", symbol: "line.horizontal.3"),
        StyleCard(title: "Sheer Layer Over Tank", subtitle: "Texture Play", imageName: "womens_sheer_layer", symbol: "square.on.square"),
        StyleCard(title: "Denim-on-Denim", subtitle: "Canadian Tuxedo", imageName: "womens_double_denim", symbol: "rectangle.on.rectangle"),
        StyleCard(title: "Wrap Coat", subtitle: "Timeless", imageName: "womens_wrap_coat", symbol: "leaf"),
        StyleCard(title: "Combat Boots & Midi", subtitle: "Contrast", imageName: "womens_combat_midi", symbol: "shoe"),
    ]

    // MARK: Any — 16 cards (unisex / mixed)

    static let any: [StyleCard] = [
        StyleCard(title: "Oversized Wool Coat", subtitle: "Layered", imageName: "any_wool_coat", symbol: "figure.stand"),
        StyleCard(title: "Draped Midi Dress", subtitle: "Fluid", imageName: "any_midi_dress", symbol: "figure.dress.line.vertical.figure"),
        StyleCard(title: "Raw Denim & White Tee", subtitle: "Minimal", imageName: "any_raw_denim", symbol: "tshirt"),
        StyleCard(title: "Leather Trench", subtitle: "Edge", imageName: "any_leather_trench", symbol: "bolt"),
        StyleCard(title: "Relaxed Pleated Trousers", subtitle: "Wide Leg", imageName: "any_pleated_trousers", symbol: "figure.walk"),
        StyleCard(title: "Silk Slip Dress", subtitle: "Evening", imageName: "any_silk_slip", symbol: "moon.stars"),
        StyleCard(title: "Workwear Chore Jacket", subtitle: "Utility", imageName: "any_chore_jacket", symbol: "hammer"),
        StyleCard(title: "Knit Co-ord Set", subtitle: "Elevated Lounge", imageName: "any_knit_coord", symbol: "circle.grid.2x2"),
        StyleCard(title: "Black Turtleneck", subtitle: "Uniform", imageName: "any_turtleneck", symbol: "circle.fill"),
        StyleCard(title: "Tailored Jumpsuit", subtitle: "Structured", imageName: "any_jumpsuit", symbol: "figure.stand"),
        StyleCard(title: "Camp Collar Shirt", subtitle: "Resort", imageName: "any_camp_collar", symbol: "sun.max"),
        StyleCard(title: "Cashmere Hoodie Layer", subtitle: "Luxury Casual", imageName: "any_cashmere_hoodie", symbol: "cloud"),
        StyleCard(title: "Track Pants & Loafers", subtitle: "Contrast", imageName: "any_track_loafer", symbol: "shoe"),
        StyleCard(title: "Sheer Layer Over Tank", subtitle: "Texture Play", imageName: "any_sheer_layer", symbol: "square.on.square"),
        StyleCard(title: "Waxed Cotton Parka", subtitle: "Outdoor", imageName: "any_waxed_parka", symbol: "cloud.rain"),
        StyleCard(title: "Combat Boots & Midi", subtitle: "Contrast", imageName: "any_combat_midi", symbol: "shoe"),
    ]
}
