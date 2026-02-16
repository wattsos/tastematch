import SwiftUI

struct HistoryScreen: View {
    @Binding var path: NavigationPath
    @State private var history: [SavedProfile] = []

    var body: some View {
        Group {
            if history.isEmpty {
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "clock")
                        .font(.system(size: 48))
                        .foregroundStyle(Theme.blush)
                    Text("No analyses yet")
                        .font(Theme.headlineFont)
                        .foregroundStyle(Theme.espresso)
                    Text(DomainCopy.historyLine(DomainStore.current))
                        .font(.subheadline)
                        .foregroundStyle(Theme.clay)
                        .multilineTextAlignment(.center)
                    Spacer()
                }
            } else {
                List {
                    ForEach(history.reversed()) { saved in
                        Button {
                            navigateToResult(saved: saved)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(saved.tasteProfile.displayName)
                                        .font(.headline)
                                        .foregroundStyle(Theme.espresso)
                                    Text(formatted(saved.savedAt))
                                        .font(.caption)
                                        .foregroundStyle(Theme.clay.opacity(0.7))
                                }
                                Spacer()
                                if let confidence = saved.tasteProfile.tags.first?.confidence {
                                    Text(alignmentWord(confidence))
                                        .font(.caption2)
                                        .foregroundStyle(Theme.muted)
                                }
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(Theme.blush)
                            }
                        }
                        .foregroundStyle(.primary)
                        .swipeActions(edge: .leading) {
                            Button {
                                let domain = saved.domain ?? .space
                                if domain == .space {
                                    path.append(Route.reanalyze(
                                        saved.roomContext ?? .livingRoom,
                                        saved.designGoal ?? .refresh
                                    ))
                                } else {
                                    path.append(Route.newScan(domain))
                                }
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

    private func alignmentWord(_ confidence: Double) -> String {
        switch confidence {
        case 0.8...: return "High"
        case 0.5...: return "Moderate"
        default:     return "Low"
        }
    }

    private func formatted(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func navigateToResult(saved: SavedProfile) {
        path.append(Route.profile(saved.tasteProfile.id))
    }
}
