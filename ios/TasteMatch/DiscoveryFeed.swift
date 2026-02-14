import SwiftUI

// MARK: - Discovery Item

struct DiscoveryItem: Identifiable, Hashable {
    let id: String
    let title: String
    let category: String
    let body: String
    let cluster: String
}

// MARK: - Discovery Feed

enum DiscoveryFeed {

    static func items(for axisScores: AxisScores) -> [DiscoveryItem] {
        let cluster = identifyCluster(axisScores)
        let primary = allItems.filter { $0.cluster == cluster }
        let others = allItems.filter { $0.cluster != cluster }
        return primary + Array(others.prefix(2))
    }

    private static func identifyCluster(_ scores: AxisScores) -> String {
        let clusters: [(String, Double)] = [
            ("industrialDark", scores.organicIndustrial + scores.lightDark),
            ("warmOrganic", scores.warmCool - scores.organicIndustrial),
            ("minimalNeutral", -scores.minimalOrnate - scores.neutralSaturated),
            ("layeredSaturated", scores.sparseLayered + scores.neutralSaturated),
        ]
        return clusters.max(by: { $0.1 < $1.1 })!.0
    }

    static let allItems: [DiscoveryItem] = [
        // Industrial / Dark
        DiscoveryItem(
            id: "disc-01", title: "Tadao Ando", category: "Architect",
            body: "Light carved from concrete. Ando's spaces are defined by what they omit — shadow becomes structural, silence becomes material.",
            cluster: "industrialDark"),
        DiscoveryItem(
            id: "disc-02", title: "Brutalism", category: "Movement",
            body: "Honest material at monumental scale. Concrete béton brut as ethical proposition, not stylistic choice.",
            cluster: "industrialDark"),
        DiscoveryItem(
            id: "disc-03", title: "Cor-Ten Steel", category: "Material",
            body: "Weathering steel that ages into a protective oxide patina. Time as collaborator, not adversary.",
            cluster: "industrialDark"),
        DiscoveryItem(
            id: "disc-04", title: "Bernd & Hilla Becher", category: "Photography",
            body: "Industrial typologies documented with forensic neutrality. The water tower as readymade sculpture.",
            cluster: "industrialDark"),
        DiscoveryItem(
            id: "disc-05", title: "Donald Judd", category: "Sculptor",
            body: "Specific objects in specific spaces. Marfa as proof that rigor and warmth can share a room.",
            cluster: "industrialDark"),

        // Warm / Organic
        DiscoveryItem(
            id: "disc-06", title: "Axel Vervoordt", category: "Designer",
            body: "Wabi imperfection married to European proportion. Spaces that feel found, not designed.",
            cluster: "warmOrganic"),
        DiscoveryItem(
            id: "disc-07", title: "Terracotta", category: "Material",
            body: "Earth fired into permanence. Every crack tells a thermal story, every glaze holds a geological memory.",
            cluster: "warmOrganic"),
        DiscoveryItem(
            id: "disc-08", title: "Malian Mudcloth", category: "Textile",
            body: "Bògòlanfini patterns fermented from riverbed clay. Geometry born from process, not drafting.",
            cluster: "warmOrganic"),
        DiscoveryItem(
            id: "disc-09", title: "Luis Barragán", category: "Architect",
            body: "Color as spatial membrane. Magenta walls that reorganize light and redirect emotional gravity.",
            cluster: "warmOrganic"),
        DiscoveryItem(
            id: "disc-10", title: "Olive Wood", category: "Material",
            body: "Grain patterns shaped by centuries of Mediterranean wind. No two cuts repeat.",
            cluster: "warmOrganic"),

        // Minimal / Neutral
        DiscoveryItem(
            id: "disc-11", title: "John Pawson", category: "Architect",
            body: "Minimum means maximum attention. Stone, light, proportion — nothing else admitted.",
            cluster: "minimalNeutral"),
        DiscoveryItem(
            id: "disc-12", title: "Shiro Kuramata", category: "Designer",
            body: "Glass, acrylic, and wire mesh dissolved into near-invisibility. Furniture as philosophical proposition.",
            cluster: "minimalNeutral"),
        DiscoveryItem(
            id: "disc-13", title: "Dieter Rams", category: "Designer",
            body: "Ten principles that argued design should be as little design as possible. Restraint as creative act.",
            cluster: "minimalNeutral"),
        DiscoveryItem(
            id: "disc-14", title: "Limestone", category: "Material",
            body: "Sedimentary patience compressed into surface. Cool to the touch, warm in register.",
            cluster: "minimalNeutral"),
        DiscoveryItem(
            id: "disc-15", title: "Naoto Fukasawa", category: "Designer",
            body: "Objects designed without outline. The cup handle that simply wasn't there.",
            cluster: "minimalNeutral"),

        // Layered / Saturated
        DiscoveryItem(
            id: "disc-16", title: "Riad Architecture", category: "Tradition",
            body: "Introverted opulence behind blank facades. Courtyard as world, zellige as infinity pattern.",
            cluster: "layeredSaturated"),
        DiscoveryItem(
            id: "disc-17", title: "India Mahdavi", category: "Designer",
            body: "Chromatic confidence deployed at architectural scale. Dusty pinks that refuse to whisper.",
            cluster: "layeredSaturated"),
        DiscoveryItem(
            id: "disc-18", title: "Fortuny Fabric", category: "Material",
            body: "Venetian silk-screened cotton carrying centuries of pattern vocabulary. Each pleat a stored memory.",
            cluster: "layeredSaturated"),
        DiscoveryItem(
            id: "disc-19", title: "Fez Medina", category: "Place",
            body: "Layered spatial compression where craft, commerce, and domesticity stack without separation.",
            cluster: "layeredSaturated"),
        DiscoveryItem(
            id: "disc-20", title: "Studio KO", category: "Practice",
            body: "Marrakech-based rigor that treats local craft as high modernism. Earth and geometry in equal measure.",
            cluster: "layeredSaturated"),
    ]
}

// MARK: - Discovery Detail Screen

struct DiscoveryDetailScreen: View {
    let item: DiscoveryItem

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(item.category.uppercased())
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.muted)
                    .tracking(1.2)

                Text(item.title)
                    .font(.system(size: 32, weight: .semibold, design: .serif))
                    .foregroundStyle(Theme.ink)

                HairlineDivider()

                Text(item.body)
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(Theme.ink)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .padding(.top, 8)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }
}
