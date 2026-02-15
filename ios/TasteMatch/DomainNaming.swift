import Foundation

// MARK: - Domain Name Dispatcher

enum DomainNameDispatcher {

    static func generate(axisScores: AxisScores, basisHash: String, domain: TasteDomain) -> String {
        switch domain {
        case .space:
            return ProfileNameGenerator.generate(from: axisScores, basisHash: basisHash)
        case .objects:
            return ObjectNamingEngine.generate(axisScores: axisScores, basisHash: basisHash)
        case .art:
            return ArtNamingEngine.generate(axisScores: axisScores, basisHash: basisHash)
        }
    }
}

// MARK: - Object Naming Engine

/// Grammar: "{Behavioral} {Structural Tone}"
enum ObjectNamingEngine {

    private static let behavioralPools: [(Axis, Bool, [String])] = [
        (.minimalOrnate, false,     ["Normcore", "Essential", "Stealth", "Utility"]),
        (.minimalOrnate, true,      ["Heritage", "Curated", "Collected", "Archival"]),
        (.warmCool, true,           ["Patina", "Tonal", "Earthen", "Grounded"]),
        (.warmCool, false,          ["Tactical", "Clinical", "Precise", "Surgical"]),
        (.softStructured, true,     ["Technical", "Engineered", "Calibrated", "Modular"]),
        (.softStructured, false,    ["Draped", "Yielding", "Fluid", "Effortless"]),
        (.organicIndustrial, true,  ["Forged", "Machined", "Tooled", "Riveted"]),
        (.organicIndustrial, false, ["Woven", "Stitched", "Braided", "Crafted"]),
        (.lightDark, false,         ["Bleached", "Matte", "Faded", "Washed"]),
        (.lightDark, true,          ["Shadow", "Coated", "Blacked", "Smoked"]),
        (.neutralSaturated, false,  ["Tonal", "Quiet", "Undyed", "Raw"]),
        (.neutralSaturated, true,   ["Signal", "Vivid", "Marked", "Bold"]),
        (.sparseLayered, false,     ["Pared", "Minimal", "Stripped", "Clean"]),
        (.sparseLayered, true,      ["Stacked", "Loaded", "Dense", "Heavy"]),
    ]

    private static let structuralTonePools: [(Axis, Bool, [String])] = [
        (.minimalOrnate, false,     ["Precision", "Line", "Edge", "Core"]),
        (.minimalOrnate, true,      ["Detail", "Texture", "Grain", "Patternwork"]),
        (.warmCool, true,           ["Warmth", "Tone", "Amber", "Rust"]),
        (.warmCool, false,          ["Steel", "Chrome", "Frost", "Zinc"]),
        (.softStructured, true,     ["Forge", "Frame", "Axis", "Grid"]),
        (.softStructured, false,    ["Drape", "Curve", "Flow", "Ease"]),
        (.organicIndustrial, true,  ["Iron", "Alloy", "Carbon", "Bolt"]),
        (.organicIndustrial, false, ["Hide", "Bark", "Fiber", "Root"]),
        (.lightDark, false,         ["Light", "Bone", "Chalk", "Haze"]),
        (.lightDark, true,          ["Shadow", "Obsidian", "Void", "Depth"]),
        (.neutralSaturated, false,  ["Stone", "Sand", "Ash", "Dust"]),
        (.neutralSaturated, true,   ["Spectrum", "Signal", "Pulse", "Flash"]),
        (.sparseLayered, false,     ["Space", "Air", "Negative", "Rest"]),
        (.sparseLayered, true,      ["Mass", "Stack", "Volume", "Weight"]),
    ]

    static func generate(axisScores: AxisScores, basisHash: String) -> String {
        let sorted = Axis.allCases.sorted { abs(axisScores.value(for: $0)) > abs(axisScores.value(for: $1)) }
        let dominant = sorted[0]
        let secondary = sorted.count >= 2 ? sorted[1] : dominant

        let dominantPositive = axisScores.value(for: dominant) >= 0
        let secondaryPositive = axisScores.value(for: secondary) >= 0

        let behavioral = pickWord(
            from: behavioralPools, axis: dominant, positive: dominantPositive,
            hash: basisHash, prime: 41
        )
        let tone = pickWord(
            from: structuralTonePools, axis: secondary, positive: secondaryPositive,
            hash: basisHash, prime: 43
        )

        return "\(behavioral) \(tone)"
    }

    private static func pickWord(
        from pools: [(Axis, Bool, [String])],
        axis: Axis, positive: Bool,
        hash: String, prime: UInt64
    ) -> String {
        guard let pool = pools.first(where: { $0.0 == axis && $0.1 == positive }) else {
            return "Quiet"
        }
        let words = pool.2
        let index = StructuralDescriptorResolver.deterministicIndex(from: hash, multiplier: prime, count: words.count)
        return words[index]
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
