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

/// Grammar: "{Signal} {Identity Tone}"
enum ObjectNamingEngine {

    // MARK: - Signal Pools (keyed by ObjectAxis)

    private static let signalPools: [(ObjectAxis, Bool, [String])] = [
        (.precision, true,      ["Calibrated", "Machined", "Exacting", "Toleranced"]),
        (.precision, false,     ["Rough", "Approximate", "Loose", "Unmetered"]),
        (.patina, true,         ["Weathered", "Worn", "Oxidized", "Seasoned"]),
        (.patina, false,        ["Pristine", "Factory", "Sealed", "Unworn"]),
        (.utility, true,        ["Deployed", "Fielded", "Loaded", "Carried"]),
        (.utility, false,       ["Displayed", "Archived", "Mounted", "Cased"]),
        (.formality, true,      ["Ceremonial", "Formal", "Dressed", "Protocol"]),
        (.formality, false,     ["Casual", "Off-Duty", "Undone", "Relaxed"]),
        (.subculture, true,     ["Underground", "Coded", "Deep-Cut", "Insider"]),
        (.subculture, false,    ["Standard", "Mainline", "Universal", "Open"]),
        (.ornament, true,       ["Etched", "Guilloché", "Engraved", "Filigreed"]),
        (.ornament, false,      ["Blank", "Bare", "Stripped", "Unmarked"]),
        (.heritage, true,       ["Storied", "Lineage", "Legacy", "Archive"]),
        (.heritage, false,      ["New-Gen", "First-Run", "Debut", "Zero"]),
        (.technicality, true,   ["Engineered", "Composite", "Alloy", "Technical"]),
        (.technicality, false,  ["Analog", "Manual", "Handbuilt", "Lo-Fi"]),
        (.minimalism, true,     ["Reduced", "Distilled", "Essential", "Negative"]),
        (.minimalism, false,    ["Stacked", "Dense", "Loaded", "Heavy"]),
    ]

    // MARK: - Identity Tone Pools (keyed by ObjectAxis)

    private static let identityTonePools: [(ObjectAxis, Bool, [String])] = [
        (.precision, true,      ["Tolerance", "Grade", "Spec", "Gauge"]),
        (.precision, false,     ["Drift", "Scatter", "Blur", "Margin"]),
        (.patina, true,         ["Relic", "Verdigris", "Tarnish", "Grain"]),
        (.patina, false,        ["Mint", "Stock", "Fresh", "Uncut"]),
        (.utility, true,        ["Kit", "Loadout", "Rig", "Carry"]),
        (.utility, false,       ["Vitrine", "Case", "Display", "Shelf"]),
        (.formality, true,      ["Rite", "Occasion", "Order", "Code"]),
        (.formality, false,     ["Break", "Ease", "Rest", "Off-Clock"]),
        (.subculture, true,     ["Signal", "Cipher", "Frequency", "Channel"]),
        (.subculture, false,    ["Baseline", "Default", "Norm", "Standard"]),
        (.ornament, true,       ["Motif", "Flourish", "Relief", "Pattern"]),
        (.ornament, false,      ["Void", "Plane", "Flat", "Ground"]),
        (.heritage, true,       ["House", "Provenance", "Edition", "Mark"]),
        (.heritage, false,      ["Prototype", "Draft", "Origin", "Launch"]),
        (.technicality, true,   ["Lab", "Module", "System", "Matrix"]),
        (.technicality, false,  ["Hand", "Loom", "Bench", "Craft"]),
        (.minimalism, true,     ["Absence", "Silence", "Clear", "Less"]),
        (.minimalism, false,    ["Mass", "Weight", "Layer", "Stack"]),
    ]

    // MARK: - Generate (from ObjectAxisScores — primary path)

    static func generateFromObjectAxes(objectScores: ObjectAxisScores, basisHash: String) -> String {
        let sorted = ObjectAxis.allCases.sorted { abs(objectScores.value(for: $0)) > abs(objectScores.value(for: $1)) }
        let dominant = sorted[0]
        let secondary = sorted.count >= 2 ? sorted[1] : dominant

        let dominantPositive = objectScores.value(for: dominant) >= 0
        let secondaryPositive = objectScores.value(for: secondary) >= 0

        let signal = pickObjectWord(
            from: signalPools, axis: dominant, positive: dominantPositive,
            hash: basisHash, prime: 59
        )
        let tone = pickObjectWord(
            from: identityTonePools, axis: secondary, positive: secondaryPositive,
            hash: basisHash, prime: 61
        )

        return "\(signal) \(tone)"
    }

    // MARK: - Generate (fallback from Space AxisScores — backward compat)

    static func generate(axisScores: AxisScores, basisHash: String) -> String {
        // Map Space axes to closest ObjectAxis approximations
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

    private static func pickObjectWord(
        from pools: [(ObjectAxis, Bool, [String])],
        axis: ObjectAxis, positive: Bool,
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
