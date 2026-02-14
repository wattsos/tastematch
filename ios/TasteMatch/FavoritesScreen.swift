import SwiftUI

struct FavoritesScreen: View {
    @State private var favorites: [RecommendationItem] = []
    @State private var searchText = ""

    private var filtered: [RecommendationItem] {
        guard !searchText.isEmpty else { return favorites }
        let query = searchText.lowercased()
        return favorites.filter {
            $0.title.lowercased().contains(query) ||
            $0.subtitle.lowercased().contains(query) ||
            $0.reason.lowercased().contains(query)
        }
    }

    var body: some View {
        Group {
            if favorites.isEmpty {
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "heart")
                        .font(.system(size: 48))
                        .foregroundStyle(Theme.blush)
                    Text("Nothing saved yet")
                        .font(Theme.headlineFont)
                        .foregroundStyle(Theme.espresso)
                    Text("When you find a piece you love,\ntap the heart to keep it here.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.clay)
                        .multilineTextAlignment(.center)
                    Spacer()
                }
            } else {
                List {
                    if filtered.isEmpty {
                        HStack {
                            Spacer()
                            VStack(spacing: 8) {
                                Image(systemName: "magnifyingglass")
                                    .font(.title2)
                                    .foregroundStyle(Theme.blush)
                                Text("No matches for \"\(searchText)\"")
                                    .font(.subheadline)
                                    .foregroundStyle(Theme.clay)
                            }
                            .padding(.vertical, 24)
                            Spacer()
                        }
                        .listRowBackground(Color.clear)
                    }

                    ForEach(filtered) { item in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(alignment: .firstTextBaseline) {
                                Text(item.title)
                                    .font(.headline)
                                    .foregroundStyle(Theme.espresso)
                                Spacer()
                                Text("$\(Int(item.price))")
                                    .font(.subheadline.monospacedDigit().weight(.medium))
                                    .foregroundStyle(Theme.accent)
                            }
                            Text(item.subtitle)
                                .font(.subheadline)
                                .foregroundStyle(Theme.clay)
                            Text(item.reason)
                                .font(.callout)
                                .italic()
                                .foregroundStyle(Theme.clay)
                        }
                        .padding(.vertical, 4)
                    }
                    .onDelete { offsets in
                        deleteItems(at: offsets)
                    }
                }
                .searchable(text: $searchText, prompt: "Search saved picks")
            }
        }
        .navigationTitle("Saved")
        .tint(Theme.accent)
        .onAppear {
            favorites = FavoritesStore.loadAll()
        }
    }

    private func deleteItems(at offsets: IndexSet) {
        let toDelete = offsets.map { filtered[$0] }
        for item in toDelete {
            FavoritesStore.remove(id: item.id)
        }
        favorites = FavoritesStore.loadAll()
    }
}
