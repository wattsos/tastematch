import Foundation

// MARK: - Object Calibration Record

struct ObjectCalibrationRecord: Codable {
    let tasteProfileId: UUID
    var vector: ObjectVector
    var swipeCount: Int
    let createdAt: Date

    // Legacy fields for decoding existing records
    private enum CodingKeys: String, CodingKey {
        case tasteProfileId, vector, swipeCount, createdAt
    }
}

// MARK: - Object Calibration Store

enum ObjectCalibrationStore {

    private static let fileName = "object_calibration.json"

    private static var fileURL: URL {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
    }

    // MARK: - Save

    static func save(_ record: ObjectCalibrationRecord) {
        var all = loadAll()
        all.removeAll { $0.tasteProfileId == record.tasteProfileId }
        all.append(record)
        write(all)
    }

    // MARK: - Load

    static func load(for profileId: UUID) -> ObjectCalibrationRecord? {
        loadAll().first { $0.tasteProfileId == profileId }
    }

    static func loadAll() -> [ObjectCalibrationRecord] {
        guard let data = try? Data(contentsOf: fileURL) else { return [] }
        return (try? JSONDecoder().decode([ObjectCalibrationRecord].self, from: data)) ?? []
    }

    // MARK: - Delete

    static func delete(for profileId: UUID) {
        var all = loadAll()
        all.removeAll { $0.tasteProfileId == profileId }
        write(all)
    }

    // MARK: - Clear

    static func clear() {
        try? FileManager.default.removeItem(at: fileURL)
    }

    // MARK: - Private

    private static func write(_ records: [ObjectCalibrationRecord]) {
        do {
            let data = try JSONEncoder().encode(records)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            // Fail silently — persistence is best-effort.
        }
    }
}
