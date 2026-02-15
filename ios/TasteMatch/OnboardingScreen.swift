import SwiftUI

struct OnboardingScreen: View {
    @Binding var hasCompletedOnboarding: Bool
    @State private var currentPage = 0

    private var pages: [OnboardingPage] {
        let primary = DomainPreferencesStore.primaryDomain
        switch primary {
        case .objects:
            return [
                OnboardingPage(
                    icon: "camera.viewfinder",
                    headline: "Your objects\ntell a story",
                    body: "Upload watches, bags, accessories — we'll read the details and intent behind what you carry."
                ),
                OnboardingPage(
                    icon: "wand.and.stars",
                    headline: "We decode\nyour taste",
                    body: "Our engine picks up on visual signals most people can't name — then maps them to an object profile unique to you."
                ),
                OnboardingPage(
                    icon: "tag.fill",
                    headline: "Find pieces\nthat feel like you",
                    body: "Get recommendations that actually match your vibe. No generic \"trending\" lists — just things that belong in your world."
                ),
            ]
        case .art:
            return [
                OnboardingPage(
                    icon: "camera.viewfinder",
                    headline: "Your walls\ntell a story",
                    body: "Upload art you love — we'll read the movements, palettes, and tension that define your eye."
                ),
                OnboardingPage(
                    icon: "wand.and.stars",
                    headline: "We decode\nyour taste",
                    body: "Our engine picks up on visual signals most people can't name — then maps them to a collection profile unique to you."
                ),
                OnboardingPage(
                    icon: "tag.fill",
                    headline: "Find pieces\nthat feel like you",
                    body: "Get recommendations that actually match your vibe. No generic \"trending\" lists — just things that belong in your world."
                ),
            ]
        case .space:
            return [
                OnboardingPage(
                    icon: "camera.viewfinder",
                    headline: "Your space\ntells a story",
                    body: "Upload a few photos of any room — we'll read the colors, textures, and layout that make it yours."
                ),
                OnboardingPage(
                    icon: "wand.and.stars",
                    headline: "We decode\nyour taste",
                    body: "Our engine picks up on visual signals most people can't name — then maps them to a style profile unique to you."
                ),
                OnboardingPage(
                    icon: "tag.fill",
                    headline: "Find pieces\nthat feel like you",
                    body: "Get recommendations that actually match your vibe. No generic \"trending\" lists — just things that belong in your world."
                ),
            ]
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Logo
            Text(Brand.name)
                .font(Theme.displayFont)
                .foregroundStyle(Theme.ink)
                .padding(.top, 56)

            Text(Brand.tagline)
                .font(.system(.subheadline, design: .serif))
                .foregroundStyle(Theme.muted)
                .padding(.top, 4)

            // Pages
            TabView(selection: $currentPage) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                    pageView(page)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.3), value: currentPage)

            // Page dots
            HStack(spacing: 10) {
                ForEach(0..<pages.count, id: \.self) { index in
                    Circle()
                        .fill(index == currentPage ? Theme.accent : Theme.blush)
                        .frame(width: index == currentPage ? 10 : 7, height: index == currentPage ? 10 : 7)
                        .animation(.easeInOut(duration: 0.2), value: currentPage)
                }
            }
            .padding(.bottom, 32)

            // Button
            Button {
                if currentPage < pages.count - 1 {
                    withAnimation { currentPage += 1 }
                } else {
                    hasCompletedOnboarding = true
                }
            } label: {
                Text(currentPage < pages.count - 1 ? "Next" : "Get Started")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Theme.accent)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.radius))
            }
            .padding(.horizontal, 24)

            if currentPage < pages.count - 1 {
                Button {
                    hasCompletedOnboarding = true
                } label: {
                    Text("Skip")
                        .font(.subheadline)
                        .foregroundStyle(Theme.clay)
                }
                .padding(.top, 12)
                .padding(.bottom, 16)
            } else {
                Spacer().frame(height: 44)
            }
        }
        .background(Theme.cream.ignoresSafeArea())
    }

    private func pageView(_ page: OnboardingPage) -> some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Theme.blush.opacity(0.3))
                    .frame(width: 120, height: 120)
                Image(systemName: page.icon)
                    .font(.system(size: 44))
                    .foregroundStyle(Theme.accent)
            }

            Text(page.headline)
                .font(.system(.title2, design: .serif, weight: .bold))
                .foregroundStyle(Theme.espresso)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            Text(page.body)
                .font(.subheadline)
                .foregroundStyle(Theme.clay)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.horizontal, 36)

            Spacer()
        }
    }
}

private struct OnboardingPage {
    let icon: String
    let headline: String
    let body: String
}
