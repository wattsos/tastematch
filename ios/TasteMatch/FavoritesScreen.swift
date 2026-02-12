import SwiftUI

struct FavoritesScreen: View {
    @State private var favorites: [RecommendationItem] = []

    var body: some View {
        Group {
            if favorites.isEmpty {
                ContentUnavailableView(
                    "No Favorites Yet",
                    systemImage: "heart",
                    description: Text("Tap the heart on any pick to save it here.")
                )
            } else {
                List {
                    ForEach(favorites) { item in
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
            }
        }
        .navigationTitle("Saved")
        .tint(Theme.accent)
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
