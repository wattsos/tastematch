import Foundation

// MARK: - Archetype Signature

struct ArchetypeSignature {
    let axes: [ObjectAxis: Double]
    let name: String
    let tagline: String
    let keywords: [String]
}

// MARK: - Object Archetype

enum ObjectArchetype: String, CaseIterable {
    case archiveMinimalist
    case industrialRomantic
    case streetCollector
    case quietLuxury
    case toolWorship
    case heritageMaximalist
    case technicalAscetic
    case patinaPurist
    case subcultureArchivist
    case newCeremonialist

    var signature: ArchetypeSignature {
        switch self {
        case .archiveMinimalist:
            return ArchetypeSignature(
                axes: [
                    .precision: 0.2, .patina: 0.1, .utility: 0.0, .formality: 0.1,
                    .subculture: 0.0, .ornament: -0.7, .heritage: 0.6,
                    .technicality: 0.0, .minimalism: 0.8
                ],
                name: "Archive Minimalist",
                tagline: "Less, but considered.",
                keywords: ["edited", "archive", "restraint"]
            )
        case .industrialRomantic:
            return ArchetypeSignature(
                axes: [
                    .precision: -0.2, .patina: 0.8, .utility: 0.2, .formality: -0.6,
                    .subculture: 0.3, .ornament: 0.1, .heritage: 0.3,
                    .technicality: -0.5, .minimalism: -0.3
                ],
                name: "Industrial Romantic",
                tagline: "Raw finish, warm soul.",
                keywords: ["patina", "raw", "lived-in"]
            )
        case .streetCollector:
            return ArchetypeSignature(
                axes: [
                    .precision: 0.0, .patina: 0.1, .utility: 0.6, .formality: -0.7,
                    .subculture: 0.8, .ornament: 0.2, .heritage: 0.1,
                    .technicality: 0.1, .minimalism: -0.2
                ],
                name: "Street Collector",
                tagline: "Culture over category.",
                keywords: ["streetwear", "utility", "coded"]
            )
        case .quietLuxury:
            return ArchetypeSignature(
                axes: [
                    .precision: 0.7, .patina: 0.0, .utility: 0.0, .formality: 0.6,
                    .subculture: -0.3, .ornament: -0.5, .heritage: 0.5,
                    .technicality: 0.2, .minimalism: 0.3
                ],
                name: "Quiet Luxury",
                tagline: "Restraint as signal.",
                keywords: ["precision", "discreet", "legacy"]
            )
        case .toolWorship:
            return ArchetypeSignature(
                axes: [
                    .precision: 0.8, .patina: -0.1, .utility: 0.8, .formality: -0.2,
                    .subculture: 0.1, .ornament: -0.3, .heritage: 0.0,
                    .technicality: 0.7, .minimalism: 0.2
                ],
                name: "Tool Worship",
                tagline: "Function is the ornament.",
                keywords: ["tool", "function", "engineered"]
            )
        case .heritageMaximalist:
            return ArchetypeSignature(
                axes: [
                    .precision: 0.2, .patina: 0.3, .utility: -0.1, .formality: 0.3,
                    .subculture: 0.1, .ornament: 0.8, .heritage: 0.7,
                    .technicality: -0.2, .minimalism: -0.8
                ],
                name: "Heritage Maximalist",
                tagline: "Curated accumulation.",
                keywords: ["ornate", "legacy", "layered"]
            )
        case .technicalAscetic:
            return ArchetypeSignature(
                axes: [
                    .precision: 0.7, .patina: -0.4, .utility: 0.3, .formality: 0.0,
                    .subculture: 0.0, .ornament: -0.5, .heritage: -0.2,
                    .technicality: 0.8, .minimalism: 0.7
                ],
                name: "Technical Ascetic",
                tagline: "Engineered emptiness.",
                keywords: ["technical", "minimal", "precise"]
            )
        case .patinaPurist:
            return ArchetypeSignature(
                axes: [
                    .precision: -0.1, .patina: 0.9, .utility: 0.2, .formality: -0.2,
                    .subculture: 0.2, .ornament: 0.0, .heritage: 0.6,
                    .technicality: -0.6, .minimalism: 0.0
                ],
                name: "Patina Purist",
                tagline: "Wear is character.",
                keywords: ["worn", "aged", "storied"]
            )
        case .subcultureArchivist:
            return ArchetypeSignature(
                axes: [
                    .precision: 0.0, .patina: 0.2, .utility: 0.3, .formality: -0.5,
                    .subculture: 0.9, .ornament: 0.2, .heritage: 0.5,
                    .technicality: 0.0, .minimalism: -0.1
                ],
                name: "Subculture Archivist",
                tagline: "Deep cuts only.",
                keywords: ["niche", "archive", "insider"]
            )
        case .newCeremonialist:
            return ArchetypeSignature(
                axes: [
                    .precision: 0.3, .patina: -0.6, .utility: -0.1, .formality: 0.8,
                    .subculture: -0.1, .ornament: 0.4, .heritage: 0.0,
                    .technicality: 0.6, .minimalism: 0.0
                ],
                name: "New Ceremonialist",
                tagline: "Future-facing ritual.",
                keywords: ["formal", "technical", "future"]
            )
        }
    }

    // MARK: - Duel Pair Generation

    /// Generates duel pairs that maximize axis coverage.
    /// Pairs archetypes with opposing dominant axes. Deterministic via profileId hash.
    static func generateDuelPairs(count: Int, profileId: UUID) -> [(ObjectArchetype, ObjectArchetype)] {
        let all = ObjectArchetype.allCases

        // Pre-compute dominant axis per archetype
        let dominants: [(ObjectArchetype, ObjectAxis)] = all.map { archetype in
            let sig = archetype.signature
            let dominant = sig.axes.max(by: { abs($0.value) < abs($1.value) })!.key
            return (archetype, dominant)
        }

        // Build pairs: for each archetype, find one with an opposing dominant axis
        var pairs: [(ObjectArchetype, ObjectArchetype)] = []
        var usedIndices = Set<Int>()

        for i in 0..<all.count {
            guard !usedIndices.contains(i) else { continue }
            // Find best partner: different dominant axis, maximize axis distance
            var bestJ = -1
            var bestDistance = -1.0
            for j in (i + 1)..<all.count {
                guard !usedIndices.contains(j) else { continue }
                if dominants[i].1 != dominants[j].1 {
                    let distance = axisDistance(all[i].signature, all[j].signature)
                    if distance > bestDistance {
                        bestDistance = distance
                        bestJ = j
                    }
                }
            }
            if bestJ >= 0 {
                pairs.append((all[i], all[bestJ]))
                usedIndices.insert(i)
                usedIndices.insert(bestJ)
            }
        }

        // Deterministic shuffle using profileId
        let hashSeed = profileId.uuidString.utf8.reduce(UInt64(0)) { ($0 &+ UInt64($1)) &* 31 }
        var shuffled = pairs
        for i in stride(from: shuffled.count - 1, through: 1, by: -1) {
            let j = Int((hashSeed &* UInt64(i + 1)) % UInt64(shuffled.count))
            if i != j { shuffled.swapAt(i, j) }
        }

        // If we need more pairs than natural pairs, cycle through with reversed sides
        var result = shuffled
        while result.count < count {
            let extra = shuffled.map { ($0.1, $0.0) } // swap sides
            result.append(contentsOf: extra)
        }

        return Array(result.prefix(count))
    }

    /// Blend a duel winner's axis signature into the object vector.
    static func applyDuelResult(
        winner: ObjectArchetype,
        vector: inout ObjectVector,
        affinities: inout [String: Double],
        weight: Double = 0.15
    ) {
        let sig = winner.signature
        for (axis, value) in sig.axes {
            let key = axis.rawValue
            vector.weights[key] = (vector.weights[key] ?? 0) + value * weight
        }
        affinities[winner.rawValue, default: 0] += weight
    }

    // MARK: - Private

    private static func axisDistance(_ a: ArchetypeSignature, _ b: ArchetypeSignature) -> Double {
        var sum = 0.0
        for axis in ObjectAxis.allCases {
            let diff = (a.axes[axis] ?? 0) - (b.axes[axis] ?? 0)
            sum += diff * diff
        }
        return sum
    }
}
