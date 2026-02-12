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

        let recommendations = RecommendationEngine.recommend(
            profile: profile,
            catalog: MockCatalog.items,
            context: roomContext,
            goal: goal,
            limit: 6
        )

        return AnalyzeResponse(
            tasteProfile: profile,
            recommendations: recommendations
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

