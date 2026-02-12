import SwiftUI
import UIKit

// MARK: - ItMe Design System

enum Theme {

    // MARK: - Adaptive Palette

    /// Warm terracotta — primary accent for buttons, links, active states
    static let accent = Color(light: .init(red: 0.82, green: 0.45, blue: 0.33),
                              dark: .init(red: 0.90, green: 0.52, blue: 0.40))

    /// Soft blush — secondary accent for highlights, badges, subtle emphasis
    static let blush = Color(light: .init(red: 0.93, green: 0.78, blue: 0.72),
                             dark: .init(red: 0.45, green: 0.35, blue: 0.32))

    /// Warm cream — card backgrounds, section fills (dark: charcoal)
    static let cream = Color(light: .init(red: 0.98, green: 0.96, blue: 0.93),
                             dark: .init(red: 0.14, green: 0.13, blue: 0.12))

    /// Deep espresso — primary text (dark: warm white)
    static let espresso = Color(light: .init(red: 0.18, green: 0.14, blue: 0.12),
                                dark: .init(red: 0.95, green: 0.93, blue: 0.90))

    /// Soft clay — secondary text, captions
    static let clay = Color(light: .init(red: 0.55, green: 0.48, blue: 0.44),
                            dark: .init(red: 0.65, green: 0.60, blue: 0.56))

    /// Sage green — success, strong match
    static let sage = Color(light: .init(red: 0.55, green: 0.71, blue: 0.56),
                            dark: .init(red: 0.60, green: 0.78, blue: 0.62))

    /// Warm amber — good match, mid-confidence
    static let amber = Color(light: .init(red: 0.87, green: 0.68, blue: 0.35),
                             dark: .init(red: 0.92, green: 0.75, blue: 0.42))

    /// Muted rose — partial match, low-confidence
    static let rose = Color(light: .init(red: 0.76, green: 0.52, blue: 0.52),
                            dark: .init(red: 0.82, green: 0.58, blue: 0.58))

    // MARK: - Semantic Colors

    static let strongMatch = sage
    static let goodMatch = amber
    static let partialMatch = rose

    static let favorite = Color(light: .init(red: 0.84, green: 0.32, blue: 0.37),
                                dark: .init(red: 0.90, green: 0.38, blue: 0.42))

    /// Surface for cards on top of the system background
    static let surface = Color(light: .init(red: 1.0, green: 0.99, blue: 0.97),
                               dark: .init(red: 0.18, green: 0.17, blue: 0.16))

    // MARK: - Typography Helpers

    static let displayFont: Font = .system(.largeTitle, design: .serif, weight: .bold)
    static let headlineFont: Font = .system(.title3, design: .serif, weight: .semibold)
    static let bodyFont: Font = .system(.body, design: .default)
    static let captionFont: Font = .system(.caption, design: .default)
}

// MARK: - Adaptive Color Initializer

extension Color {
    init(light: UIColor, dark: UIColor) {
        self.init(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        })
    }
}

// MARK: - View Modifiers

extension View {
    func itmeCardStyle() -> some View {
        self
            .padding()
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
