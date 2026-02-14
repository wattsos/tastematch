import SwiftUI

// MARK: - Taste Badge

struct TasteBadge: View {
    let tagKey: String
    let size: BadgeSize

    enum BadgeSize {
        case compact   // Inline in lists
        case featured  // Hero display on results
    }

    private var info: BadgeInfo {
        Self.badgeMap[tagKey] ?? BadgeInfo(title: "Style Explorer", icon: "sparkles", color: Theme.accent)
    }

    var body: some View {
        switch size {
        case .compact:
            compactBadge
        case .featured:
            featuredBadge
        }
    }

    private var compactBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: info.icon)
                .font(.caption)
            Text(info.title)
                .font(.caption.weight(.semibold))
        }
        .foregroundStyle(info.color)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(info.color.opacity(0.12))
        .clipShape(Capsule())
    }

    private var featuredBadge: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(info.color.opacity(0.12))
                    .frame(width: 56, height: 56)
                Image(systemName: info.icon)
                    .font(.title2)
                    .foregroundStyle(info.color)
            }
            Text(info.title)
                .font(.system(.subheadline, design: .serif, weight: .semibold))
                .foregroundStyle(Theme.espresso)
        }
    }
}

// MARK: - Badge Data

struct BadgeInfo {
    let title: String
    let icon: String
    let color: Color
}

extension TasteBadge {
    static let badgeMap: [String: BadgeInfo] = [
        "midCenturyModern": BadgeInfo(
            title: "Retro Visionary",
            icon: "chair.lounge",
            color: Theme.amber
        ),
        "scandinavian": BadgeInfo(
            title: "Nordic Soul",
            icon: "snowflake",
            color: Color(red: 0.55, green: 0.72, blue: 0.80)
        ),
        "industrial": BadgeInfo(
            title: "Industrial Edge",
            icon: "hammer",
            color: Color(red: 0.50, green: 0.50, blue: 0.50)
        ),
        "bohemian": BadgeInfo(
            title: "Boho Spirit",
            icon: "leaf",
            color: Color(red: 0.75, green: 0.58, blue: 0.40)
        ),
        "minimalist": BadgeInfo(
            title: "Less Is More",
            icon: "circle.dotted",
            color: Color(red: 0.45, green: 0.45, blue: 0.45)
        ),
        "traditional": BadgeInfo(
            title: "Classic Heart",
            icon: "crown",
            color: Color(red: 0.60, green: 0.45, blue: 0.30)
        ),
        "coastal": BadgeInfo(
            title: "Coastal Dreamer",
            icon: "water.waves",
            color: Color(red: 0.40, green: 0.65, blue: 0.75)
        ),
        "rustic": BadgeInfo(
            title: "Rustic Roots",
            icon: "tree",
            color: Color(red: 0.55, green: 0.45, blue: 0.35)
        ),
        "artDeco": BadgeInfo(
            title: "Deco Maximalist",
            icon: "diamond",
            color: Color(red: 0.75, green: 0.60, blue: 0.30)
        ),
        "japandi": BadgeInfo(
            title: "Zen Minimalist",
            icon: "moon",
            color: Color(red: 0.55, green: 0.60, blue: 0.50)
        ),
    ]
}
