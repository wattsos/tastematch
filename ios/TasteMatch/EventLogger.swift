import Foundation
import os

final class EventLogger {
    static let shared = EventLogger()

    private let logger = Logger(subsystem: "dev.tastematch", category: "events")

    private init() {}

    func logEvent(
        _ eventName: String,
        tasteProfileId: UUID? = nil,
        metadata: [String: String] = [:]
    ) {
        logger.info("[\(eventName)] profile=\(tasteProfileId?.uuidString ?? "nil") meta=\(metadata)")

        // Fire-and-forget to backend stub.
        Task {
            try? await APIClient.shared.sendEvent(
                name: eventName,
                tasteProfileId: tasteProfileId,
                metadata: metadata
            )
        }
    }
}
