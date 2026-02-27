import SwiftUI

struct IdentityDebugView: View {
    private let session = BurgundySession.shared
    @State private var eventsCount: Int? = nil
    @State private var pendingCount: Int? = nil

    var body: some View {
        List {
            Section("Identity") {
                debugRow("IDENTITY ID",   value: session.current.id.uuidString,   copyable: true)
                debugRow("VERSION",       value: "\(session.current.version)")
                debugRow("STABILITY",     value: String(format: "%.4f", session.current.stability))
                debugRow("ME / NOT / MAYBE", value: "\(session.current.countMe) / \(session.current.countNotMe) / \(session.current.countMaybe)")
            }

            Section("Device") {
                debugRow("DEVICE ID", value: DeviceInstallID.current, copyable: true)
            }

            Section("Sync") {
                if let date = session.lastSyncedAt {
                    debugRow("LAST SYNCED", value: formatted(date))
                } else {
                    debugRow("LAST SYNCED", value: "Not yet")
                }
                debugRow("FETCH SOURCE", value: session.lastFetchWasServer ? "Server" : "Local")
                debugRow("CACHED COUNT", value: "\(session.lastServerEventCount)")
                if let n = eventsCount {
                    debugRow("EVENTS (LIVE)", value: "\(n)")
                }
                if let n = pendingCount {
                    debugRow("PENDING (LIVE)", value: "\(n)")
                }
            }

            Section("Config") {
                debugRow("ENDPOINT", value: session.endpointURL.isEmpty ? "(not configured)" : session.endpointURL)
            }
        }
        .navigationTitle("IDENTITY DEBUG")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            do {
                let events = try await BurgundyAPI.fetchEvents(limit: 200)
                eventsCount = events.count
                pendingCount = events.filter { $0.pending }.count
            } catch {
                eventsCount = nil
            }
        }
    }

    private func debugRow(_ label: String, value: String, copyable: Bool = false) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .tracking(0.8)
                .foregroundStyle(Theme.muted)
                .fixedSize()
            Spacer()
            Text(value)
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.trailing)
                .lineLimit(2)
            if copyable {
                Button {
                    UIPasteboard.general.string = value
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.caption2)
                        .foregroundStyle(Theme.muted)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func formatted(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .medium
        return f.string(from: date)
    }
}
