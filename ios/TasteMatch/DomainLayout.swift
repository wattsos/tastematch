import Foundation

enum DomainLayout {

    struct SectionConfig {
        let heroLabel: String
        let showWorldGrid: Bool
        let showUniform: Bool
        let showRarityLanes: Bool
        let radarSubtitle: String
        let showMaterials: Bool
    }

    static func config(for domain: TasteDomain) -> SectionConfig {
        switch domain {
        case .space:
            return SectionConfig(
                heroLabel: "SIGNATURE SPACES",
                showWorldGrid: true,
                showUniform: false,
                showRarityLanes: false,
                radarSubtitle: "Architecture + material signals.",
                showMaterials: true
            )
        case .objects:
            return SectionConfig(
                heroLabel: "SIGNATURE CARRY",
                showWorldGrid: false,
                showUniform: true,
                showRarityLanes: false,
                radarSubtitle: "Craft, ateliers, utility.",
                showMaterials: false
            )
        case .art:
            return SectionConfig(
                heroLabel: "SIGNATURE WORKS",
                showWorldGrid: false,
                showUniform: false,
                showRarityLanes: true,
                radarSubtitle: "Movements + scenes.",
                showMaterials: false
            )
        }
    }
}
