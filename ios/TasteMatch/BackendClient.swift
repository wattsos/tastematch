import Foundation

// MARK: - Backend Protocol

protocol BackendClient {
    func saveProfile(_ snapshot: ProfileSnapshot) async throws
    func getProfile(id: UUID) async throws -> ProfileSnapshot?
    func shareProfile(_ snapshot: ProfileSnapshot) async throws -> ShareResponse
    func sendEvents(_ events: [LoggedEvent]) async throws
}

// MARK: - Backend Error

enum BackendError: Error {
    case notImplemented
}

// MARK: - Local Backend Client

struct LocalBackendClient: BackendClient {

    func saveProfile(_ snapshot: ProfileSnapshot) async throws {
        // No-op: ProfileStore already handles local persistence.
    }

    func getProfile(id: UUID) async throws -> ProfileSnapshot? {
        let all = ProfileStore.loadAll()
        guard let saved = all.first(where: { $0.id == id }) else { return nil }

        let profile = saved.tasteProfile
        let vector = TasteEngine.vectorFromProfile(profile)
        let axisScores = AxisMapping.computeAxisScores(from: vector)
        let swipeCount = CalibrationStore.load(for: id)?.swipeCount ?? 0
        let confidenceLevel = CalibrationStore.load(for: id)?.vector.confidenceLevel(swipeCount: swipeCount) ?? "Low"

        let influences = AxisPresentation.influencePhrases(axisScores: axisScores)
        let avoids = AxisPresentation.avoidPhrases(axisScores: axisScores)

        return ProfileSnapshot(
            id: profile.id,
            userId: nil,
            profileName: profile.displayName,
            axisScores: axisScores.toDictionary(),
            basisHash: profile.profileNameBasisHash,
            confidenceLevel: confidenceLevel,
            influences: influences,
            avoids: avoids,
            createdAt: saved.savedAt,
            updatedAt: profile.profileNameUpdatedAt ?? saved.savedAt
        )
    }

    func shareProfile(_ snapshot: ProfileSnapshot) async throws -> ShareResponse {
        let slug = snapshot.id.uuidString.prefix(8).lowercased()
        return ShareResponse(
            slug: String(slug),
            publicURL: "https://burgundy.app/p/\(slug)"
        )
    }

    func sendEvents(_ events: [LoggedEvent]) async throws {
        // No-op: EventLogger already queues to disk locally.
    }
}

// MARK: - Remote Backend Client

struct RemoteBackendClient: BackendClient {

    private let baseURL = URL(string: "https://api.burgundy.app/v1")!

    func saveProfile(_ snapshot: ProfileSnapshot) async throws {
        // TODO: implement with URLSession — POST /profiles
        throw BackendError.notImplemented
    }

    func getProfile(id: UUID) async throws -> ProfileSnapshot? {
        // TODO: implement with URLSession — GET /profiles/:id
        throw BackendError.notImplemented
    }

    func shareProfile(_ snapshot: ProfileSnapshot) async throws -> ShareResponse {
        // TODO: implement with URLSession — POST /profiles/:id/share
        throw BackendError.notImplemented
    }

    func sendEvents(_ events: [LoggedEvent]) async throws {
        // TODO: implement with URLSession — POST /events
        throw BackendError.notImplemented
    }
}
