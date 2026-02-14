import Foundation

enum BackendMode: String {
    case local
    case remote
}

enum FeatureFlags {
    static var backendMode: BackendMode = .local
}
