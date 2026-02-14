import SwiftUI

struct BoardScreen: View {
    @Binding var path: NavigationPath
    let items: [RecommendationItem]
    @State private var saved: [RecommendationItem] = []

    var body: some View {
        ScrollView {
            if saved.isEmpty {
                emptyState
            } else {
                boardGrid
            }
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            let favoriteKeys = Set(FavoritesStore.loadAll().map { "\($0.title)|\($0.subtitle)" })
            saved = items.filter { favoriteKeys.contains("\($0.title)|\($0.subtitle)") }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 80)

            VStack(alignment: .leading, spacing: 20) {
                Text("BOARD")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.muted)
                    .tracking(1.2)

                Text("Nothing here yet.")
                    .font(.system(size: 28, weight: .semibold, design: .serif))
                    .foregroundStyle(Theme.ink)

                Text("Bookmark items from your selection\nto assemble a board.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.muted)
                    .lineSpacing(3)

                Button {
                    Haptics.tap()
                    path.removeLast()
                } label: {
                    Text("[ Add from Selection ]")
                        .font(.caption.weight(.medium).monospaced())
                        .foregroundStyle(Theme.ink)
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)

            Spacer(minLength: 80)
        }
    }

    // MARK: - Board Grid

    private var boardGrid: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text("BOARD")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.muted)
                    .tracking(1.2)

                Text("\(saved.count) \(saved.count == 1 ? "piece" : "pieces")")
                    .font(.caption2)
                    .foregroundStyle(Theme.muted)
            }

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 14),
                    GridItem(.flexible(), spacing: 14)
                ],
                spacing: 14
            ) {
                ForEach(saved) { item in
                    boardCard(item)
                }
            }
        }
        .padding(16)
    }

    // MARK: - Board Card

    private func boardCard(_ item: RecommendationItem) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            CachedImage(url: item.imageURL, height: 150)

            VStack(alignment: .leading, spacing: 6) {
                Text(item.title)
                    .font(.system(.subheadline, design: .default, weight: .medium))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(2)

                Text("$\(Int(item.price))")
                    .font(.caption.monospacedDigit().weight(.medium))
                    .foregroundStyle(Theme.muted)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
        .labSurface(padded: false, bordered: true)
    }
}
