import SwiftUI

// MARK: - Routing

enum Route: Hashable {
    case upload
    case context([UIImage], RoomContext, DesignGoal)
    case result(TasteProfile, [RecommendationItem])
    case history
    case settings
    case favorites
    case compare
    case recommendationDetail(RecommendationItem)
    case reanalyze(RoomContext, DesignGoal)

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
        case .compare:
            hasher.combine("compare")
        case .recommendationDetail(let item):
            hasher.combine("recommendationDetail")
            hasher.combine(item.id)
        case .reanalyze(let room, let goal):
            hasher.combine("reanalyze")
            hasher.combine(room.rawValue)
            hasher.combine(goal.rawValue)
        }
    }

    static func == (lhs: Route, rhs: Route) -> Bool {
        switch (lhs, rhs) {
        case (.upload, .upload):
            return true
        case (.context(let a, _, _), .context(let b, _, _)):
            return a.count == b.count
        case (.result(let p1, _), .result(let p2, _)):
            return p1.id == p2.id
        case (.history, .history):
            return true
        case (.settings, .settings):
            return true
        case (.favorites, .favorites):
            return true
        case (.compare, .compare):
            return true
        case (.recommendationDetail(let a), .recommendationDetail(let b)):
            return a.id == b.id
        case (.reanalyze(let r1, let g1), .reanalyze(let r2, let g2)):
            return r1 == r2 && g1 == g2
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
                        case .context(let images, let room, let goal):
                            ContextScreen(path: $path, images: images, initialRoom: room, initialGoal: goal)
                        case .result(let profile, let recs):
                            ResultScreen(path: $path, profile: profile, recommendations: recs)
                        case .history:
                            HistoryScreen(path: $path)
                        case .settings:
                            SettingsScreen(path: $path)
                        case .favorites:
                            FavoritesScreen()
                        case .compare:
                            CompareScreen(path: $path)
                        case .recommendationDetail(let item):
                            RecommendationDetailScreen(item: item)
                        case .reanalyze(let room, let goal):
                            UploadScreen(path: $path, prefillRoom: room, prefillGoal: goal)
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
