import SwiftUI

// MARK: - Routing

enum Route: Hashable {
    case context([UIImage], RoomContext, DesignGoal, TasteDomain)
    case calibration(TasteProfile, [RecommendationItem], TasteDomain)
    case result(TasteProfile, [RecommendationItem], TasteDomain)
    case compare
    case recommendationDetail(RecommendationItem, tasteProfileId: UUID, domain: TasteDomain = .space)
    case reanalyze(RoomContext, DesignGoal)
    case evolution
    case about
    case board([RecommendationItem])
    case discoveryDetail(DiscoveryItem)
    case profile(UUID)
    case shop(TasteProfile, TasteDomain)
    case newScan(TasteDomain? = nil)
    case identityReveal
    case itemEvaluation(evaluation: TasteEvaluatedObject, candidateVector: TasteVector)

    func hash(into hasher: inout Hasher) {
        switch self {
        case .context:
            hasher.combine("context")
        case .calibration(let profile, _, _):
            hasher.combine("calibration")
            hasher.combine(profile.id)
        case .result(let profile, _, _):
            hasher.combine("result")
            hasher.combine(profile.id)
        case .compare:
            hasher.combine("compare")
        case .recommendationDetail(let item, _, _):
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
        case .profile(let id):
            hasher.combine("profile")
            hasher.combine(id)
        case .shop(let profile, _):
            hasher.combine("shop")
            hasher.combine(profile.id)
        case .newScan:
            hasher.combine("newScan")
        case .identityReveal:
            hasher.combine("identityReveal")
        case .itemEvaluation(let eval, _):
            hasher.combine("itemEvaluation")
            hasher.combine(eval.id)
        }
    }

    static func == (lhs: Route, rhs: Route) -> Bool {
        switch (lhs, rhs) {
        case (.context(let a, _, _, _), .context(let b, _, _, _)):
            return a.count == b.count
        case (.calibration(let p1, _, _), .calibration(let p2, _, _)):
            return p1.id == p2.id
        case (.result(let p1, _, _), .result(let p2, _, _)):
            return p1.id == p2.id
        case (.compare, .compare):
            return true
        case (.recommendationDetail(let a, _, _), .recommendationDetail(let b, _, _)):
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
        case (.profile(let id1), .profile(let id2)):
            return id1 == id2
        case (.shop(let p1, _), .shop(let p2, _)):
            return p1.id == p2.id
        case (.newScan, .newScan):
            return true  // Ignore domain for nav stack dedup
        case (.identityReveal, .identityReveal):
            return true
        case (.itemEvaluation(let e1, _), .itemEvaluation(let e2, _)):
            return e1.id == e2.id
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
    @StateObject private var advisorySettings = AdvisorySettings()

    private enum OnboardingPhase {
        case goalSelection, carousel, done
    }

    @State private var onboardingPhase: OnboardingPhase
    @State private var showOnboarding: Bool

    init() {
        let domainDone = DomainPreferencesStore.isOnboardingComplete
        let carouselDone = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        if !domainDone {
            _onboardingPhase = State(initialValue: .goalSelection)
            _showOnboarding = State(initialValue: true)
        } else if !carouselDone {
            _onboardingPhase = State(initialValue: .carousel)
            _showOnboarding = State(initialValue: true)
        } else {
            _onboardingPhase = State(initialValue: .done)
            _showOnboarding = State(initialValue: false)
        }
    }

    var body: some Scene {
        WindowGroup {
            EngineRootView()
                .environmentObject(advisorySettings)
        }
    }

    @ViewBuilder
    private var onboardingFlow: some View {
        switch onboardingPhase {
        case .goalSelection:
            GoalSelectionScreen(isPresented: $showOnboarding) {
                DomainPreferencesStore.markOnboardingComplete()
                onboardingPhase = .carousel
            }
        case .carousel:
            OnboardingScreen(hasCompletedOnboarding: Binding(
                get: { hasCompletedOnboarding },
                set: { newValue in
                    hasCompletedOnboarding = newValue
                    if newValue {
                        onboardingPhase = .done
                        showOnboarding = false
                    }
                }
            ))
        case .done:
            EmptyView()
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
                HomeRootView(path: $homePath)
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
        case .context(let images, let room, let goal, let domain):
            ContextScreen(path: path, images: images, initialRoom: room, initialGoal: goal, domain: domain)
        case .calibration(let profile, let recs, let domain):
            switch domain {
            case .objects:
                ObjectsCalibrationScreen(path: path, profile: profile, recommendations: recs)
            case .space, .art:
                TasteCalibrationScreen(path: path, profile: profile, recommendations: recs, domain: domain)
            }
        case .result(let profile, let recs, let domain):
            ResultScreen(path: path, profile: profile, recommendations: recs, domain: domain)
        case .compare:
            CompareScreen(path: path)
        case .recommendationDetail(let item, let profileId, let domain):
            RecommendationDetailScreen(item: item, tasteProfileId: profileId, domain: domain)
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
        case .profile(let profileId):
            MyProfileScreen(profileId: profileId, path: path)
        case .shop(let profile, let domain):
            ShopScreen(path: path, profile: profile, domain: domain)
        case .newScan(let domain):
            UploadScreen(path: path, domain: domain ?? DomainPreferencesStore.primaryDomain)
        case .identityReveal:
            IdentityRevealView(path: path)
        case .itemEvaluation(let evaluation, let candidateVector):
            ItemEvaluationScreen(path: path, evaluation: evaluation, candidateVector: candidateVector)
        }
    }
}

// MARK: - Home Root

struct HomeRootView: View {
    @Binding var path: NavigationPath
    @State private var latestProfileId: UUID?

    var body: some View {
        Group {
            if let profileId = latestProfileId {
                MyProfileScreen(profileId: profileId, path: $path)
            } else {
                UploadScreen(path: $path)
            }
        }
        .onAppear {
            latestProfileId = ProfileStore.loadLatest()?.id
        }
    }
}
