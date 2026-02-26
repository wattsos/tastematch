import SwiftUI

struct EngineRootView: View {
    @State private var path = NavigationPath()

    private var hasIdentity: Bool {
        ProfileStore.loadLatest() != nil
    }

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if hasIdentity {
                    IdentityHomeView(path: $path)
                } else {
                    SwipeOnboardingView(path: $path)
                }
            }
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .identityReveal:
                    IdentityRevealView(path: $path)
                case .itemEvaluation(let evaluation):
                    ItemEvaluationScreen(path: $path, evaluation: evaluation)
                default:
                    EmptyView()
                }
            }
        }
    }
}
