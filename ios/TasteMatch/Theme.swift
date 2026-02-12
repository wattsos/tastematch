import SwiftUI

// MARK: - ItMe Design System

enum Theme {

    // MARK: - Palette

    /// Warm terracotta — primary accent for buttons, links, active states
    static let accent = Color(red: 0.82, green: 0.45, blue: 0.33)

    /// Soft blush — secondary accent for highlights, badges, subtle emphasis
    static let blush = Color(red: 0.93, green: 0.78, blue: 0.72)

    /// Warm cream — card backgrounds, section fills
    static let cream = Color(red: 0.98, green: 0.96, blue: 0.93)

    /// Deep espresso — primary text on light backgrounds
    static let espresso = Color(red: 0.18, green: 0.14, blue: 0.12)

    /// Soft clay — secondary text, captions
    static let clay = Color(red: 0.55, green: 0.48, blue: 0.44)

    /// Sage green — success, strong match
    static let sage = Color(red: 0.55, green: 0.71, blue: 0.56)

    /// Warm amber — good match, mid-confidence
    static let amber = Color(red: 0.87, green: 0.68, blue: 0.35)

    /// Muted rose — partial match, low-confidence
    static let rose = Color(red: 0.76, green: 0.52, blue: 0.52)

    // MARK: - Semantic Colors

    static let strongMatch = sage
    static let goodMatch = amber
    static let partialMatch = rose

    static let favorite = Color(red: 0.84, green: 0.32, blue: 0.37)

    // MARK: - Typography Helpers

    static let displayFont: Font = .system(.largeTitle, design: .serif, weight: .bold)
    static let headlineFont: Font = .system(.title3, design: .serif, weight: .semibold)
    static let bodyFont: Font = .system(.body, design: .default)
    static let captionFont: Font = .system(.caption, design: .default)
}

// MARK: - View Modifiers

extension View {
    func itmeCardStyle() -> some View {
        self
            .padding()
            .background(Theme.cream)
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
