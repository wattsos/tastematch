import SwiftUI

// MARK: - Routing

enum Route: Hashable {
    case context([UIImage], RoomContext, DesignGoal)
    case calibration(TasteProfile, [RecommendationItem])
    case result(TasteProfile, [RecommendationItem])
    case compare
    case recommendationDetail(RecommendationItem, tasteProfileId: UUID)
    case reanalyze(RoomContext, DesignGoal)
    case evolution
    case about
    case board([RecommendationItem])
    case discoveryDetail(DiscoveryItem)

    func hash(into hasher: inout Hasher) {
        switch self {
        case .context:
            hasher.combine("context")
        case .calibration(let profile, _):
            hasher.combine("calibration")
            hasher.combine(profile.id)
        case .result(let profile, _):
            hasher.combine("result")
            hasher.combine(profile.id)
        case .compare:
            hasher.combine("compare")
        case .recommendationDetail(let item, _):
            hasher.combine("recommendationDetail")
            hasher.combine(item.id)
        case .reanalyze(let room, let goal):
            hasher.combine("reanalyze")
            hasher.combine(room.rawValue)
            hasher.combine(goal.rawValue)
        case .evolution:
            hasher.combine("evolution")
        case .about:
            hasher.combine("about")
        case .board:
            hasher.combine("board")
        case .discoveryDetail(let item):
            hasher.combine("discoveryDetail")
            hasher.combine(item.id)
        }
    }

    static func == (lhs: Route, rhs: Route) -> Bool {
        switch (lhs, rhs) {
        case (.context(let a, _, _), .context(let b, _, _)):
            return a.count == b.count
        case (.calibration(let p1, _), .calibration(let p2, _)):
            return p1.id == p2.id
        case (.result(let p1, _), .result(let p2, _)):
            return p1.id == p2.id
        case (.compare, .compare):
            return true
        case (.recommendationDetail(let a, _), .recommendationDetail(let b, _)):
            return a.id == b.id
        case (.reanalyze(let r1, let g1), .reanalyze(let r2, let g2)):
            return r1 == r2 && g1 == g2
        case (.evolution, .evolution):
            return true
        case (.about, .about):
            return true
        case (.board, .board):
            return true
        case (.discoveryDetail(let a), .discoveryDetail(let b)):
            return a.id == b.id
        default:
            return false
        }
    }
}

// MARK: - Tab

enum AppTab: String, CaseIterable {
    case home = "Home"
    case saved = "Saved"
    case history = "History"
    case settings = "Settings"

    var icon: String {
        switch self {
        case .home: return "camera.viewfinder"
        case .saved: return "bookmark"
        case .history: return "clock.arrow.circlepath"
        case .settings: return "gearshape"
        }
    }
}

// MARK: - App entry point

@main
struct TasteMatchApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .fullScreenCover(isPresented: Binding(
                    get: { !hasCompletedOnboarding },
                    set: { if $0 { hasCompletedOnboarding = false } }
                )) {
                    OnboardingScreen(hasCompletedOnboarding: $hasCompletedOnboarding)
                }
        }
    }
}

// MARK: - Main Tab View

struct MainTabView: View {
    @State private var selectedTab: AppTab = .home
    @State private var homePath = NavigationPath()
    @State private var savedPath = NavigationPath()
    @State private var historyPath = NavigationPath()
    @State private var settingsPath = NavigationPath()

    var body: some View {
        TabView(selection: $selectedTab) {
            // Home tab
            NavigationStack(path: $homePath) {
                UploadScreen(path: $homePath)
                    .navigationDestination(for: Route.self) { route in
                        destinationView(for: route, path: $homePath)
                    }
            }
            .tabItem {
                Label(AppTab.home.rawValue, systemImage: AppTab.home.icon)
            }
            .tag(AppTab.home)

            // Saved tab
            NavigationStack(path: $savedPath) {
                FavoritesScreen()
                    .navigationDestination(for: Route.self) { route in
                        destinationView(for: route, path: $savedPath)
                    }
            }
            .tabItem {
                Label(AppTab.saved.rawValue, systemImage: AppTab.saved.icon)
            }
            .tag(AppTab.saved)

            // History tab
            NavigationStack(path: $historyPath) {
                HistoryScreen(path: $historyPath)
                    .navigationDestination(for: Route.self) { route in
                        destinationView(for: route, path: $historyPath)
                    }
            }
            .tabItem {
                Label(AppTab.history.rawValue, systemImage: AppTab.history.icon)
            }
            .tag(AppTab.history)

            // Settings tab
            NavigationStack(path: $settingsPath) {
                SettingsScreen(path: $settingsPath)
                    .navigationDestination(for: Route.self) { route in
                        destinationView(for: route, path: $settingsPath)
                    }
            }
            .tabItem {
                Label(AppTab.settings.rawValue, systemImage: AppTab.settings.icon)
            }
            .tag(AppTab.settings)
        }
        .tint(Theme.accent)
    }

    @ViewBuilder
    private func destinationView(for route: Route, path: Binding<NavigationPath>) -> some View {
        switch route {
        case .context(let images, let room, let goal):
            ContextScreen(path: path, images: images, initialRoom: room, initialGoal: goal)
        case .calibration(let profile, let recs):
            TasteCalibrationScreen(path: path, profile: profile, recommendations: recs)
        case .result(let profile, let recs):
            ResultScreen(path: path, profile: profile, recommendations: recs)
        case .compare:
            CompareScreen(path: path)
        case .recommendationDetail(let item, let profileId):
            RecommendationDetailScreen(item: item, tasteProfileId: profileId)
        case .reanalyze(let room, let goal):
            UploadScreen(path: path, prefillRoom: room, prefillGoal: goal)
        case .evolution:
            EvolutionScreen()
        case .about:
            AboutScreen()
        case .board(let items):
            BoardScreen(path: path, items: items)
        case .discoveryDetail(let item):
            DiscoveryDetailScreen(item: item)
        }
    }
}
