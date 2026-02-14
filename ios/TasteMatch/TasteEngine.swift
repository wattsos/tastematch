import Foundation

// MARK: - Visual Signal Types

enum PaletteTemperature: String, CaseIterable {
    // Ordered for adjacency scoring: cool ↔ neutral ↔ warm
    case cool, neutral, warm
}

enum Brightness: String, CaseIterable {
    case low, medium, high
}

enum Contrast: String, CaseIterable {
    case low, medium, high
}

enum Saturation: String, CaseIterable {
    case muted, neutral, vivid
}

enum EdgeDensity: String, CaseIterable {
    case low, medium, high
}

enum Material: String, CaseIterable {
    case wood, metal, textile, mixed
}

struct VisualSignals {
    let paletteTemperature: PaletteTemperature
    let brightness: Brightness
    let contrast: Contrast
    let saturation: Saturation
    let edgeDensity: EdgeDensity
    let material: Material
}

// MARK: - Taste Engine

struct TasteEngine {

    /// The 10 canonical taste tags the engine can assign.
    enum CanonicalTag: String, CaseIterable {
        case midCenturyModern = "Mid-Century Modern"
        case scandinavian     = "Scandinavian"
        case industrial       = "Industrial"
        case bohemian         = "Bohemian"
        case minimalist       = "Minimalist"
        case traditional      = "Traditional"
        case coastal          = "Coastal"
        case rustic           = "Rustic"
        case artDeco          = "Art Deco"
        case japandi          = "Japandi"
    }

    /// Produce a `TasteProfile` deterministically from visual signals, room context, and design goal.
    static func analyze(
        signals: VisualSignals,
        context: RoomContext,
        goal: DesignGoal
    ) -> TasteProfile {
        // 1. Score every canonical tag against the signals.
        var scored = CanonicalTag.allCases.map { tag -> (tag: CanonicalTag, score: Double) in
            var raw = 0.0
            let p = Self.idealProfile(for: tag)

            raw += ordinalMatch(signals.paletteTemperature, p.palette)
            raw += ordinalMatch(signals.brightness, p.brightness)
            raw += ordinalMatch(signals.contrast, p.contrast)
            raw += ordinalMatch(signals.saturation, p.saturation)
            raw += ordinalMatch(signals.edgeDensity, p.edgeDensity)
            raw += materialMatch(signals.material, p.material)

            // Normalize six dimensions → 0-1
            var confidence = raw / 6.0

            // Context boost (small)
            if let boost = Self.contextBoosts[context]?[tag] {
                confidence += boost
            }

            // Goal multiplier
            confidence *= Self.goalMultiplier(for: goal)

            return (tag, clamp01(confidence))
        }

        // 2. Stable sort: highest score first, tag name ascending breaks ties.
        scored.sort {
            if $0.score != $1.score { return $0.score > $1.score }
            return String(describing: $0.tag) < String(describing: $1.tag)
        }

        let primary = scored[0]
        let secondary: (tag: CanonicalTag, score: Double)? =
            scored[1].score >= 0.4 ? scored[1] : nil

        // 3. Build TasteTag array.
        var tags = [TasteTag(key: String(describing: primary.tag), label: primary.tag.rawValue, confidence: rounded(primary.score))]
        if let sec = secondary {
            tags.append(TasteTag(key: String(describing: sec.tag), label: sec.tag.rawValue, confidence: rounded(sec.score)))
        }

        // 4. Build Signal list from the raw visual signals.
        let signalList = [
            Signal(key: "palette_temperature", value: signals.paletteTemperature.rawValue),
            Signal(key: "brightness",          value: signals.brightness.rawValue),
            Signal(key: "contrast",            value: signals.contrast.rawValue),
            Signal(key: "saturation",          value: signals.saturation.rawValue),
            Signal(key: "edge_density",        value: signals.edgeDensity.rawValue),
            Signal(key: "material",            value: signals.material.rawValue),
        ]

        // 5. Deterministic story.
        let story = Self.buildStory(
            primary: primary.tag,
            secondary: secondary?.tag,
            signals: signals,
            context: context,
            goal: goal
        )

        return TasteProfile(tags: tags, story: story, signals: signalList)
    }

    /// Convert a canonical tag key (e.g. "scandinavian") to its display label (e.g. "Scandinavian").
    static func displayLabel(for tagKey: String) -> String {
        CanonicalTag.allCases.first { String(describing: $0) == tagKey }?.rawValue ?? tagKey
    }

    /// Convert a TasteProfile's tags into a TasteVector (tag key → confidence as weight).
    static func vectorFromProfile(_ profile: TasteProfile) -> TasteVector {
        var weights: [String: Double] = [:]
        for tag in CanonicalTag.allCases {
            weights[String(describing: tag)] = 0.0
        }
        for tag in profile.tags {
            weights[tag.key] = tag.confidence
        }
        return TasteVector(weights: weights)
    }
}

// MARK: - Ideal Profiles

private extension TasteEngine {

    struct IdealProfile {
        let palette: PaletteTemperature
        let brightness: Brightness
        let contrast: Contrast
        let saturation: Saturation
        let edgeDensity: EdgeDensity
        let material: Material
    }

    //                                        palette   bright  contrast  sat      edges    material
    static func idealProfile(for tag: CanonicalTag) -> IdealProfile {
        switch tag {
        case .midCenturyModern: return .init(palette: .warm,    brightness: .medium, contrast: .medium, saturation: .neutral, edgeDensity: .medium, material: .wood)
        case .scandinavian:     return .init(palette: .cool,    brightness: .high,   contrast: .low,    saturation: .muted,   edgeDensity: .low,    material: .wood)
        case .industrial:       return .init(palette: .cool,    brightness: .low,    contrast: .high,   saturation: .muted,   edgeDensity: .high,   material: .metal)
        case .bohemian:         return .init(palette: .warm,    brightness: .medium, contrast: .low,    saturation: .vivid,   edgeDensity: .high,   material: .textile)
        case .minimalist:       return .init(palette: .neutral, brightness: .high,   contrast: .low,    saturation: .muted,   edgeDensity: .low,    material: .mixed)
        case .traditional:      return .init(palette: .warm,    brightness: .medium, contrast: .medium, saturation: .neutral, edgeDensity: .medium, material: .wood)
        case .coastal:          return .init(palette: .cool,    brightness: .high,   contrast: .low,    saturation: .neutral, edgeDensity: .low,    material: .textile)
        case .rustic:           return .init(palette: .warm,    brightness: .low,    contrast: .high,   saturation: .muted,   edgeDensity: .medium, material: .wood)
        case .artDeco:          return .init(palette: .warm,    brightness: .medium, contrast: .high,   saturation: .vivid,   edgeDensity: .high,   material: .metal)
        case .japandi:          return .init(palette: .neutral, brightness: .high,   contrast: .low,    saturation: .muted,   edgeDensity: .low,    material: .wood)
        }
    }
}

// MARK: - Scoring Helpers

private extension TasteEngine {

    /// Ordinal match for any 3-value enum ordered in its `CaseIterable` declaration.
    /// Exact → 1.0, adjacent → 0.5, opposite → 0.0
    static func ordinalMatch<T: CaseIterable & RawRepresentable>(
        _ input: T, _ ideal: T
    ) -> Double where T.RawValue == String {
        let cases = Array(T.allCases)
        guard let i = cases.firstIndex(where: { $0.rawValue == input.rawValue }),
              let j = cases.firstIndex(where: { $0.rawValue == ideal.rawValue }) else {
            return 0
        }
        let distance = abs(cases.distance(from: i, to: j))
        switch distance {
        case 0:  return 1.0
        case 1:  return 0.5
        default: return 0.0
        }
    }

    /// Material match: exact → 1.0, mixed ↔ anything → 0.5, mismatch → 0.0
    static func materialMatch(_ input: Material, _ ideal: Material) -> Double {
        if input == ideal { return 1.0 }
        if input == .mixed || ideal == .mixed { return 0.5 }
        return 0.0
    }

    static func clamp01(_ v: Double) -> Double { min(1, max(0, v)) }
    static func rounded(_ v: Double) -> Double { (v * 100).rounded() / 100 }
}

// MARK: - Context & Goal Modifiers

private extension TasteEngine {

    static let contextBoosts: [RoomContext: [CanonicalTag: Double]] = [
        .livingRoom: [.midCenturyModern: 0.05, .bohemian: 0.05, .scandinavian: 0.03],
        .bedroom:    [.scandinavian: 0.05, .japandi: 0.05, .minimalist: 0.03],
        .kitchen:    [.industrial: 0.05, .rustic: 0.05, .scandinavian: 0.03],
        .office:     [.minimalist: 0.05, .industrial: 0.05, .midCenturyModern: 0.03],
        .bathroom:   [.minimalist: 0.05, .coastal: 0.05, .japandi: 0.03],
        .outdoor:    [.coastal: 0.05, .rustic: 0.05, .bohemian: 0.03],
    ]

    static func goalMultiplier(for goal: DesignGoal) -> Double {
        switch goal {
        case .refresh:   return 1.0
        case .overhaul:  return 1.1
        case .accent:    return 0.9
        case .organize:  return 0.95
        }
    }
}

// MARK: - Story Generation

private extension TasteEngine {

    static let paletteDescriptions: [PaletteTemperature: String] = [
        .warm:    "warm, inviting tones",
        .cool:    "cool, calming hues",
        .neutral: "balanced, grounded neutrals",
    ]

    static let brightnessDescriptions: [Brightness: String] = [
        .low:    "moody, intimate lighting",
        .medium: "comfortable ambient light",
        .high:   "bright, airy spaces",
    ]

    static let materialDescriptions: [Material: String] = [
        .wood:    "natural wood surfaces",
        .metal:   "metallic finishes and hardware",
        .textile: "rich textiles and fabrics",
        .mixed:   "an eclectic mix of materials",
    ]

    static let goalPhrases: [DesignGoal: String] = [
        .refresh:  "A few targeted swaps",
        .overhaul: "A full reimagining of the space",
        .accent:   "Some well-chosen accent pieces",
        .organize: "A streamlined, decluttered layout",
    ]

    static func buildStory(
        primary: CanonicalTag,
        secondary: CanonicalTag?,
        signals: VisualSignals,
        context: RoomContext,
        goal: DesignGoal
    ) -> String {
        // Build a lightweight vector from primary/secondary to compute axis scores
        var weights: [String: Double] = [:]
        for tag in CanonicalTag.allCases {
            weights[String(describing: tag)] = 0.0
        }
        weights[String(describing: primary)] = 1.0
        if let sec = secondary {
            weights[String(describing: sec)] = 0.6
        }
        let vector = TasteVector(weights: weights)
        let axisScores = AxisMapping.computeAxisScores(from: vector)

        let palette     = paletteDescriptions[signals.paletteTemperature]!
        let brightness  = brightnessDescriptions[signals.brightness]!
        let material    = materialDescriptions[signals.material]!
        let goalPhrase  = goalPhrases[goal]!
        let room        = context.rawValue.lowercased()

        return AxisPresentation.storyText(
            axisScores: axisScores,
            palette: palette,
            brightness: brightness,
            material: material,
            room: room,
            goal: goalPhrase
        )
    }
}
