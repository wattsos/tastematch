import Foundation

// MARK: - Config

/// Read from Info.plist (populated via Config.xcconfig or direct edit for local dev).
private enum SupabaseConfig {
    static var url: String {
        (Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String) ?? ""
    }
    static var anonKey: String {
        (Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String) ?? ""
    }
    static var isConfigured: Bool { !url.isEmpty && url != "$(SUPABASE_URL)" }
}

// MARK: - Wire types

struct RemoteIdentity: Decodable {
    let id: String
    let version: Int
    let embedding: [Double]
    let anti_embedding: [Double]
    let stability: Double
    let count_me: Int
    let count_not_me: Int
    let count_maybe: Int

    func toTasteIdentity() -> TasteIdentity {
        let emb  = embedding.count == 64 ? embedding : Array(repeating: 0.0, count: 64)
        let anti = anti_embedding.count == 64 ? anti_embedding : Array(repeating: 0.0, count: 64)
        var t = TasteIdentity(
            id: UUID(uuidString: id) ?? UUID(),
            embedding: StyleEmbedding(dims: emb),
            antiEmbedding: StyleEmbedding(dims: anti)
        )
        t.version    = version
        t.stability  = stability
        t.countMe    = count_me
        t.countNotMe = count_not_me
        t.countMaybe = count_maybe
        return t
    }
}

struct RemoteEvent: Decodable, Identifiable {
    let id: String
    let identity_id: String
    let vote: String
    let return_reason: String?
    let category: String
    let pending: Bool
    let created_at: String
    let scores: [String: Double]?
}

// MARK: - In-memory identity cache

/// Holds the server-resolved identity for the current session.
/// Falls back to IdentityStore when Supabase is not configured.
final class BurgundySession {
    static let shared = BurgundySession()
    private init() {}

    var identity: TasteIdentity?
    var lastSyncedAt: Date?
    var lastFetchWasServer: Bool = false
    var lastServerEventCount: Int = 0

    /// Base URL for edge functions (read-only, for debug display).
    var endpointURL: String { SupabaseConfig.url }

    /// Load identity — from server if configured, else from local store.
    func bootstrap() async {
        // Set synchronously so any vote before bootstrap completes uses real state.
        if identity == nil {
            identity = IdentityStore.load() ?? TasteIdentity()
        }
        guard SupabaseConfig.isConfigured else { return }
        do {
            let remote = try await BurgundyAPI.bootstrapIdentity()
            // Only adopt remote if no vote has happened yet (local version ≤ remote).
            if (identity?.version ?? 0) <= remote.version {
                identity = remote
                IdentityStore.save(remote)
            }
            lastSyncedAt = Date()
        } catch {
            // Already set to local above — nothing to do.
        }
    }

    /// Current identity, never nil (falls back to fresh identity).
    var current: TasteIdentity {
        get { identity ?? TasteIdentity() }
        set {
            identity = newValue
            IdentityStore.save(newValue)
        }
    }
}

// MARK: - BurgundyAPI

enum BurgundyAPI {

    // MARK: Bootstrap

    static func bootstrapIdentity() async throws -> TasteIdentity {
        let payload = ["device_install_id": DeviceInstallID.current]
        let data = try await post(path: "identity-bootstrap", body: payload)
        let resp = try JSONDecoder().decode(BootstrapResponse.self, from: data)
        return resp.identity.toTasteIdentity()
    }

    // MARK: Record event

    @discardableResult
    static func recordEvent(
        vote: TasteVote,
        evaluation: TasteEvaluation,
        returnReason: ReturnReason?,
        identity: TasteIdentity
    ) async throws -> (identity: TasteIdentity, pending: Bool) {
        var body: [String: Any] = [
            "device_install_id": DeviceInstallID.current,
            "identity_id":       identity.id.uuidString,
            "vote":              vote.rawValue,
            "category":          (evaluation.furnitureCategory ?? .other).rawValue,
            "object_embedding":  evaluation.candidate.embedding.dims,
            "scores": [
                "alignment":          evaluation.alignmentScore,
                "tension":            evaluation.tensionScore,
                "purchase_confidence": evaluation.purchaseConfidence,
            ] as [String: Any],
        ]
        if let reason = returnReason { body["return_reason"] = reason.rawValue }

        let data = try await post(path: "record-event", body: body)
        let resp = try JSONDecoder().decode(RecordEventResponse.self, from: data)
        return (resp.identity.toTasteIdentity(), resp.pending)
    }

    // MARK: Fetch events (for History)

    static func fetchEvents(limit: Int = 50) async throws -> [RemoteEvent] {
        guard let id = BurgundySession.shared.identity?.id else { return [] }
        let path = "fetch-events?identity_id=\(id.uuidString)&device_install_id=\(DeviceInstallID.current)&limit=\(limit)"
        let data = try await get(path: path)
        let resp = try JSONDecoder().decode(FetchEventsResponse.self, from: data)
        BurgundySession.shared.lastFetchWasServer = true
        BurgundySession.shared.lastServerEventCount = resp.events.count
        return resp.events
    }

    // MARK: - HTTP helpers

    private static func post(path: String, body: [String: Any]) async throws -> Data {
        guard let url = URL(string: "\(SupabaseConfig.url)/functions/v1/\(path)") else {
            throw URLError(.badURL)
        }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json",                  forHTTPHeaderField: "Content-Type")
        req.setValue(SupabaseConfig.anonKey,              forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(SupabaseConfig.anonKey)",  forHTTPHeaderField: "Authorization")
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: req)
        if let http = response as? HTTPURLResponse, http.statusCode >= 400 {
            throw URLError(.badServerResponse)
        }
        return data
    }

    private static func get(path: String) async throws -> Data {
        guard let url = URL(string: "\(SupabaseConfig.url)/functions/v1/\(path)") else {
            throw URLError(.badURL)
        }
        var req = URLRequest(url: url)
        req.setValue(SupabaseConfig.anonKey,              forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(SupabaseConfig.anonKey)",  forHTTPHeaderField: "Authorization")
        let (data, response) = try await URLSession.shared.data(for: req)
        if let http = response as? HTTPURLResponse, http.statusCode >= 400 {
            throw URLError(.badServerResponse)
        }
        return data
    }
}

// MARK: - Response types

private struct BootstrapResponse: Decodable {
    let identity: RemoteIdentity
}

private struct RecordEventResponse: Decodable {
    let identity: RemoteIdentity
    let pending: Bool
}

private struct FetchEventsResponse: Decodable {
    let events: [RemoteEvent]
}
