import Foundation

// MARK: - Models

struct CalibratorItem: Identifiable, Decodable {
    let object_id: String
    let title: String
    let image_url: String?
    let category: String?
    let brand: String?

    var id: String { object_id }
}

private struct ItemsResponse: Decodable {
    let ok: Bool
    let items: [CalibratorItem]
}

// MARK: - Oracle Models

struct OracleItem: Decodable {
    let object_id: String
    let title: String
    let image_url: String?
    let category: String?
    let brand: String?
    let similarity: Double?
}

struct PredictionResult: Decodable {
    let ok: Bool
    let top_match: OracleItem
    let bottom_match: OracleItem
}

// MARK: - API

enum CalibratorAPI {

    private static let baseURL = "http://localhost:3001"

    /// Fetch 10 random catalog items that have embeddings.
    static func fetchItems() async throws -> [CalibratorItem] {
        guard let url = URL(string: "\(baseURL)/api/calibrate/items") else {
            throw URLError(.badURL)
        }
        let (data, response) = try await URLSession.shared.data(from: url)
        if let http = response as? HTTPURLResponse, http.statusCode >= 400 {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(ItemsResponse.self, from: data).items
    }

    /// Fetch the oracle prediction: top and bottom match for the user's current identity vector.
    static func fetchPrediction(userId: String) async throws -> PredictionResult {
        guard let url = URL(string: "\(baseURL)/api/calibrate/prediction?user_id=\(userId)") else {
            throw URLError(.badURL)
        }
        let (data, response) = try await URLSession.shared.data(from: url)
        if let http = response as? HTTPURLResponse, http.statusCode >= 400 {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(PredictionResult.self, from: data)
    }

    /// Record a swipe event and update the user's calibrator identity vector.
    /// Fire-and-forget: failures are logged in DEBUG but do not surface to the UI.
    static func sendSwipe(userId: String, objectId: String, action: String) async {
        guard let url = URL(string: "\(baseURL)/api/calibrate/swipe") else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = ["user_id": userId, "object_id": objectId, "action": action]
        req.httpBody = try? JSONEncoder().encode(body)
        do {
            let (_, response) = try await URLSession.shared.data(for: req)
            #if DEBUG
            if let http = response as? HTTPURLResponse {
                print("[CalibratorAPI] swipe \(action) → HTTP \(http.statusCode)")
            }
            #endif
        } catch {
            #if DEBUG
            print("[CalibratorAPI] sendSwipe failed: \(error.localizedDescription)")
            #endif
        }
    }
}
