import Foundation

struct CalibrationRecord: Codable {
    let tasteProfileId: UUID
    var vector: TasteVector
    var swipeCount: Int
    let createdAt: Date
}

enum CalibrationStore {

    private static let fileName = "calibration_data.json"

    private static var fileURL: URL {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
    }

    // MARK: - Save

    static func save(_ record: CalibrationRecord) {
        var all = loadAll()
        all.removeAll { $0.tasteProfileId == record.tasteProfileId }
        all.append(record)
        write(all)
    }

    // MARK: - Load

    static func load(for profileId: UUID) -> CalibrationRecord? {
        loadAll().first { $0.tasteProfileId == profileId }
    }

    static func loadAll() -> [CalibrationRecord] {
        guard let data = try? Data(contentsOf: fileURL) else { return [] }
        return (try? JSONDecoder().decode([CalibrationRecord].self, from: data)) ?? []
    }

    // MARK: - Delete

    static func delete(for profileId: UUID) {
        var all = loadAll()
        all.removeAll { $0.tasteProfileId == profileId }
        write(all)
    }

    // MARK: - Private

    private static func write(_ records: [CalibrationRecord]) {
        do {
            let data = try JSONEncoder().encode(records)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            // Fail silently — persistence is best-effort.
        }
    }
}
