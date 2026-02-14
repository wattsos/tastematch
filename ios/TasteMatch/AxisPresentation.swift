import Foundation

// MARK: - Axis Presentation

enum AxisPresentation {

    // MARK: - Synonym Pools (4-8 per direction)

    private static let synonyms: [Axis: (positive: [String], negative: [String])] = [
        .minimalOrnate: (
            positive: ["ornate", "embellished", "elaborate", "articulated", "gilt-edged", "filigree"],
            negative: ["minimal", "pared-back", "reductive", "austere", "distilled", "bare"]
        ),
        .warmCool: (
            positive: ["warm", "amber-toned", "earthen", "sun-warmed", "honeyed", "ochre"],
            negative: ["cool", "lunar", "silvered", "frost-toned", "slate", "graphite"]
        ),
        .softStructured: (
            positive: ["structured", "precise", "architectural", "geometric", "exacting", "gridded"],
            negative: ["soft", "yielding", "draped", "fluid", "pliant", "unhurried"]
        ),
        .organicIndustrial: (
            positive: ["raw", "exposed", "unfinished", "forged", "hewn", "smelted"],
            negative: ["organic", "hand-turned", "botanical", "woven", "rooted", "living-edge"]
        ),
        .lightDark: (
            positive: ["dark", "shadowed", "inky", "obsidian", "blackened", "nocturnal"],
            negative: ["light", "luminous", "bleached", "translucent", "chalked", "gauze-lit"]
        ),
        .neutralSaturated: (
            positive: ["vivid", "chromatic", "pigment-rich", "saturated", "dyed", "color-forward"],
            negative: ["neutral", "tonal", "undyed", "monochrome", "achromatic", "greyed"]
        ),
        .sparseLayered: (
            positive: ["layered", "stacked", "accumulated", "dense", "stratified", "built-up"],
            negative: ["spare", "edited", "void-led", "essentialist", "emptied", "stripped"]
        ),
    ]

    // Primary vocabulary — stable canonical words for variant labels and axis display
    private static let primaryWords: [Axis: (positive: String, negative: String)] = [
        .minimalOrnate:      (positive: "Ornate",     negative: "Minimal"),
        .warmCool:           (positive: "Warm",       negative: "Cool"),
        .softStructured:     (positive: "Structured", negative: "Soft"),
        .organicIndustrial:  (positive: "Raw",        negative: "Organic"),
        .lightDark:          (positive: "Dark",       negative: "Light"),
        .neutralSaturated:   (positive: "Vivid",      negative: "Neutral"),
        .sparseLayered:      (positive: "Layered",    negative: "Spare"),
    ]

    // MARK: - Axis Categories

    private enum AxisCategory { case structural, atmosphere, material }

    private static let categories: [Axis: AxisCategory] = [
        .minimalOrnate:     .structural,
        .softStructured:    .structural,
        .sparseLayered:     .structural,
        .warmCool:          .atmosphere,
        .lightDark:         .atmosphere,
        .neutralSaturated:  .atmosphere,
        .organicIndustrial: .material,
    ]

    // MARK: - Private Helpers

    private static func scoreHash(from scores: AxisScores) -> String {
        Axis.allCases.map { axis in
            let bucket = Int((scores.value(for: axis) * 10).rounded())
            return "\(axis.rawValue):\(bucket)"
        }.joined(separator: "|")
    }

    private static func selectSynonym(axis: Axis, positive: Bool, hash: String, salt: String = "") -> String {
        let pool = positive ? synonyms[axis]!.positive : synonyms[axis]!.negative
        let combined = hash + axis.rawValue + (positive ? "+" : "-") + salt
        let index = StructuralDescriptorResolver.deterministicIndex(
            from: combined, multiplier: 37, count: pool.count
        )
        return pool[index]
    }

    private static func capitalizeFirst(_ s: String) -> String {
        s.prefix(1).uppercased() + s.dropFirst()
    }

    // MARK: - Public Functions

    /// Returns the primary/canonical word for an axis direction.
    /// Used for variant labels ("More Raw") and axis display ("Minimal — Ornate").
    static func influenceWord(axis: Axis, positive: Bool) -> String {
        let entry = primaryWords[axis]!
        return positive ? entry.positive : entry.negative
    }

    /// Returns 2-4 category-mixed influence phrases using synonym pools.
    /// Picks 1 structural + 1 atmosphere + optional material, no repeated root words.
    static func influencePhrases(axisScores: AxisScores) -> [String] {
        let hash = scoreHash(from: axisScores)
        let pairs = Axis.allCases.map { axis in (axis, axisScores.value(for: axis)) }

        // Build candidate pool
        var strong = pairs.filter { abs($0.1) > 0.3 }
            .sorted { abs($0.1) > abs($1.1) }

        if strong.count < 2 {
            strong = pairs.filter { abs($0.1) > 0.15 }
                .sorted { abs($0.1) > abs($1.1) }
        }

        if strong.count < 2 {
            strong = Array(pairs.sorted { abs($0.1) > abs($1.1) }.prefix(3))
        }

        // Group by category
        var structural: [(Axis, Double)] = []
        var atmosphere: [(Axis, Double)] = []
        var material: [(Axis, Double)] = []

        for pair in strong {
            switch categories[pair.0]! {
            case .structural: structural.append(pair)
            case .atmosphere: atmosphere.append(pair)
            case .material:   material.append(pair)
            }
        }

        // Pick 1 per category (strongest in each), then fill
        var selected: [(Axis, Double)] = []
        if let s = structural.first { selected.append(s) }
        if let a = atmosphere.first { selected.append(a) }
        if let m = material.first { selected.append(m) }

        // Ensure at least 2
        for pair in strong where selected.count < 2 {
            if !selected.contains(where: { $0.0 == pair.0 }) {
                selected.append(pair)
            }
        }

        // Optional 4th from strong if magnitude > 0.4
        if selected.count < 4 {
            for pair in strong where !selected.contains(where: { $0.0 == pair.0 }) {
                if abs(pair.1) > 0.4 {
                    selected.append(pair)
                    break
                }
            }
        }

        let capped = Array(selected.prefix(4))

        // Convert to synonym words, skip repeated roots
        var usedRoots = Set<String>()
        var result: [String] = []
        for pair in capped {
            let word = selectSynonym(axis: pair.0, positive: pair.1 >= 0, hash: hash)
            let root = word.components(separatedBy: "-").first ?? word
            if !usedRoots.contains(root.lowercased()) {
                result.append(capitalizeFirst(word))
                usedRoots.insert(root.lowercased())
            }
        }

        return result
    }

    /// Returns 0-2 avoid phrases (opposite direction) using synonym pools.
    static func avoidPhrases(axisScores: AxisScores) -> [String] {
        let hash = scoreHash(from: axisScores)
        let strong = Axis.allCases
            .map { axis in (axis, axisScores.value(for: axis)) }
            .filter { abs($0.1) > 0.5 }
            .sorted { abs($0.1) > abs($1.1) }
            .prefix(2)

        return strong.map { pair in
            let word = selectSynonym(axis: pair.0, positive: pair.1 < 0, hash: hash, salt: "avoid")
            return capitalizeFirst(word)
        }
    }

    /// One-line curator reading. 10-18 words including profileName.
    static func oneLineReading(profileName: String, axisScores: AxisScores) -> String {
        let hash = scoreHash(from: axisScores)
        let dominant = axisScores.dominantAxis
        let dominantValue = axisScores.value(for: dominant)
        let dominantWord = selectSynonym(
            axis: dominant, positive: dominantValue >= 0, hash: hash, salt: "reading.dom"
        )

        let secondary = axisScores.secondaryAxis

        if let sec = secondary {
            let secValue = axisScores.value(for: sec)
            let secWord = selectSynonym(
                axis: sec, positive: secValue >= 0, hash: hash, salt: "reading.sec"
            )

            let templates = [
                "\(profileName) — \(dominantWord) composition with a \(secWord) counterpoint running through.",
                "\(profileName) — \(dominantWord) at its foundation, \(secWord) in the details.",
                "\(profileName) — \(dominantWord) instinct holding \(secWord) tension beneath the surface.",
                "\(profileName) — a \(dominantWord) register tempered by \(secWord) restraint and conviction.",
                "\(profileName) — \(secWord) undertone driving a predominantly \(dominantWord) material position.",
                "\(profileName) — the register is \(dominantWord), the counterweight \(secWord), both considered.",
                "\(profileName) — built on \(dominantWord) ground, inflected with \(secWord) precision and weight.",
            ]

            let index = StructuralDescriptorResolver.deterministicIndex(
                from: hash + "reading", multiplier: 41, count: templates.count
            )
            return templates[index]
        } else {
            let templates = [
                "\(profileName) — \(dominantWord) instinct from end to end, singular and uncompromised.",
                "\(profileName) — \(dominantWord) in every direction, without a competing register.",
            ]

            let index = StructuralDescriptorResolver.deterministicIndex(
                from: hash + "reading", multiplier: 41, count: templates.count
            )
            return templates[index]
        }
    }

    /// Axis display label for comparison views. Uses primary vocabulary.
    static func axisDisplayLabel(_ axis: Axis) -> String {
        let entry = primaryWords[axis]!
        return "\(entry.negative) — \(entry.positive)"
    }

    /// Story text using axis phrases and signal descriptions.
    static func storyText(
        axisScores: AxisScores,
        palette: String,
        brightness: String,
        material: String,
        room: String,
        goal: String
    ) -> String {
        let phrases = influencePhrases(axisScores: axisScores)
        let phraseLine = phrases.prefix(2).joined(separator: " and ").lowercased()

        let sentence1 = "Your instinct runs \(phraseLine) — that thread is consistent across your choices."
        let sentence2 = "Your \(room) features \(palette), \(brightness), and \(material)."
        let sentence3 = "\(goal) could bring this direction into sharper focus."

        return "\(sentence1) \(sentence2) \(sentence3)"
    }
}
