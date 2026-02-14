import Foundation

/// Generates 2-3 contextual design tips based on the user's taste profile.
enum DesignTipsEngine {

    struct Tip: Identifiable {
        let id = UUID()
        let icon: String
        let headline: String
        let body: String
    }

    static func tips(
        for profile: TasteProfile,
        context: RoomContext? = nil,
        goal: DesignGoal? = nil
    ) -> [Tip] {
        let primaryKey = profile.tags.first?.key
        let secondaryKey = profile.tags.dropFirst().first?.key

        var result: [Tip] = []

        // 1. Primary style tip
        if let key = primaryKey, let tip = styleTips[key] {
            result.append(tip)
        }

        // 2. Signal-based tip (palette + material)
        let palette = profile.signals.first(where: { $0.key == "palette_temperature" })?.value
        let material = profile.signals.first(where: { $0.key == "material" })?.value
        if let tip = signalTip(palette: palette, material: material) {
            result.append(tip)
        }

        // 3. Room-specific tip
        if let room = context, let tip = roomTips[room] {
            result.append(tip)
        }

        // 4. Goal-based tip (only if we need a third)
        if result.count < 3, let g = goal, let tip = goalTips[g] {
            result.append(tip)
        }

        // 5. Blend tip if two styles detected
        if result.count < 3, let sec = secondaryKey, let primary = primaryKey {
            result.append(blendTip(primary: primary, secondary: sec))
        }

        return Array(result.prefix(3))
    }
}

// MARK: - Style Tips

private extension DesignTipsEngine {

    static let styleTips: [String: Tip] = [
        "midCenturyModern": Tip(
            icon: "chair.lounge",
            headline: "Anchor with a statement piece",
            body: "Your mid-century eye loves clean silhouettes. Try a single iconic chair or credenza as the room's focal point — let everything else orbit it."
        ),
        "scandinavian": Tip(
            icon: "sun.max",
            headline: "Chase the light",
            body: "Your Scandinavian taste pairs naturally with daylight. Swap heavy drapes for sheer linen curtains and watch the room transform."
        ),
        "industrial": Tip(
            icon: "lightbulb",
            headline: "Expose one raw element",
            body: "Your industrial instinct thrives on honesty. If you can't expose brick or ductwork, try an open-frame bookshelf or wire-cage pendant."
        ),
        "bohemian": Tip(
            icon: "paintpalette",
            headline: "Layer patterns fearlessly",
            body: "Your boho spirit lives in texture. Mix a kilim rug with a printed throw and embroidered cushions — the more personal, the better."
        ),
        "minimalist": Tip(
            icon: "square.dashed",
            headline: "Edit one thing out",
            body: "Your minimalist eye values restraint. Walk through the room and remove one object — the breathing space you create is the design."
        ),
        "traditional": Tip(
            icon: "books.vertical",
            headline: "Invest in symmetry",
            body: "Your classic taste loves balance. Try matching table lamps flanking a sofa or identical frames on either side of a mantle."
        ),
        "coastal": Tip(
            icon: "water.waves",
            headline: "Bring in natural fiber",
            body: "Your coastal soul craves texture from the shore. A jute rug or rattan accent chair instantly grounds the breezy palette."
        ),
        "rustic": Tip(
            icon: "tree",
            headline: "Let wood tell a story",
            body: "Your rustic warmth deepens with character. Look for reclaimed or live-edge pieces — imperfections are features, not flaws."
        ),
        "artDeco": Tip(
            icon: "diamond",
            headline: "Go bold on one surface",
            body: "Your Art Deco sensibility loves drama. Try a geometric-patterned wallpaper or a gold-framed mirror on a single accent wall."
        ),
        "japandi": Tip(
            icon: "leaf",
            headline: "Embrace wabi-sabi",
            body: "Your Japandi aesthetic values imperfect beauty. A hand-thrown ceramic vase or an unfinished wood bowl adds quiet soul."
        ),
    ]
}

// MARK: - Signal Tips

private extension DesignTipsEngine {

    static func signalTip(palette: String?, material: String?) -> Tip? {
        switch (palette, material) {
        case ("warm", "wood"):
            return Tip(
                icon: "flame",
                headline: "Warm it up with amber light",
                body: "Your warm wood tones glow under 2700K bulbs. Swap cool-white LEDs for warm ones to amplify the coziness."
            )
        case ("warm", "textile"):
            return Tip(
                icon: "bed.double",
                headline: "Double down on softness",
                body: "Your warm textile palette loves layering. Add a chunky knit throw or a linen bedspread to deepen that inviting feel."
            )
        case ("cool", "metal"):
            return Tip(
                icon: "sparkle",
                headline: "Polish meets patina",
                body: "Your cool metallic palette shines with contrast. Mix brushed steel with a matte black accent for industrial depth."
            )
        case ("cool", "wood"):
            return Tip(
                icon: "snowflake",
                headline: "Lighten the wood tone",
                body: "Your cool palette pairs best with ash or white oak. If your wood runs dark, balance with light textiles."
            )
        case ("neutral", _):
            return Tip(
                icon: "circle.lefthalf.filled",
                headline: "Add one accent color",
                body: "Your balanced neutrals are a perfect canvas. Introduce a single accent — sage, slate, or navy — through cushions or art."
            )
        default:
            return nil
        }
    }
}

// MARK: - Room Tips

private extension DesignTipsEngine {

    static let roomTips: [RoomContext: Tip] = [
        .livingRoom: Tip(
            icon: "sofa",
            headline: "Create a conversation zone",
            body: "Pull furniture slightly away from the walls and angle seats toward each other. It feels more intimate and intentional."
        ),
        .bedroom: Tip(
            icon: "moon.stars",
            headline: "Keep tech out of sight",
            body: "Your bedroom is for rest. Hide chargers in a drawer, skip the TV mount, and let the room breathe calm."
        ),
        .kitchen: Tip(
            icon: "frying.pan",
            headline: "Display what you use",
            body: "Open shelving with your favorite ceramics and cookbooks turns function into decor. Curate, don't clutter."
        ),
        .office: Tip(
            icon: "desktopcomputer",
            headline: "Zone your desk",
            body: "Keep your primary work surface clear. Move reference items and supplies to a side table or shelf within arm's reach."
        ),
        .bathroom: Tip(
            icon: "drop",
            headline: "Upgrade the small things",
            body: "Swap out the soap dispenser, towel hooks, and bath mat. Three small changes make a bathroom feel fully renovated."
        ),
        .outdoor: Tip(
            icon: "sun.horizon",
            headline: "Layer outdoor lighting",
            body: "String lights overhead, lanterns at ground level, and a candle on the table. Three layers turn a patio into a destination."
        ),
    ]
}

// MARK: - Goal Tips

private extension DesignTipsEngine {

    static let goalTips: [DesignGoal: Tip] = [
        .refresh: Tip(
            icon: "arrow.triangle.2.circlepath",
            headline: "Swap, don't shop",
            body: "Before buying anything new, try moving pieces between rooms. A lamp from the bedroom might be the living room's missing accent."
        ),
        .overhaul: Tip(
            icon: "rectangle.3.group",
            headline: "Start with the floor plan",
            body: "Before choosing a single piece, sketch the layout. Where people walk and sit matters more than what sits on a shelf."
        ),
        .accent: Tip(
            icon: "paintbrush.pointed",
            headline: "Use the rule of three",
            body: "Group accent objects in threes — a vase, a candle, and a small sculpture. Odd numbers feel more natural to the eye."
        ),
        .organize: Tip(
            icon: "tray.2",
            headline: "One in, one out",
            body: "For every new piece you bring in, let one go. It keeps the space intentional and prevents re-cluttering."
        ),
    ]
}

// MARK: - Blend Tip

private extension DesignTipsEngine {

    static func blendTip(primary: String, secondary: String) -> Tip {
        let primaryLabel = TasteBadge.badgeMap[primary]?.title ?? primary
        let secondaryLabel = TasteBadge.badgeMap[secondary]?.title ?? secondary
        return Tip(
            icon: "arrow.triangle.merge",
            headline: "Blend your two sides",
            body: "Your \(primaryLabel) and \(secondaryLabel) leanings create a unique mix. Use one style for structure (furniture) and the other for soul (textiles, art)."
        )
    }
}
