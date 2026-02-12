import Foundation

final class APIClient {
    static let shared = APIClient()

    // Would point at real backend; unused for now.
    private let baseURL = URL(string: "https://api.tastematch.dev/v1")!

    private init() {}

    // MARK: - POST /analyze

    func analyze(imageData: [Data], roomContext: String, goal: String) async throws -> AnalyzeResponse {
        // Stub: simulate network delay then return mock data.
        try await Task.sleep(for: .seconds(1.2))
        return AnalyzeResponse(
            tasteProfile: .mock,
            recommendations: RecommendationItem.mocks
        )
    }

    // MARK: - POST /events

    func sendEvent(name: String, tasteProfileId: UUID?, metadata: [String: String]) async throws {
        // Stub: would POST to /events endpoint.
        try await Task.sleep(for: .seconds(0.1))
    }
}

// MARK: - Mock data

extension TasteProfile {
    static let mock = TasteProfile(
        tags: [
            TasteTag(label: "Mid-Century Modern", confidence: 0.92),
            TasteTag(label: "Warm Minimalism", confidence: 0.85),
            TasteTag(label: "Earthy Tones", confidence: 0.78),
            TasteTag(label: "Natural Textures", confidence: 0.71),
        ],
        story: "You gravitate toward clean lines softened by warm woods and organic materials. "
            + "Your space tells a story of intentional simplicity — every piece earns its place, "
            + "yet the overall feel is inviting rather than stark.",
        signals: [
            Signal(key: "dominant_palette", value: "Warm neutrals with olive accents"),
            Signal(key: "material_preference", value: "Walnut, linen, ceramic"),
            Signal(key: "pattern_tolerance", value: "Low — solid & subtle grain"),
            Signal(key: "layout_density", value: "Moderate — curated, not sparse"),
        ]
    )
}

extension RecommendationItem {
    static let mocks: [RecommendationItem] = [
        RecommendationItem(
            title: "Walnut Credenza",
            subtitle: "Article — $899",
            reason: "Anchors your mid-century aesthetic while adding hidden storage."
        ),
        RecommendationItem(
            title: "Linen Throw Pillows (set of 2)",
            subtitle: "Parachute — $120",
            reason: "Softens seating with the natural texture you're drawn to."
        ),
        RecommendationItem(
            title: "Ceramic Table Lamp",
            subtitle: "West Elm — $149",
            reason: "Earthy glaze echoes your warm-neutral palette."
        ),
        RecommendationItem(
            title: "Olive Accent Chair",
            subtitle: "CB2 — $649",
            reason: "Introduces your secondary color in a statement piece."
        ),
    ]
}
