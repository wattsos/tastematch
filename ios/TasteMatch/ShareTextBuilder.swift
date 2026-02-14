import Foundation

enum ShareTextBuilder {

    static func build(
        profile: TasteProfile,
        recommendations: [RecommendationItem]
    ) -> String {
        var lines: [String] = []

        lines.append("My \(Brand.name) Profile")
        lines.append("")

        lines.append("Profile: \(profile.displayName)")
        lines.append("")

        let vector = TasteEngine.vectorFromProfile(profile)
        let axisScores = AxisMapping.computeAxisScores(from: vector)
        let reading = AxisPresentation.oneLineReading(
            profileName: profile.displayName,
            axisScores: axisScores
        )
        lines.append(reading)
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
