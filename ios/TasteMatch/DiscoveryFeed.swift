import SwiftUI

// MARK: - Discovery Detail Screen

struct DiscoveryDetailScreen: View {
    let item: DiscoveryItem

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(item.type.rawValue.uppercased())
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.muted)
                    .tracking(1.2)

                Text(item.title)
                    .font(.system(size: 32, weight: .semibold, design: .serif))
                    .foregroundStyle(Theme.ink)

                if !item.primaryRegion.isEmpty {
                    Text(item.primaryRegion)
                        .font(.caption)
                        .foregroundStyle(Theme.muted)
                }

                HairlineDivider()

                Text(item.body)
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(Theme.ink)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .padding(.top, 8)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }
}
