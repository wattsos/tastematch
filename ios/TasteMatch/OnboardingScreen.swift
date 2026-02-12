import SwiftUI

struct OnboardingScreen: View {
    @Binding var hasCompletedOnboarding: Bool

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "sparkles.rectangle.stack")
                .font(.system(size: 64))
                .foregroundStyle(.accent)

            VStack(spacing: 12) {
                Text("Welcome to TasteMatch")
                    .font(.largeTitle.weight(.bold))
                    .multilineTextAlignment(.center)

                Text("Snap a few photos of your room and we'll decode your design taste — then recommend pieces that actually fit your style.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            VStack(alignment: .leading, spacing: 16) {
                featureRow(icon: "camera.fill", title: "Upload Photos", description: "Share up to 5 photos of your space")
                featureRow(icon: "wand.and.stars", title: "Get Your Profile", description: "We analyze color, texture, and style")
                featureRow(icon: "tag.fill", title: "See Recommendations", description: "Products matched to your taste")
            }
            .padding(.horizontal, 32)

            Spacer()

            Button {
                hasCompletedOnboarding = true
            } label: {
                Text("Get Started")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
    }

    private func featureRow(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.accent)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
