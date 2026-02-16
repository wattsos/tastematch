import SwiftUI

struct EngineRootView: View {
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            UploadScreen(path: $path)
                .navigationDestination(for: Route.self) { route in
                    EngineDestinationView(route: route, path: $path)
                }
        }
    }
}

private struct EngineDestinationView: View {
    let route: Route
    @Binding var path: NavigationPath

    var body: some View {
        switch route {
        case .context(let images, let room, let goal, let domain):
            ContextScreen(path: $path, images: images, initialRoom: room, initialGoal: goal, domain: domain)

        case .calibration(let profile, let recs, let domain):
            switch domain {
            case .objects:
                ObjectsCalibrationScreen(path: $path, profile: profile, recommendations: recs)
            case .space, .art:
                TasteCalibrationScreen(path: $path, profile: profile, recommendations: recs, domain: domain)
            }

        case .result(let profile, let recs, let domain):
            ResultScreen(path: $path, profile: profile, recommendations: recs, domain: domain)

        case .recommendationDetail(let item, let profileId, let domain):
            RecommendationDetailScreen(item: item, tasteProfileId: profileId, domain: domain)

        case .reanalyze(let room, let goal):
            UploadScreen(path: $path, prefillRoom: room, prefillGoal: goal)

        case .newScan(let domain):
            UploadScreen(path: $path, domain: domain ?? DomainPreferencesStore.primaryDomain)

        default:
            EmptyView()
        }
    }
}
