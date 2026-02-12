import SwiftUI

// MARK: - Routing

enum Route: Hashable {
    case upload
    case context([UIImage])
    case result(TasteProfile, [RecommendationItem])
    case history
    case settings
    case favorites

    // Hashable conformance (identity-based for payloads)
    func hash(into hasher: inout Hasher) {
        switch self {
        case .upload:
            hasher.combine("upload")
        case .context:
            hasher.combine("context")
        case .result(let profile, _):
            hasher.combine("result")
            hasher.combine(profile.id)
        case .history:
            hasher.combine("history")
        case .settings:
            hasher.combine("settings")
        case .favorites:
            hasher.combine("favorites")
        }
    }

    static func == (lhs: Route, rhs: Route) -> Bool {
        switch (lhs, rhs) {
        case (.upload, .upload):
            return true
        case (.context(let a), .context(let b)):
            return a.count == b.count
        case (.result(let p1, _), .result(let p2, _)):
            return p1.id == p2.id
        case (.history, .history):
            return true
        case (.settings, .settings):
            return true
        case (.favorites, .favorites):
            return true
        default:
            return false
        }
    }
}

// MARK: - App entry point

@main
struct TasteMatchApp: App {
    @State private var path = NavigationPath()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $path) {
                UploadScreen(path: $path)
                    .navigationDestination(for: Route.self) { route in
                        switch route {
                        case .upload:
                            UploadScreen(path: $path)
                        case .context(let images):
                            ContextScreen(path: $path, images: images)
                        case .result(let profile, let recs):
                            ResultScreen(path: $path, profile: profile, recommendations: recs)
                        case .history:
                            HistoryScreen(path: $path)
                        case .settings:
                            SettingsScreen(path: $path)
                        case .favorites:
                            FavoritesScreen()
                        }
                    }
                    .onAppear {
                        if let saved = ProfileStore.loadLatest() {
                            path.append(Route.result(saved.tasteProfile, saved.recommendations))
                        }
                    }
            }
            .fullScreenCover(isPresented: Binding(
                get: { !hasCompletedOnboarding },
                set: { if $0 { hasCompletedOnboarding = false } }
            )) {
                OnboardingScreen(hasCompletedOnboarding: $hasCompletedOnboarding)
            }
        }
    }
}
