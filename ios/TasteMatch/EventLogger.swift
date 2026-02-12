import Foundation
import os

final class EventLogger {
    static let shared = EventLogger()

    private let logger = Logger(subsystem: "com.itme2", category: "events")
    private let queue = DispatchQueue(label: "com.itme2.eventlogger")

    private static let fileName = "event_queue.json"
    private static var fileURL: URL {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
    }

    private init() {}

    // MARK: - Log

    func logEvent(
        _ eventName: String,
        tasteProfileId: UUID? = nil,
        metadata: [String: String] = [:]
    ) {
        let event = LoggedEvent(
            name: eventName,
            tasteProfileId: tasteProfileId,
            metadata: metadata,
            timestamp: Date()
        )

        logger.info("[\(eventName)] profile=\(tasteProfileId?.uuidString ?? "nil") meta=\(metadata)")

        queue.async { [weak self] in
            self?.enqueue(event)
        }

        // Attempt to flush in background.
        Task { await flush() }
    }

    // MARK: - Flush

    func flush() async {
        let events = dequeueAll()
        guard !events.isEmpty else { return }

        var failures: [LoggedEvent] = []
        for event in events {
            do {
                try await APIClient.shared.sendEvent(
                    name: event.name,
                    tasteProfileId: event.tasteProfileId,
                    metadata: event.metadata
                )
            } catch {
                failures.append(event)
            }
        }

        // Re-enqueue any events that failed to send.
        if !failures.isEmpty {
            queue.sync {
                var existing = Self.loadQueue()
                existing.insert(contentsOf: failures, at: 0)
                Self.writeQueue(existing)
            }
        }
    }

    // MARK: - Queue Info

    var pendingCount: Int {
        queue.sync { Self.loadQueue().count }
    }

    func clearQueue() {
        queue.async {
            try? FileManager.default.removeItem(at: Self.fileURL)
        }
    }

    // MARK: - Private

    private func enqueue(_ event: LoggedEvent) {
        var events = Self.loadQueue()
        events.append(event)
        Self.writeQueue(events)
    }

    private func dequeueAll() -> [LoggedEvent] {
        queue.sync {
            let events = Self.loadQueue()
            if !events.isEmpty {
                Self.writeQueue([])
            }
            return events
        }
    }

    private static func loadQueue() -> [LoggedEvent] {
        guard let data = try? Data(contentsOf: fileURL) else { return [] }
        return (try? JSONDecoder().decode([LoggedEvent].self, from: data)) ?? []
    }

    private static func writeQueue(_ events: [LoggedEvent]) {
        do {
            let data = try JSONEncoder().encode(events)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            // Best-effort persistence.
        }
    }
}

// MARK: - Event Model

struct LoggedEvent: Codable {
    let id: UUID
    let name: String
    let tasteProfileId: UUID?
    let metadata: [String: String]
    let timestamp: Date

    init(name: String, tasteProfileId: UUID? = nil, metadata: [String: String] = [:], timestamp: Date = Date()) {
        self.id = UUID()
        self.name = name
        self.tasteProfileId = tasteProfileId
        self.metadata = metadata
        self.timestamp = timestamp
    }
}
