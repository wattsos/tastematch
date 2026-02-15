import Foundation

// MARK: - Domain Discovery

enum DomainDiscovery {

    private static var cache: [TasteDomain: [DiscoveryItem]] = [:]

    static func items(for domain: TasteDomain) -> [DiscoveryItem] {
        if let cached = cache[domain] { return cached }
        let provider = LocalNDJSONProvider(filename: domain.discoveryFilename)
        let loaded = provider.loadItems()
        cache[domain] = loaded
        return loaded
    }

    static func identifyCluster(_ scores: AxisScores, domain: TasteDomain) -> String {
        switch domain {
        case .space:
            return DiscoveryEngine.identifyCluster(scores)
        case .objects:
            return identifyObjectsCluster(scores)
        case .art:
            return identifyArtCluster(scores)
        }
    }

    static func resetCache() {
        cache.removeAll()
    }

    // MARK: - Objects Clusters (legacy — Space AxisScores)

    private static func identifyObjectsCluster(_ s: AxisScores) -> String {
        let clusters: [(String, Double)] = [
            ("precisionTool", s.softStructured + s.organicIndustrial),
            ("heritageCraft", s.warmCool - s.minimalOrnate + s.sparseLayered),
            ("streetSignal", s.lightDark + s.neutralSaturated + s.softStructured),
            ("quietCeremony", -s.minimalOrnate - s.sparseLayered - s.neutralSaturated),
        ]
        return clusters.max(by: { $0.1 < $1.1 })!.0
    }

    // MARK: - Objects Clusters V2 (ObjectAxisScores)

    static func identifyObjectsClusterV2(objectScores s: ObjectAxisScores) -> String {
        let clusters: [(String, Double)] = [
            ("precisionTool", s.precision + s.technicality),
            ("heritageCraft", s.heritage + s.patina),
            ("streetSignal", s.subculture + s.utility),
            ("quietCeremony", s.formality + s.minimalism),
        ]
        return clusters.max(by: { $0.1 < $1.1 })!.0
    }

    // MARK: - Art Clusters

    private static func identifyArtCluster(_ s: AxisScores) -> String {
        let clusters: [(String, Double)] = [
            ("archiveCanon", s.warmCool + s.sparseLayered + s.minimalOrnate),
            ("postMonochrome", -s.neutralSaturated - s.minimalOrnate + s.lightDark),
            ("brutalGesture", s.organicIndustrial + s.lightDark + s.softStructured),
            ("afroFuturism", s.neutralSaturated + s.warmCool - s.lightDark),
            ("conceptualArchive", -s.sparseLayered - s.warmCool + s.softStructured),
        ]
        return clusters.max(by: { $0.1 < $1.1 })!.0
    }
}
