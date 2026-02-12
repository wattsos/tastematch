import Foundation
import UIKit

final class APIClient {
    static let shared = APIClient()

    // Would point at real backend; unused for now.
    private let baseURL = URL(string: "https://api.tastematch.dev/v1")!

    private init() {}

    // MARK: - POST /analyze

    func analyze(
        imageData: [Data],
        roomContext: RoomContext,
        goal: DesignGoal
    ) async throws -> AnalyzeResponse {
        // Stub: simulate network latency.
        try await Task.sleep(for: .seconds(0.3))

        let signals = Self.mockSignals(from: imageData)
        let profile = TasteEngine.analyze(
            signals: signals,
            context: roomContext,
            goal: goal
        )

        return AnalyzeResponse(
            tasteProfile: profile,
            recommendations: RecommendationItem.mocks
        )
    }

    // MARK: - POST /events

    func sendEvent(name: String, tasteProfileId: UUID?, metadata: [String: String]) async throws {
        // Stub: would POST to /events endpoint.
        try await Task.sleep(for: .seconds(0.1))
    }

    // MARK: - Signal extraction placeholder

    /// Placeholder that returns fixed signals regardless of image content.
    /// Replace with real CV extraction when the vision pipeline lands.
    static func mockSignals(from imageData: [Data]) -> VisualSignals {
        VisualSignals(
            paletteTemperature: .warm,
            brightness: .medium,
            contrast: .medium,
            saturation: .neutral,
            edgeDensity: .medium,
            material: .wood
        )
    }
}

// MARK: - Mock recommendations (engine doesn't produce these yet)

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
