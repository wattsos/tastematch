import SwiftUI

struct FavoritesScreen: View {
    @State private var favorites: [RecommendationItem] = []

    var body: some View {
        Group {
            if favorites.isEmpty {
                ContentUnavailableView(
                    "No Favorites Yet",
                    systemImage: "heart",
                    description: Text("Tap the heart on any recommendation to save it here.")
                )
            } else {
                List {
                    ForEach(favorites) { item in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(item.title)
                                .font(.headline)
                            Text(item.subtitle)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text(item.reason)
                                .font(.callout)
                                .italic()
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                    .onDelete { offsets in
                        deleteItems(at: offsets)
                    }
                }
            }
        }
        .navigationTitle("Favorites")
        .onAppear {
            favorites = FavoritesStore.loadAll()
        }
    }

    private func deleteItems(at offsets: IndexSet) {
        for index in offsets {
            FavoritesStore.remove(id: favorites[index].id)
        }
        favorites = FavoritesStore.loadAll()
    }
}
