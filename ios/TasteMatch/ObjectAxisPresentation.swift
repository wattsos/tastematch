import Foundation

// MARK: - Object Axis Presentation

enum ObjectAxisPresentation {

    // MARK: - Synonym Pools

    private static let synonyms: [ObjectAxis: (positive: [String], negative: [String])] = [
        .precision: (
            positive: ["precise", "exacting", "tight-tolerance", "calibrated", "metered", "dialed"],
            negative: ["rough", "imprecise", "loose", "unfinished", "approximate", "raw-cut"]
        ),
        .patina: (
            positive: ["worn", "aged", "oxidized", "weathered", "seasoned", "lived-in"],
            negative: ["factory-new", "pristine", "sealed", "mint", "unworn", "untouched"]
        ),
        .utility: (
            positive: ["functional", "carried", "deployed", "daily-use", "field-ready", "loaded"],
            negative: ["decorative", "displayed", "mounted", "ceremonial", "vitrine-kept", "shelved"]
        ),
        .formality: (
            positive: ["formal", "ceremonial", "dressed", "protocol", "occasion", "black-tie"],
            negative: ["casual", "off-duty", "undone", "street", "relaxed", "weekend"]
        ),
        .subculture: (
            positive: ["niche", "coded", "insider", "deep-cut", "underground", "scene-specific"],
            negative: ["mainstream", "universal", "open", "standard", "broad-market", "general"]
        ),
        .ornament: (
            positive: ["embellished", "engraved", "etched", "filigreed", "detailed", "guilloché"],
            negative: ["austere", "blank", "bare", "unmarked", "stripped", "unadorned"]
        ),
        .heritage: (
            positive: ["legacy", "storied", "lineage", "archive", "house", "provenance"],
            negative: ["new-gen", "first-run", "debut", "contemporary", "fresh-house", "zero"]
        ),
        .technicality: (
            positive: ["engineered", "hi-tech", "composite", "technical", "alloy", "machined"],
            negative: ["analog", "handbuilt", "lo-fi", "manual", "bench-made", "artisanal"]
        ),
        .minimalism: (
            positive: ["stripped", "essential", "reduced", "distilled", "negative-space", "edited"],
            negative: ["maximal", "layered", "stacked", "dense", "accumulated", "heavy"]
        ),
    ]

    // MARK: - Primary Words

    private static let primaryWords: [ObjectAxis: (positive: String, negative: String)] = [
        .precision:    (positive: "Precise",      negative: "Rough"),
        .patina:       (positive: "Worn",         negative: "Pristine"),
        .utility:      (positive: "Functional",   negative: "Decorative"),
        .formality:    (positive: "Formal",       negative: "Casual"),
        .subculture:   (positive: "Niche",        negative: "Mainstream"),
        .ornament:     (positive: "Embellished",  negative: "Austere"),
        .heritage:     (positive: "Legacy",       negative: "New-Gen"),
        .technicality: (positive: "Engineered",   negative: "Analog"),
        .minimalism:   (positive: "Essential",    negative: "Maximal"),
    ]

    // MARK: - Axis Categories

    private enum AxisCategory { case material, behavioral, identity }

    private static let categories: [ObjectAxis: AxisCategory] = [
        .precision:    .material,
        .patina:       .material,
        .technicality: .material,
        .utility:      .behavioral,
        .formality:    .behavioral,
        .subculture:   .behavioral,
        .ornament:     .identity,
        .heritage:     .identity,
        .minimalism:   .identity,
    ]

    // MARK: - Public

    static func influenceWord(axis: ObjectAxis, positive: Bool) -> String {
        let entry = primaryWords[axis]!
        return positive ? entry.positive : entry.negative
    }

    static func influencePhrases(objectScores: ObjectAxisScores) -> [String] {
        let hash = scoreHash(from: objectScores)
        let pairs = ObjectAxis.allCases.map { axis in (axis, objectScores.value(for: axis)) }

        var strong = pairs.filter { abs($0.1) > 0.3 }
            .sorted { abs($0.1) > abs($1.1) }

        if strong.count < 2 {
            strong = pairs.filter { abs($0.1) > 0.15 }
                .sorted { abs($0.1) > abs($1.1) }
        }

        if strong.count < 2 {
            strong = Array(pairs.sorted { abs($0.1) > abs($1.1) }.prefix(3))
        }

        var material: [(ObjectAxis, Double)] = []
        var behavioral: [(ObjectAxis, Double)] = []
        var identity: [(ObjectAxis, Double)] = []

        for pair in strong {
            switch categories[pair.0]! {
            case .material:   material.append(pair)
            case .behavioral: behavioral.append(pair)
            case .identity:   identity.append(pair)
            }
        }

        var selected: [(ObjectAxis, Double)] = []
        if let m = material.first { selected.append(m) }
        if let b = behavioral.first { selected.append(b) }
        if let i = identity.first { selected.append(i) }

        for pair in strong where selected.count < 2 {
            if !selected.contains(where: { $0.0 == pair.0 }) {
                selected.append(pair)
            }
        }

        if selected.count < 4 {
            for pair in strong where !selected.contains(where: { $0.0 == pair.0 }) {
                if abs(pair.1) > 0.4 {
                    selected.append(pair)
                    break
                }
            }
        }

        let capped = Array(selected.prefix(4))

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

    static func avoidPhrases(objectScores: ObjectAxisScores) -> [String] {
        let hash = scoreHash(from: objectScores)
        let strong = ObjectAxis.allCases
            .map { axis in (axis, objectScores.value(for: axis)) }
            .filter { abs($0.1) > 0.5 }
            .sorted { abs($0.1) > abs($1.1) }
            .prefix(2)

        return strong.map { pair in
            let word = selectSynonym(axis: pair.0, positive: pair.1 < 0, hash: hash, salt: "avoid")
            return capitalizeFirst(word)
        }
    }

    static func axisDisplayLabel(_ axis: ObjectAxis) -> String {
        let entry = primaryWords[axis]!
        return "\(entry.negative) — \(entry.positive)"
    }

    // MARK: - Private

    private static func scoreHash(from scores: ObjectAxisScores) -> String {
        ObjectAxis.allCases.map { axis in
            let bucket = Int((scores.value(for: axis) * 10).rounded())
            return "\(axis.rawValue):\(bucket)"
        }.joined(separator: "|")
    }

    private static func selectSynonym(axis: ObjectAxis, positive: Bool, hash: String, salt: String = "") -> String {
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
}
