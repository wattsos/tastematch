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
        var result: [Tip] = []

        // 1. Axis-based primary tip (from dominant axis)
        let vector = TasteEngine.vectorFromProfile(profile)
        let axisScores = AxisMapping.computeAxisScores(from: vector)
        let dominant = axisScores.dominantAxis
        let dominantPositive = axisScores.value(for: dominant) >= 0
        let axisKey = AxisTipKey(axis: dominant, positive: dominantPositive)
        if let tip = axisTips[axisKey] {
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

        // 5. Blend tip if multiple axis influences
        if result.count < 3 {
            result.append(blendTip(profile: profile))
        }

        return Array(result.prefix(3))
    }
}

// MARK: - Axis Tips

private extension DesignTipsEngine {

    struct AxisTipKey: Hashable {
        let axis: Axis
        let positive: Bool
    }

    static let axisTips: [AxisTipKey: Tip] = [
        AxisTipKey(axis: .minimalOrnate, positive: false): Tip(
            icon: "square.dashed",
            headline: "Edit one thing out",
            body: "Your minimal instinct values restraint. Walk through the room and remove one object — the breathing space you create is the design."
        ),
        AxisTipKey(axis: .minimalOrnate, positive: true): Tip(
            icon: "diamond",
            headline: "Go bold on one surface",
            body: "Your ornate sensibility loves density. Try a patterned wallpaper or a richly framed mirror on a single accent wall."
        ),
        AxisTipKey(axis: .warmCool, positive: true): Tip(
            icon: "flame",
            headline: "Anchor with warm material",
            body: "Your warm instinct deepens with character. Look for reclaimed or live-edge pieces — imperfections are features, not flaws."
        ),
        AxisTipKey(axis: .warmCool, positive: false): Tip(
            icon: "sun.max",
            headline: "Chase the light",
            body: "Your cool register pairs naturally with daylight. Swap heavy drapes for sheer linen curtains and watch the room transform."
        ),
        AxisTipKey(axis: .softStructured, positive: true): Tip(
            icon: "books.vertical",
            headline: "Invest in symmetry",
            body: "Your structured instinct loves balance. Try matching table lamps flanking a sofa or identical frames on either side of a mantle."
        ),
        AxisTipKey(axis: .softStructured, positive: false): Tip(
            icon: "bed.double",
            headline: "Double down on softness",
            body: "Your soft instinct thrives on ease. Add a chunky knit throw or a linen bedspread to deepen that relaxed feel."
        ),
        AxisTipKey(axis: .organicIndustrial, positive: true): Tip(
            icon: "lightbulb",
            headline: "Expose one raw element",
            body: "Your raw instinct thrives on honesty. If you can't expose brick or ductwork, try an open-frame bookshelf or wire-cage pendant."
        ),
        AxisTipKey(axis: .organicIndustrial, positive: false): Tip(
            icon: "leaf",
            headline: "Bring nature inside",
            body: "Your organic instinct values imperfect beauty. A hand-thrown ceramic vase or a living plant wall adds quiet soul."
        ),
        AxisTipKey(axis: .lightDark, positive: false): Tip(
            icon: "sun.horizon",
            headline: "Maximize natural light",
            body: "Your light register opens up with airy surfaces. Consider lighter wood tones and reflective materials to amplify the brightness."
        ),
        AxisTipKey(axis: .lightDark, positive: true): Tip(
            icon: "moon.stars",
            headline: "Lean into shadow",
            body: "Your dark register gains depth with intimate lighting. Layer warm-toned spots to create pools of atmosphere."
        ),
        AxisTipKey(axis: .neutralSaturated, positive: false): Tip(
            icon: "circle.lefthalf.filled",
            headline: "Add one accent color",
            body: "Your neutral palette is a perfect canvas. Introduce a single accent — sage, slate, or navy — through cushions or art."
        ),
        AxisTipKey(axis: .neutralSaturated, positive: true): Tip(
            icon: "paintpalette",
            headline: "Layer color fearlessly",
            body: "Your vivid instinct lives in saturation. Mix a bold rug with a printed throw and chromatic cushions — commit to the energy."
        ),
        AxisTipKey(axis: .sparseLayered, positive: false): Tip(
            icon: "rectangle.split.3x1",
            headline: "Keep surfaces clear",
            body: "Your spare instinct values open planes. Display only what you use daily and store the rest — negative space is the design."
        ),
        AxisTipKey(axis: .sparseLayered, positive: true): Tip(
            icon: "rectangle.3.group",
            headline: "Build density with intent",
            body: "Your layered instinct thrives on accumulation. Group objects in clusters of three — a vase, a candle, a small sculpture — to build narrative."
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

    static func blendTip(profile: TasteProfile) -> Tip {
        let vector = TasteEngine.vectorFromProfile(profile)
        let axisScores = AxisMapping.computeAxisScores(from: vector)
        let phrases = AxisPresentation.influencePhrases(axisScores: axisScores)
        let primaryLabel = phrases.first ?? "primary"
        let secondaryLabel = phrases.dropFirst().first ?? "secondary"
        return Tip(
            icon: "arrow.triangle.merge",
            headline: "Blend your two sides",
            body: "Your \(primaryLabel.lowercased()) and \(secondaryLabel.lowercased()) leanings create a unique mix. Use one direction for structure (furniture) and the other for soul (textiles, art)."
        )
    }
}
