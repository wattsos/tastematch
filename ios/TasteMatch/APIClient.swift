import Foundation
import UIKit

final class APIClient {
    static let shared = APIClient()

    // Would point at real backend; unused for now.
    private let baseURL = URL(string: "https://api.burgundy.app/v1")!
    private let catalog: CatalogProvider

    var backend: BackendClient {
        switch FeatureFlags.backendMode {
        case .local:  return LocalBackendClient()
        case .remote: return RemoteBackendClient()
        }
    }

    private init(catalog: CatalogProvider = BundleCatalogProvider()) {
        self.catalog = catalog
    }

    // MARK: - POST /analyze

    func analyze(
        imageData: [Data],
        roomContext: RoomContext,
        goal: DesignGoal
    ) async throws -> AnalyzeResponse {
        // Stub: simulate network latency.
        try await Task.sleep(for: .seconds(0.3))

        let signals = SignalExtractor.extract(from: imageData)
        let profile = TasteEngine.analyze(
            signals: signals,
            context: roomContext,
            goal: goal
        )

        let recommendations = RecommendationEngine.recommend(
            profile: profile,
            catalog: catalog.items,
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
        let event = LoggedEvent(name: name, tasteProfileId: tasteProfileId, metadata: metadata)
        try await backend.sendEvents([event])
    }

}

