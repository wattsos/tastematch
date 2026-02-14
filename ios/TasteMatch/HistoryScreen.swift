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
                    Text("Every room you analyze will\nshow up here over time.")
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
                                    if let secondary = saved.tasteProfile.tags.dropFirst().first {
                                        Text(secondary.label)
                                            .font(.subheadline)
                                            .foregroundStyle(Theme.clay)
                                    }
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
        if let record = CalibrationStore.load(for: saved.tasteProfile.id) {
            let imageVector = TasteEngine.vectorFromProfile(saved.tasteProfile)
            let blended = TasteVector.blend(image: imageVector, swipe: record.vector.normalized(), mode: .wantMore)
            let reranked = RecommendationEngine.rankWithVector(
                saved.recommendations,
                vector: blended,
                catalog: MockCatalog.items,
                context: saved.roomContext,
                goal: saved.designGoal
            )
            path.append(Route.result(saved.tasteProfile, reranked))
        } else {
            path.append(Route.result(saved.tasteProfile, saved.recommendations))
        }
    }
}
