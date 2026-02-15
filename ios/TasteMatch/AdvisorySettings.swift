import Foundation
import Combine

// MARK: - Advisory Settings Store

final class AdvisorySettings: ObservableObject {
    static let shared = AdvisorySettings()

    private static let key = "burgundy.advisoryLevel"

    @Published var level: AdvisoryLevel {
        didSet {
            UserDefaults.standard.set(level.rawValue, forKey: Self.key)
        }
    }

    init() {
        if let raw = UserDefaults.standard.string(forKey: Self.key),
           let stored = AdvisoryLevel(rawValue: raw) {
            self.level = stored
        } else {
            self.level = .standard
        }
    }
}
