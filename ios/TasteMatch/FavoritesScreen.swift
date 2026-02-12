import SwiftUI

struct FavoritesScreen: View {
    @State private var favorites: [RecommendationItem] = []

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
