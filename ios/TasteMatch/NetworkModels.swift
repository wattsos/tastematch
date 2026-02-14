import Foundation

// MARK: - Profile Snapshot

struct ProfileSnapshot: Codable {
    let id: UUID
    let userId: String?
    let profileName: String
    let axisScores: [String: Double]
    let basisHash: String
    let confidenceLevel: String
    let influences: [String]
    let avoids: [String]
    let createdAt: Date
    let updatedAt: Date
}

// MARK: - Share Response

struct ShareResponse: Codable {
    let slug: String
    let publicURL: String
}

// MARK: - AxisScores → Dictionary

extension AxisScores {
    func toDictionary() -> [String: Double] {
        var dict: [String: Double] = [:]
        for axis in Axis.allCases {
            dict[axis.rawValue] = value(for: axis)
        }
        return dict
    }
}
