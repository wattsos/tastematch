import SwiftUI

struct OracleRevealView: View {
    let topMatch: OracleItem
    let bottomMatch: OracleItem
    let onContinue: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                header
                    .padding(.top, 52)
                    .padding(.bottom, 32)

                matchCard(
                    item: topMatch,
                    label: "We predict you love this",
                    icon: "heart.fill",
                    color: Theme.accent
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 14)

                matchCard(
                    item: bottomMatch,
                    label: "We predict you hate this",
                    icon: "xmark.circle.fill",
                    color: Theme.muted
                )
                .padding(.horizontal, 20)

                continueButton
                    .padding(.horizontal, 20)
                    .padding(.top, 32)
                    .padding(.bottom, 52)
            }
        }
        .background(Theme.bg.ignoresSafeArea())
        .onAppear { Haptics.success() }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 10) {
            Text("THE ORACLE")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.accent)
                .tracking(2.4)

            Text("After 15 swipes,\nthe math has spoken.")
                .font(.title2.weight(.semibold))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Match Card

    private func matchCard(item: OracleItem, label: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Label banner
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption.weight(.semibold))
                Text(label.uppercased())
                    .font(.caption2.weight(.semibold))
                    .tracking(0.8)
            }
            .foregroundStyle(color)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

            // Image
            CachedImage(url: item.image_url, height: 240)
                .frame(maxWidth: .infinity)

            // Info
            VStack(alignment: .leading, spacing: 6) {
                Text(item.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(2)

                HStack {
                    if let category = item.category {
                        Text(category.uppercased())
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(Theme.muted)
                            .tracking(0.8)
                    }
                    Spacer()
                    Text(item.similarity.map { String(format: "%.0f%% match", max(0, $0 * 100)) } ?? "")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(color)
                }
            }
            .padding(14)
        }
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.radius, style: .continuous)
                .stroke(Theme.hairline, lineWidth: 1)
        )
    }

    // MARK: - Continue

    private var continueButton: some View {
        Button {
            Haptics.tap()
            onContinue()
        } label: {
            Text("Continue")
                .font(.callout.weight(.semibold))
                .foregroundStyle(Theme.bg)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Theme.ink)
                .clipShape(RoundedRectangle(cornerRadius: Theme.radius, style: .continuous))
        }
    }
}
