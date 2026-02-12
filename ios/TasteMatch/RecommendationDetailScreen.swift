import SwiftUI

struct RecommendationDetailScreen: View {
    let item: RecommendationItem
    @State private var isFavorited = false

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text(item.title)
                        .font(.title2.weight(.bold))
                    Text(item.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            Section("Price") {
                HStack {
                    Text("$\(Int(item.price))")
                        .font(.title.weight(.semibold))
                    Spacer()
                    Button {
                        toggleFavorite()
                    } label: {
                        Label(
                            isFavorited ? "Saved" : "Save",
                            systemImage: isFavorited ? "heart.fill" : "heart"
                        )
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(isFavorited ? .red : .accentColor)
                    }
                    .buttonStyle(.plain)
                }
            }

            Section("Why This Fits") {
                Text(item.reason)
                    .font(.body)
                    .lineSpacing(3)
            }

            Section("Match Strength") {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(confidenceLabel)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(confidenceColor)
                        Spacer()
                        Text("\(Int(item.attributionConfidence * 100))%")
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    ProgressView(value: item.attributionConfidence)
                        .tint(confidenceColor)
                }
            }

            Section {
                Button {
                    // Placeholder — will open productURL when real catalog lands
                } label: {
                    HStack {
                        Spacer()
                        VStack(spacing: 2) {
                            Text("View Product")
                                .font(.body.weight(.semibold))
                            Text("Coming soon")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
                .disabled(true)
            }
        }
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            isFavorited = FavoritesStore.isFavorited(item)
        }
    }

    // MARK: - Favorites

    private func toggleFavorite() {
        Haptics.tap()
        if isFavorited {
            let stored = FavoritesStore.loadAll()
            if let match = stored.first(where: { $0.title == item.title && $0.subtitle == item.subtitle }) {
                FavoritesStore.remove(id: match.id)
            }
        } else {
            FavoritesStore.add(item)
        }
        isFavorited.toggle()
    }

    // MARK: - Attribution Helpers

    private var confidenceLabel: String {
        switch item.attributionConfidence {
        case 0.8...: return "Strong match"
        case 0.5...: return "Good match"
        default:     return "Partial match"
        }
    }

    private var confidenceColor: Color {
        switch item.attributionConfidence {
        case 0.8...: return .green
        case 0.5...: return .orange
        default:     return .secondary
        }
    }
}
