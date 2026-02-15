import Foundation

// MARK: - Taste Domain

enum TasteDomain: String, Codable, CaseIterable, Identifiable {
    case space, objects, art

    var id: String { rawValue }

    var displayLabel: String {
        switch self {
        case .space:   return "SPACE"
        case .objects: return "OBJECTS"
        case .art:     return "ART"
        }
    }

    var commerceFilename: String {
        "commerce_\(rawValue)"
    }

    var discoveryFilename: String {
        "discovery_\(rawValue)"
    }
}

// MARK: - Domain Store

enum DomainStore {
    private static let key = "tasteDomain"

    static var current: TasteDomain {
        get {
            guard let raw = UserDefaults.standard.string(forKey: key),
                  let domain = TasteDomain(rawValue: raw) else {
                return .space
            }
            return domain
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: key)
        }
    }
}
