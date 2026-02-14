import Foundation

enum ShareTextBuilder {

    static func build(
        profile: TasteProfile,
        recommendations: [RecommendationItem]
    ) -> String {
        var lines: [String] = []

        lines.append("My \(Brand.name) Profile")
        lines.append("")

        let tagLine = profile.tags.map { $0.label }.joined(separator: ", ")
        lines.append("Style: \(tagLine)")
        lines.append("")

        lines.append(profile.story)
        lines.append("")

        if !recommendations.isEmpty {
            lines.append("Selection:")
            for item in recommendations {
                lines.append("- \(item.title) — \(item.subtitle)")
            }
            lines.append("")
        }

        lines.append("Discovered on \(Brand.name) — \(Brand.domain)")

        return lines.joined(separator: "\n")
    }
}
