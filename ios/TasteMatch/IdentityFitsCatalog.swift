import Foundation

enum IdentityFitsCatalog {
    static let all: [String] = (1...53).map { String(format: "fit_%03d", $0) }
}
