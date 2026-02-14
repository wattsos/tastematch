import Foundation

// MARK: - Axis

enum Axis: String, CaseIterable {
    case minimalOrnate
    case warmCool
    case softStructured
    case organicIndustrial
    case lightDark
    case neutralSaturated
    case sparseLayered
}

// MARK: - Axis Scores

struct AxisScores: Equatable {
    var minimalOrnate: Double       // -1 = minimal, +1 = ornate
    var warmCool: Double            // -1 = cool, +1 = warm
    var softStructured: Double      // -1 = soft, +1 = structured
    var organicIndustrial: Double   // -1 = organic, +1 = industrial
    var lightDark: Double           // -1 = light, +1 = dark
    var neutralSaturated: Double    // -1 = neutral, +1 = saturated
    var sparseLayered: Double       // -1 = sparse, +1 = layered

    static let zero = AxisScores(
        minimalOrnate: 0, warmCool: 0, softStructured: 0,
        organicIndustrial: 0, lightDark: 0, neutralSaturated: 0,
        sparseLayered: 0
    )

    func value(for axis: Axis) -> Double {
        switch axis {
        case .minimalOrnate:      return minimalOrnate
        case .warmCool:           return warmCool
        case .softStructured:     return softStructured
        case .organicIndustrial:  return organicIndustrial
        case .lightDark:          return lightDark
        case .neutralSaturated:   return neutralSaturated
        case .sparseLayered:      return sparseLayered
        }
    }

    var dominantAxis: Axis {
        Axis.allCases.max(by: { abs(value(for: $0)) < abs(value(for: $1)) })!
    }

    var secondaryAxis: Axis? {
        let sorted = Axis.allCases.sorted { abs(value(for: $0)) > abs(value(for: $1)) }
        guard sorted.count >= 2, abs(value(for: sorted[1])) > 0.15 else { return nil }
        return sorted[1]
    }
}

// MARK: - Axis Mapping

enum AxisMapping {

    static let contributions: [String: AxisScores] = [
        "midCenturyModern": AxisScores(
            minimalOrnate: -0.3, warmCool: 0.7, softStructured: 0.2,
            organicIndustrial: -0.4, lightDark: 0.0, neutralSaturated: 0.0, sparseLayered: -0.1
        ),
        "scandinavian": AxisScores(
            minimalOrnate: -0.8, warmCool: -0.4, softStructured: -0.3,
            organicIndustrial: -0.3, lightDark: -0.7, neutralSaturated: -0.5, sparseLayered: -0.6
        ),
        "industrial": AxisScores(
            minimalOrnate: -0.2, warmCool: -0.5, softStructured: 0.8,
            organicIndustrial: 0.9, lightDark: 0.7, neutralSaturated: -0.3, sparseLayered: 0.3
        ),
        "bohemian": AxisScores(
            minimalOrnate: 0.8, warmCool: 0.8, softStructured: -0.6,
            organicIndustrial: -0.7, lightDark: 0.0, neutralSaturated: 0.6, sparseLayered: 0.9
        ),
        "minimalist": AxisScores(
            minimalOrnate: -0.9, warmCool: 0.0, softStructured: 0.3,
            organicIndustrial: 0.0, lightDark: -0.5, neutralSaturated: -0.6, sparseLayered: -0.8
        ),
        "traditional": AxisScores(
            minimalOrnate: 0.6, warmCool: 0.7, softStructured: 0.4,
            organicIndustrial: -0.3, lightDark: 0.1, neutralSaturated: 0.2, sparseLayered: 0.5
        ),
        "coastal": AxisScores(
            minimalOrnate: -0.4, warmCool: -0.3, softStructured: -0.5,
            organicIndustrial: -0.4, lightDark: -0.6, neutralSaturated: -0.2, sparseLayered: -0.3
        ),
        "rustic": AxisScores(
            minimalOrnate: 0.3, warmCool: 0.8, softStructured: 0.5,
            organicIndustrial: -0.5, lightDark: 0.6, neutralSaturated: -0.3, sparseLayered: 0.4
        ),
        "artDeco": AxisScores(
            minimalOrnate: 0.9, warmCool: 0.4, softStructured: 0.7,
            organicIndustrial: 0.3, lightDark: 0.2, neutralSaturated: 0.8, sparseLayered: 0.7
        ),
        "japandi": AxisScores(
            minimalOrnate: -0.7, warmCool: 0.2, softStructured: -0.2,
            organicIndustrial: -0.3, lightDark: -0.6, neutralSaturated: -0.5, sparseLayered: -0.7
        ),
    ]

    static func computeAxisScores(from vector: TasteVector) -> AxisScores {
        let weights = vector.weights
        let totalWeight = weights.values.map { abs($0) }.reduce(0, +)
        guard totalWeight > 0 else { return .zero }

        var mo = 0.0, wc = 0.0, ss = 0.0, oi = 0.0, ld = 0.0, ns = 0.0, sl = 0.0

        for (tag, weight) in weights {
            guard let c = contributions[tag] else { continue }
            mo += weight * c.minimalOrnate
            wc += weight * c.warmCool
            ss += weight * c.softStructured
            oi += weight * c.organicIndustrial
            ld += weight * c.lightDark
            ns += weight * c.neutralSaturated
            sl += weight * c.sparseLayered
        }

        return AxisScores(
            minimalOrnate:     clamp(mo / totalWeight),
            warmCool:          clamp(wc / totalWeight),
            softStructured:    clamp(ss / totalWeight),
            organicIndustrial: clamp(oi / totalWeight),
            lightDark:         clamp(ld / totalWeight),
            neutralSaturated:  clamp(ns / totalWeight),
            sparseLayered:     clamp(sl / totalWeight)
        )
    }

    private static func clamp(_ v: Double) -> Double { min(1, max(-1, v)) }
}

// MARK: - Structural Descriptor Resolver

enum StructuralDescriptorResolver {

    private static let pools: [(Axis, Bool, [String])] = [
        (.minimalOrnate, false,     ["Minimal", "Clean", "Spare", "Quiet"]),
        (.minimalOrnate, true,      ["Ornate", "Adorned", "Rich", "Elaborate"]),
        (.warmCool, true,           ["Warm", "Earth", "Sunlit"]),
        (.warmCool, false,          ["Cool", "Frost", "Nordic"]),
        (.softStructured, true,     ["Structured", "Rigid", "Composed"]),
        (.softStructured, false,    ["Soft", "Gentle", "Relaxed"]),
        (.organicIndustrial, true,  ["Industrial", "Brutal", "Concrete", "Raw"]),
        (.organicIndustrial, false, ["Organic", "Natural", "Verdant"]),
        (.lightDark, false,         ["Light", "Airy", "Bright"]),
        (.lightDark, true,          ["Dark", "Noir", "Midnight", "Studio"]),
        (.neutralSaturated, false,  ["Neutral", "Tonal", "Muted"]),
        (.neutralSaturated, true,   ["Saturated", "Vivid", "Chromatic"]),
        (.sparseLayered, false,     ["Sparse", "Open", "Reduced"]),
        (.sparseLayered, true,      ["Layered", "Textural", "Expressive"]),
    ]

    static func resolve(axisScores: AxisScores, basisHash: String) -> String {
        let dominant = axisScores.dominantAxis
        let value = axisScores.value(for: dominant)
        let isPositive = value >= 0

        guard let pool = pools.first(where: { $0.0 == dominant && $0.1 == isPositive }) else {
            return "Quiet"
        }

        let descriptors = pool.2
        let index = deterministicIndex(from: basisHash, multiplier: 31, count: descriptors.count)
        return descriptors[index]
    }

    static func deterministicIndex(from hash: String, multiplier: UInt64, count: Int) -> Int {
        guard count > 0 else { return 0 }
        let hashValue = hash.utf8.reduce(UInt64(0)) { ($0 &+ UInt64($1)) &* multiplier }
        return Int(hashValue % UInt64(count))
    }
}

// MARK: - Context Resolver

enum ContextResolver {

    private enum Cluster: CaseIterable {
        case industrialDark
        case warmOrganic
        case minimalNeutral
        case layeredSaturated
    }

    private static let clusterPools: [Cluster: [String]] = [
        .industrialDark:    ["Berlin", "Concrete", "Studio", "Metro", "Bushwick"],
        .warmOrganic:       ["Desert", "Lagos", "Garden", "Lisbon", "Nairobi"],
        .minimalNeutral:    ["Tokyo", "Milan", "Gallery", "Campus", "Atelier"],
        .layeredSaturated:  ["Havana", "Marrakech", "Athens", "Harbor"],
    ]

    static func resolve(axisScores: AxisScores, basisHash: String) -> String {
        let cluster = identifyCluster(axisScores)
        let pool = clusterPools[cluster]!
        let index = StructuralDescriptorResolver.deterministicIndex(
            from: basisHash, multiplier: 37, count: pool.count
        )
        return pool[index]
    }

    private static func identifyCluster(_ scores: AxisScores) -> Cluster {
        let clusters: [(Cluster, Double)] = [
            (.industrialDark,    scores.organicIndustrial + scores.lightDark),
            (.warmOrganic,       scores.warmCool - scores.organicIndustrial),
            (.minimalNeutral,    -scores.minimalOrnate - scores.neutralSaturated),
            (.layeredSaturated,  scores.sparseLayered + scores.neutralSaturated),
        ]
        return clusters.max(by: { $0.1 < $1.1 })!.0
    }
}

// MARK: - Profile Name Generator

enum ProfileNameGenerator {
    static func generate(from axisScores: AxisScores, basisHash: String) -> String {
        let context = ContextResolver.resolve(axisScores: axisScores, basisHash: basisHash)
        let descriptor = StructuralDescriptorResolver.resolve(axisScores: axisScores, basisHash: basisHash)
        return "\(context) \(descriptor)"
    }
}

// MARK: - Description Generator

enum DescriptionGenerator {

    static func generate(from axisScores: AxisScores) -> String {
        let dominant = axisScores.dominantAxis
        let secondary = axisScores.secondaryAxis
        let dominantPos = axisScores.value(for: dominant) >= 0

        if let sec = secondary {
            let secPos = axisScores.value(for: sec) >= 0
            if let combined = lookupCombined(dominant, dominantPos, sec, secPos)
                ?? lookupCombined(sec, secPos, dominant, dominantPos) {
                return combined
            }
        }

        return dominantOnly(dominant, positive: dominantPos)
    }

    private static func lookupCombined(_ a: Axis, _ aPos: Bool, _ b: Axis, _ bPos: Bool) -> String? {
        switch (a, aPos, b, bPos) {
        case (.organicIndustrial, true, .lightDark, true):
            return "Structured silhouettes with raw material depth and controlled contrast."
        case (.organicIndustrial, true, .softStructured, true):
            return "Raw material and rigid geometry define a space built on industrial logic."
        case (.warmCool, true, .organicIndustrial, false):
            return "Earth-driven texture with layered warmth and relaxed structure."
        case (.minimalOrnate, false, .neutralSaturated, false):
            return "Light, balanced form with disciplined negative space."
        case (.minimalOrnate, false, .lightDark, false):
            return "Restrained composition in an airy, open register."
        case (.minimalOrnate, false, .sparseLayered, false):
            return "Disciplined emptiness where negative space becomes the primary material."
        case (.minimalOrnate, false, .warmCool, false):
            return "Stripped-back clarity under a cool, Nordic register."
        case (.minimalOrnate, true, .neutralSaturated, true):
            return "Bold material confidence with chromatic intensity and decorative weight."
        case (.minimalOrnate, true, .sparseLayered, true):
            return "Ornamental density with layered narrative and deliberate maximalism."
        case (.warmCool, true, .sparseLayered, true):
            return "Warm, collected layers that build depth through accumulated texture."
        case (.warmCool, true, .lightDark, true):
            return "Grounded warmth deepened by shadow and rich tonal contrast."
        case (.warmCool, false, .softStructured, true):
            return "Precise geometry under a cool, controlled palette."
        case (.softStructured, false, .sparseLayered, false):
            return "Gentle forms in open space, favoring quiet over complexity."
        case (.softStructured, false, .lightDark, false):
            return "Airy softness with luminous, yielding surfaces."
        case (.lightDark, true, .sparseLayered, true):
            return "Deep, atmospheric stacking with moody material weight."
        default:
            return nil
        }
    }

    private static func dominantOnly(_ axis: Axis, positive: Bool) -> String {
        switch (axis, positive) {
        case (.minimalOrnate, false):
            return "Pared-back composition where every element earns its place."
        case (.minimalOrnate, true):
            return "Richly detailed surfaces with confident decorative presence."
        case (.warmCool, true):
            return "Grounded warmth that builds from natural material and earth tone."
        case (.warmCool, false):
            return "Cool restraint with a preference for clarity over comfort."
        case (.softStructured, true):
            return "Defined edges and deliberate proportion hold the composition taut."
        case (.softStructured, false):
            return "Soft contours and relaxed geometry, favoring ease over precision."
        case (.organicIndustrial, true):
            return "Raw industrial character with exposed material and urban edge."
        case (.organicIndustrial, false):
            return "Organic forms drawn from natural growth and handcraft."
        case (.lightDark, false):
            return "Open, light-filled planes that give visual breathing room."
        case (.lightDark, true):
            return "Deep tonal anchoring with intimate, shadow-rich atmosphere."
        case (.neutralSaturated, false):
            return "A tonal, desaturated palette that lets form lead over color."
        case (.neutralSaturated, true):
            return "Chromatic confidence with saturated, expressive color choices."
        case (.sparseLayered, false):
            return "Disciplined restraint, allowing negative space to define the room."
        case (.sparseLayered, true):
            return "Accumulated layers that build visual narrative through density."
        }
    }
}

// MARK: - Basis Hash Builder

enum BasisHashBuilder {

    static func build(axisScores: AxisScores, vector: TasteVector, swipeCount: Int) -> String {
        var parts: [String] = []

        for axis in Axis.allCases {
            parts.append(bucket(axisScores.value(for: axis)))
        }

        let topInfluences = vector.weights
            .sorted { $0.value > $1.value }
            .prefix(2)
            .map(\.key)
            .sorted()
        parts.append(contentsOf: topInfluences)

        parts.append(vector.confidenceLevel(swipeCount: swipeCount))

        return parts.joined(separator: "|")
    }

    private static func bucket(_ value: Double) -> String {
        let sign = value >= 0 ? "+" : "-"
        let magnitude: String
        switch abs(value) {
        case 0.5...: magnitude = "H"
        case 0.2...: magnitude = "M"
        default:     magnitude = "L"
        }
        return "\(sign)\(magnitude)"
    }
}

// MARK: - Profile Naming Result

struct ProfileNamingResult {
    let name: String
    let description: String
    let version: Int
    let basisHash: String
    let previousNames: [String]
    let updatedAt: Date
    let didUpdate: Bool
}

// MARK: - Profile Naming Engine

enum ProfileNamingEngine {

    static func resolve(
        vector: TasteVector,
        swipeCount: Int,
        existingProfile: TasteProfile
    ) -> ProfileNamingResult {
        let axisScores = AxisMapping.computeAxisScores(from: vector)
        let basisHash = BasisHashBuilder.build(
            axisScores: axisScores, vector: vector, swipeCount: swipeCount
        )
        let generatedName = ProfileNameGenerator.generate(from: axisScores, basisHash: basisHash)
        let description = DescriptionGenerator.generate(from: axisScores)

        // First time — no existing name
        if existingProfile.profileName.isEmpty {
            return ProfileNamingResult(
                name: generatedName,
                description: description,
                version: 1,
                basisHash: basisHash,
                previousNames: [],
                updatedAt: Date(),
                didUpdate: true
            )
        }

        // Check evolution gate
        let hashChanged = basisHash != existingProfile.profileNameBasisHash
        if hashChanged && shouldEvolve(vector: vector, swipeCount: swipeCount) {
            var prev = existingProfile.previousNames
            if !prev.contains(existingProfile.profileName) {
                prev.append(existingProfile.profileName)
            }
            if prev.count > 3 { prev = Array(prev.suffix(3)) }

            return ProfileNamingResult(
                name: generatedName,
                description: description,
                version: existingProfile.profileNameVersion + 1,
                basisHash: basisHash,
                previousNames: prev,
                updatedAt: Date(),
                didUpdate: true
            )
        }

        // No change — keep existing name, refresh description
        return ProfileNamingResult(
            name: existingProfile.profileName,
            description: description,
            version: existingProfile.profileNameVersion,
            basisHash: existingProfile.profileNameBasisHash,
            previousNames: existingProfile.previousNames,
            updatedAt: existingProfile.profileNameUpdatedAt ?? Date(),
            didUpdate: false
        )
    }

    static func applyInitialNaming(to profile: inout TasteProfile) {
        let vector = TasteEngine.vectorFromProfile(profile)
        let result = resolve(vector: vector, swipeCount: 0, existingProfile: profile)
        profile.profileName = result.name
        profile.profileNameVersion = result.version
        profile.profileNameBasisHash = result.basisHash
        profile.profileNameUpdatedAt = result.updatedAt
        profile.previousNames = result.previousNames
    }

    private static func shouldEvolve(vector: TasteVector, swipeCount: Int) -> Bool {
        let norm = vector.normalized()
        let sorted = norm.weights.values.sorted(by: >)
        let top1 = sorted.first ?? 0
        let top2 = sorted.dropFirst().first ?? 0
        let separation = top1 - top2
        let confidence = vector.confidenceLevel(swipeCount: swipeCount)

        return confidence == "Strong" || swipeCount >= 14 || separation >= 0.15
    }
}
