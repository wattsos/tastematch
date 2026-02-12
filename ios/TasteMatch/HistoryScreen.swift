import SwiftUI

struct HistoryScreen: View {
    @Binding var path: NavigationPath
    @State private var history: [SavedProfile] = []

    var body: some View {
        Group {
            if history.isEmpty {
                ContentUnavailableView(
                    "No History Yet",
                    systemImage: "clock",
                    description: Text("Your past analyses will appear here.")
                )
            } else {
                List {
                    ForEach(history.reversed()) { saved in
                        Button {
                            path.append(Route.result(saved.tasteProfile, saved.recommendations))
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(saved.tasteProfile.tags.first?.label ?? "Unknown Style")
                                        .font(.headline)
                                    if let secondary = saved.tasteProfile.tags.dropFirst().first {
                                        Text(secondary.label)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                    Text(formatted(saved.savedAt))
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                }
                                Spacer()
                                if let confidence = saved.tasteProfile.tags.first?.confidence {
                                    Text("\(Int(confidence * 100))%")
                                        .font(.caption.monospacedDigit())
                                        .foregroundStyle(.secondary)
                                }
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .foregroundStyle(.primary)
                        .swipeActions(edge: .leading) {
                            Button {
                                path.append(Route.reanalyze(
                                    saved.roomContext ?? .livingRoom,
                                    saved.designGoal ?? .refresh
                                ))
                            } label: {
                                Label("Re-analyze", systemImage: "arrow.clockwise")
                            }
                            .tint(.blue)
                        }
                    }
                    .onDelete { offsets in
                        deleteItems(at: offsets)
                    }
                }
            }
        }
        .navigationTitle("History")
        .tint(Theme.accent)
        .toolbar {
            if history.count >= 2 {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        Button {
                            path.append(Route.evolution)
                        } label: {
                            Label("Evolution", systemImage: "chart.line.uptrend.xyaxis")
                        }
                        Button {
                            path.append(Route.compare)
                        } label: {
                            Label("Compare", systemImage: "arrow.left.arrow.right")
                        }
                    }
                }
            }
        }
        .onAppear {
            history = ProfileStore.loadAll()
        }
    }

    private func deleteItems(at offsets: IndexSet) {
        // History is displayed reversed, so map offsets back to original order
        let reversed = Array(history.reversed())
        for index in offsets {
            let item = reversed[index]
            ProfileStore.delete(id: item.id)
        }
        history = ProfileStore.loadAll()
    }

    private func formatted(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
