import SwiftUI

struct OnboardingScreen: View {
    @Binding var hasCompletedOnboarding: Bool

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "sparkles.rectangle.stack")
                .font(.system(size: 64))
                .foregroundStyle(Theme.accent)

            VStack(spacing: 12) {
                Text("ItMe")
                    .font(Theme.displayFont)
                    .foregroundStyle(Theme.espresso)

                Text("Your space says something about you.\nLet's find out what.")
                    .font(.body)
                    .foregroundStyle(Theme.clay)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            VStack(alignment: .leading, spacing: 16) {
                featureRow(icon: "camera.fill", title: "Upload Photos", description: "Share up to 5 photos of your space")
                featureRow(icon: "wand.and.stars", title: "Get Your Profile", description: "We read color, texture, and vibe")
                featureRow(icon: "tag.fill", title: "See Picks", description: "Pieces that actually feel like you")
            }
            .padding(.horizontal, 32)

            Spacer()

            Button {
                hasCompletedOnboarding = true
            } label: {
                Text("Get Started")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Theme.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
        .background(Theme.cream.ignoresSafeArea())
    }

    private func featureRow(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Theme.accent)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.espresso)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(Theme.clay)
            }
        }
    }
}
