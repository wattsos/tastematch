import SwiftUI

struct ResultScreen: View {
    @Binding var path: NavigationPath
    let profile: TasteProfile
    let recommendations: [RecommendationItem]
    @State private var showShareSheet = false
    @State private var favoritedIds: Set<String> = []

    var body: some View {
        List {
            Section("Your Taste Tags") {
                ForEach(profile.tags) { tag in
                    HStack(spacing: 12) {
                        Text(tag.label)
                            .font(.body.weight(.medium))
                        Spacer()
                        ProgressView(value: tag.confidence)
                            .frame(width: 80)
                        Text("\(Int(tag.confidence * 100))%")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                            .frame(width: 36, alignment: .trailing)
                    }
                }
            }

            Section("Story") {
                Text(profile.story)
                    .font(.body)
                    .lineSpacing(3)
            }

            Section("Signals") {
                ForEach(profile.signals) { signal in
                    HStack {
                        Text(signal.key.replacingOccurrences(of: "_", with: " ").capitalized)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(width: 120, alignment: .leading)
                        Spacer()
                        Text(signal.value.capitalized)
                            .font(.body)
                    }
                }
            }

            Section("Recommendations") {
                ForEach(recommendations) { item in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(item.title)
                                .font(.headline)
                            Spacer()
                            Text(confidenceLabel(item.attributionConfidence))
                                .font(.caption2.weight(.medium))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(confidenceColor(item.attributionConfidence).opacity(0.15))
                                .foregroundStyle(confidenceColor(item.attributionConfidence))
                                .clipShape(Capsule())
                        }
                        Text(item.subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        HStack {
                            Text(item.reason)
                                .font(.callout)
                                .italic()
                                .foregroundStyle(.secondary)
                            Spacer()
                            Button {
                                toggleFavorite(item)
                            } label: {
                                Image(systemName: isFavorited(item) ? "heart.fill" : "heart")
                                    .foregroundStyle(isFavorited(item) ? .red : .secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Results")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    showShareSheet = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Start Over") {
                    ProfileStore.clear()
                    path = NavigationPath()
                }
                .font(.subheadline)
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(text: shareSummary)
        }
        .onAppear {
            EventLogger.shared.logEvent("results_viewed", tasteProfileId: profile.id)
            refreshFavorites()
        }
    }

    // MARK: - Favorites

    private func isFavorited(_ item: RecommendationItem) -> Bool {
        favoritedIds.contains(favoriteKey(item))
    }

    private func toggleFavorite(_ item: RecommendationItem) {
        let key = favoriteKey(item)
        if favoritedIds.contains(key) {
            favoritedIds.remove(key)
            // Find the stored favorite by matching title+subtitle and remove it
            let stored = FavoritesStore.loadAll()
            if let match = stored.first(where: { $0.title == item.title && $0.subtitle == item.subtitle }) {
                FavoritesStore.remove(id: match.id)
            }
        } else {
            favoritedIds.insert(key)
            FavoritesStore.add(item)
        }
    }

    private func refreshFavorites() {
        let stored = FavoritesStore.loadAll()
        favoritedIds = Set(stored.map { "\($0.title)|\($0.subtitle)" })
    }

    private func favoriteKey(_ item: RecommendationItem) -> String {
        "\(item.title)|\(item.subtitle)"
    }

    // MARK: - Attribution Helpers

    private func confidenceLabel(_ value: Double) -> String {
        switch value {
        case 0.8...: return "Strong match"
        case 0.5...: return "Good match"
        default:     return "Partial match"
        }
    }

    private func confidenceColor(_ value: Double) -> Color {
        switch value {
        case 0.8...: return .green
        case 0.5...: return .orange
        default:     return .secondary
        }
    }

    // MARK: - Share Summary

    private var shareSummary: String {
        var lines: [String] = []

        lines.append("My TasteMatch Results")
        lines.append("")

        // Tags
        let tagLine = profile.tags.map { "\($0.label) (\(Int($0.confidence * 100))%)" }.joined(separator: ", ")
        lines.append("Style: \(tagLine)")
        lines.append("")

        // Story
        lines.append(profile.story)
        lines.append("")

        // Recommendations
        lines.append("Top Picks:")
        for item in recommendations {
            lines.append("- \(item.title) — \(item.subtitle)")
        }

        lines.append("")
        lines.append("Analyzed with TasteMatch")

        return lines.joined(separator: "\n")
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let text: String

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [text], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
