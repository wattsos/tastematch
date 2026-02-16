import Foundation

// MARK: - Domain Name Dispatcher

enum DomainNameDispatcher {

    static func generate(axisScores: AxisScores, basisHash: String, domain: TasteDomain) -> String {
        switch domain {
        case .space:
            return ProfileNameGenerator.generate(from: axisScores, basisHash: basisHash)
        case .objects:
            // Objects uses its own 9-axis naming; fall through to Space name if no ObjectAxisScores provided
            return ObjectNamingEngine.generate(axisScores: axisScores, basisHash: basisHash)
        case .art:
            return ArtNamingEngine.generate(axisScores: axisScores, basisHash: basisHash)
        }
    }

    /// Objects-specific dispatch using ObjectAxisScores.
    static func generateObjects(objectScores: ObjectAxisScores, basisHash: String) -> String {
        ObjectNamingEngine.generateFromObjectAxes(objectScores: objectScores, basisHash: basisHash)
    }
}

// MARK: - Object Naming Engine

/// Matches user's ObjectAxisScores against lifestyle aesthetic signatures via dot-product similarity.
enum ObjectNamingEngine {

    // MARK: - Lifestyle Aesthetics

    private struct Aesthetic {
        let name: String
        let signature: [ObjectAxis: Double]
    }

    private static let lifestyleAesthetics: [Aesthetic] = [
        Aesthetic(name: "Quiet Luxury",   signature: [.precision: 0.7, .formality: 0.6, .ornament: -0.5, .subculture: -0.6, .minimalism: 0.4]),
        Aesthetic(name: "Normcore",       signature: [.minimalism: 0.7, .ornament: -0.6, .subculture: -0.5, .formality: -0.4]),
        Aesthetic(name: "Streetwear",     signature: [.subculture: 0.8, .utility: 0.4, .formality: -0.6, .heritage: -0.4]),
        Aesthetic(name: "Vintage",        signature: [.patina: 0.8, .heritage: 0.6, .technicality: -0.5]),
        Aesthetic(name: "Techwear",       signature: [.technicality: 0.8, .minimalism: 0.5, .precision: 0.6, .heritage: -0.5]),
        Aesthetic(name: "Old Money",      signature: [.heritage: 0.8, .formality: 0.7, .subculture: -0.6, .precision: 0.5]),
        Aesthetic(name: "Gorpcore",       signature: [.utility: 0.8, .technicality: 0.5, .formality: -0.6, .ornament: -0.5]),
        Aesthetic(name: "Wabi-Sabi",      signature: [.patina: 0.8, .minimalism: 0.5, .precision: -0.6, .formality: -0.4]),
        Aesthetic(name: "Maximalist",     signature: [.ornament: 0.8, .minimalism: -0.7, .heritage: 0.4]),
        Aesthetic(name: "Workwear",       signature: [.utility: 0.7, .patina: 0.5, .formality: -0.5, .ornament: -0.4]),
        Aesthetic(name: "Dark Academia",  signature: [.heritage: 0.7, .formality: 0.6, .ornament: 0.5, .technicality: -0.4]),
        Aesthetic(name: "Avant-Garde",    signature: [.subculture: 0.7, .technicality: 0.5, .heritage: -0.5, .ornament: 0.4]),
        Aesthetic(name: "Western",        signature: [.heritage: 0.6, .patina: 0.6, .utility: 0.5, .technicality: -0.5, .minimalism: -0.4]),
        Aesthetic(name: "Prep",           signature: [.formality: 0.7, .precision: 0.6, .subculture: -0.5, .patina: -0.4]),
        Aesthetic(name: "Artisan",        signature: [.technicality: -0.5, .heritage: 0.6, .patina: 0.5, .precision: 0.6]),
        Aesthetic(name: "Military",       signature: [.utility: 0.7, .precision: 0.6, .formality: 0.5, .ornament: -0.5]),
        Aesthetic(name: "Minimalist",     signature: [.minimalism: 0.8, .precision: 0.5, .ornament: -0.6, .patina: -0.4]),
        Aesthetic(name: "Bohemian",       signature: [.ornament: 0.6, .formality: -0.6, .patina: 0.5, .subculture: 0.4, .precision: -0.5]),
    ]

    /// All names that can be generated, for test assertions.
    static var allLifestyleNames: Set<String> {
        Set(lifestyleAesthetics.map(\.name))
    }

    // MARK: - Generate (from ObjectAxisScores — primary path)

    static func generateFromObjectAxes(objectScores: ObjectAxisScores, basisHash: String) -> String {
        let scored = lifestyleAesthetics.map { aesthetic in
            let similarity = dotProduct(objectScores, aesthetic.signature)
            return (aesthetic, similarity)
        }
        let best = scored.max(by: { $0.1 < $1.1 })!.0
        return best.name
    }

    // MARK: - Generate (fallback from Space AxisScores — backward compat)

    static func generate(axisScores: AxisScores, basisHash: String) -> String {
        let objectScores = ObjectAxisScores(
            precision: axisScores.softStructured,
            patina: axisScores.warmCool,
            utility: -axisScores.minimalOrnate,
            formality: axisScores.minimalOrnate,
            subculture: -axisScores.neutralSaturated,
            ornament: axisScores.minimalOrnate,
            heritage: axisScores.warmCool,
            technicality: axisScores.organicIndustrial,
            minimalism: -axisScores.sparseLayered
        )
        return generateFromObjectAxes(objectScores: objectScores, basisHash: basisHash)
    }

    // MARK: - Private

    private static func dotProduct(_ scores: ObjectAxisScores, _ signature: [ObjectAxis: Double]) -> Double {
        var sum = 0.0
        for (axis, weight) in signature {
            sum += scores.value(for: axis) * weight
        }
        return sum
    }
}

// MARK: - Art Naming Engine

/// Grammar: "{Movement} {Gesture/Study}"
enum ArtNamingEngine {

    private static let movementPools: [(Axis, Bool, [String])] = [
        (.minimalOrnate, false,     ["Post-Minimal", "Reductive", "Zero", "Void"]),
        (.minimalOrnate, true,      ["Baroque", "Maximal", "Ornamental", "Decorative"]),
        (.warmCool, true,           ["Contemporary", "Earthwork", "Vernacular", "Archive"]),
        (.warmCool, false,          ["Monochrome", "Chromatic", "Spectral", "Glacial"]),
        (.softStructured, true,     ["Constructivist", "Systematic", "Geometric", "Serial"]),
        (.softStructured, false,    ["Gestural", "Lyrical", "Fluid", "Organic"]),
        (.organicIndustrial, true,  ["Brutal", "Industrial", "Material", "Concrete"]),
        (.organicIndustrial, false, ["Biomorphic", "Natural", "Elemental", "Terrestrial"]),
        (.lightDark, false,         ["Luminous", "Light", "Radiant", "Prismatic"]),
        (.lightDark, true,          ["Nocturnal", "Shadow", "Tenebrist", "Crepuscular"]),
        (.neutralSaturated, false,  ["Tonal", "Achromatic", "Grayscale", "Subdued"]),
        (.neutralSaturated, true,   ["Chromatic", "Polychrome", "Saturated", "Pigment"]),
        (.sparseLayered, false,     ["Essential", "Distilled", "Sparse", "Singular"]),
        (.sparseLayered, true,      ["Accumulated", "Stratified", "Palimpsest", "Dense"]),
    ]

    private static let gesturePools: [(Axis, Bool, [String])] = [
        (.minimalOrnate, false,     ["Study", "Notation", "Mark", "Trace"]),
        (.minimalOrnate, true,      ["Tableau", "Scene", "Vista", "Field"]),
        (.warmCool, true,           ["Signal", "Pulse", "Breath", "Echo"]),
        (.warmCool, false,          ["Strike", "Cut", "Fracture", "Edge"]),
        (.softStructured, true,     ["Grid", "Structure", "Module", "Unit"]),
        (.softStructured, false,    ["Gesture", "Drift", "Sway", "Wave"]),
        (.organicIndustrial, true,  ["Force", "Impact", "Pressure", "Mass"]),
        (.organicIndustrial, false, ["Growth", "Root", "Bloom", "Spore"]),
        (.lightDark, false,         ["Glow", "Haze", "Aura", "Gleam"]),
        (.lightDark, true,          ["Depth", "Void", "Well", "Pit"]),
        (.neutralSaturated, false,  ["Silence", "Pause", "Rest", "Lull"]),
        (.neutralSaturated, true,   ["Burst", "Flare", "Charge", "Surge"]),
        (.sparseLayered, false,     ["Point", "Line", "Dot", "Plane"]),
        (.sparseLayered, true,      ["Layer", "Fold", "Weave", "Band"]),
    ]

    static func generate(axisScores: AxisScores, basisHash: String) -> String {
        let sorted = Axis.allCases.sorted { abs(axisScores.value(for: $0)) > abs(axisScores.value(for: $1)) }
        let dominant = sorted[0]
        let secondary = sorted.count >= 2 ? sorted[1] : dominant

        let dominantPositive = axisScores.value(for: dominant) >= 0
        let secondaryPositive = axisScores.value(for: secondary) >= 0

        let movement = pickWord(
            from: movementPools, axis: dominant, positive: dominantPositive,
            hash: basisHash, prime: 47
        )
        let gesture = pickWord(
            from: gesturePools, axis: secondary, positive: secondaryPositive,
            hash: basisHash, prime: 53
        )

        return "\(movement) \(gesture)"
    }

    private static func pickWord(
        from pools: [(Axis, Bool, [String])],
        axis: Axis, positive: Bool,
        hash: String, prime: UInt64
    ) -> String {
        guard let pool = pools.first(where: { $0.0 == axis && $0.1 == positive }) else {
            return "Study"
        }
        let words = pool.2
        let index = StructuralDescriptorResolver.deterministicIndex(from: hash, multiplier: prime, count: words.count)
        return words[index]
    }
}
