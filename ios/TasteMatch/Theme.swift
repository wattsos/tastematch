import SwiftUI
import UIKit

// MARK: - Cultural Lab Design System

enum Theme {

    // MARK: - Neutral Palette

    /// Off-white page background
    static let bg = Color(light: .init(red: 0.96, green: 0.96, blue: 0.95, alpha: 1),
                          dark: .init(red: 0.10, green: 0.10, blue: 0.10, alpha: 1))

    /// Content surface — pure white
    static let surface = Color(light: .init(red: 1.0, green: 1.0, blue: 1.0, alpha: 1),
                               dark: .init(red: 0.14, green: 0.14, blue: 0.13, alpha: 1))

    /// Primary text — near-black
    static let ink = Color(light: .init(red: 0.06, green: 0.06, blue: 0.06, alpha: 1),
                           dark: .init(red: 0.94, green: 0.94, blue: 0.94, alpha: 1))

    /// Secondary text / captions
    static let muted = Color(light: .init(red: 0.38, green: 0.38, blue: 0.38, alpha: 1),
                             dark: .init(red: 0.62, green: 0.62, blue: 0.62, alpha: 1))

    /// Hairline separators
    static let hairline = Color.black.opacity(0.08)

    /// Radius
    static let radius: CGFloat = 8

    // MARK: - Accent (burgundy)

    /// Primary accent — burgundy
    static let accent = Color(light: .init(red: 0.427, green: 0.122, blue: 0.169, alpha: 1),
                              dark: .init(red: 0.58, green: 0.20, blue: 0.25, alpha: 1))

    /// Pressed / darker accent
    static let accentPressed = Color(light: .init(red: 0.306, green: 0.078, blue: 0.114, alpha: 1),
                                     dark: .init(red: 0.48, green: 0.15, blue: 0.20, alpha: 1))

    // MARK: - Legacy Aliases (keep other files compiling)

    static let offWhite = bg
    static let cream = bg
    static let espresso = ink
    static let clay = muted
    static let blush = hairline

    // MARK: - Match Colors (desaturated)

    /// Cooler sage green — strong match
    static let sage = Color(light: .init(red: 0.50, green: 0.65, blue: 0.50, alpha: 1),
                            dark: .init(red: 0.55, green: 0.72, blue: 0.55, alpha: 1))

    /// Less-warm amber — good match
    static let amber = Color(light: .init(red: 0.75, green: 0.62, blue: 0.35, alpha: 1),
                             dark: .init(red: 0.80, green: 0.68, blue: 0.42, alpha: 1))

    /// Cooler rose — partial match
    static let rose = Color(light: .init(red: 0.65, green: 0.48, blue: 0.48, alpha: 1),
                            dark: .init(red: 0.72, green: 0.54, blue: 0.54, alpha: 1))

    // MARK: - Semantic Colors

    static let strongMatch = sage
    static let goodMatch = amber
    static let partialMatch = rose

    static let favorite = Color(light: .init(red: 0.84, green: 0.32, blue: 0.37, alpha: 1),
                                dark: .init(red: 0.90, green: 0.38, blue: 0.42, alpha: 1))

    // MARK: - Identity Palette

    /// Bone — warm off-white for identity screens
    static let bone = Color(light: .init(red: 0.95, green: 0.93, blue: 0.90, alpha: 1),
                            dark: .init(red: 0.11, green: 0.10, blue: 0.09, alpha: 1))

    /// Deep burgundy — identity accent
    static let burgundy = Color(light: .init(red: 0.36, green: 0.09, blue: 0.12, alpha: 1),
                                dark: .init(red: 0.55, green: 0.18, blue: 0.22, alpha: 1))

    /// Charcoal — identity text
    static let charcoal = Color(light: .init(red: 0.18, green: 0.17, blue: 0.16, alpha: 1),
                                dark: .init(red: 0.88, green: 0.87, blue: 0.86, alpha: 1))

    // MARK: - Typography Helpers

    static let displayFont: Font = .system(size: 48, weight: .bold, design: .serif)
    static let headlineFont: Font = .system(.title3, design: .default, weight: .semibold)
    static let bodyFont: Font = .system(.body, design: .default)
    static let captionFont: Font = .system(.caption, design: .default)
    static let labelFont: Font = .system(.caption, design: .default, weight: .medium)

    /// Serif headline for identity screens
    static let identityHeadline: Font = .system(.title2, design: .serif, weight: .semibold)
    static let identityDisplay: Font = .system(size: 56, weight: .bold, design: .serif)
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

struct LabSurface: ViewModifier {
    var padded: Bool = true
    var bordered: Bool = true

    func body(content: Content) -> some View {
        content
            .padding(padded ? 16 : 0)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.radius, style: .continuous)
                    .stroke(bordered ? Theme.hairline : .clear, lineWidth: 1)
            )
            .shadow(color: .clear, radius: 0) // ensure no shadows
    }
}

extension View {
    func labSurface(padded: Bool = true, bordered: Bool = true) -> some View {
        modifier(LabSurface(padded: padded, bordered: bordered))
    }

    /// Editorial section label: uppercase, tracked, muted
    func sectionLabel() -> some View {
        self
            .font(.caption.weight(.semibold))
            .foregroundStyle(Theme.muted)
            .tracking(1.2)
    }
}

// MARK: - Hairline Divider

struct HairlineDivider: View {
    var body: some View {
        Rectangle()
            .fill(Theme.hairline)
            .frame(height: 1)
    }
}
