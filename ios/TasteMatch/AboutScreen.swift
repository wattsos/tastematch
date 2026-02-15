import SwiftUI

struct AboutScreen: View {

    var body: some View {
        List {
            // Hero
            Section {
                VStack(spacing: 12) {
                    Text(Brand.name)
                        .font(Theme.displayFont)
                        .foregroundStyle(Theme.ink)
                        .tracking(3)
                    Text(Brand.tagline)
                        .font(.system(.subheadline, design: .serif))
                        .foregroundStyle(Theme.muted)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .listRowBackground(Color.clear)
            }

            // Story
            Section("Our Story") {
                Text("\(Brand.name) was born from a simple idea: your space already knows your style. We built an engine that reads the visual DNA of your room — color temperature, texture, contrast — and translates it into a taste profile you can act on.")
                    .font(.body)
                    .foregroundStyle(Theme.ink)
                    .lineSpacing(4)
            }

            // How it works
            Section("How It Works") {
                step(number: "1", title: "Upload", description: "Snap a photo of any room or space you love.")
                step(number: "2", title: "Analyze", description: "Our engine extracts visual signals — palette, brightness, texture, materials.")
                step(number: "3", title: "Discover", description: "Get a taste profile, curated selections, and design tips tailored to you.")
            }

            // The 10 styles
            Section("10 Canonical Styles") {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(Array(TasteBadge.badgeMap.sorted(by: { $0.key < $1.key })), id: \.key) { key, _ in
                        TasteBadge(tagKey: key, size: .compact)
                    }
                }
                .padding(.vertical, 8)
            }

            // Version info
            Section("App Info") {
                infoRow(label: "Version", value: appVersion)
                infoRow(label: "Build", value: buildNumber)
                infoRow(label: "Engine", value: "Deterministic v1")
                infoRow(label: "Catalog", value: "\(catalogCount) pieces")
            }

            // Links
            Section {
                HStack {
                    Spacer()
                    VStack(spacing: 4) {
                        Text(Brand.domain)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Theme.accent)
                        Text("Made with care")
                            .font(.caption2)
                            .foregroundStyle(Theme.muted)
                    }
                    Spacer()
                }
                .padding(.vertical, 8)
                .listRowBackground(Color.clear)
            }
        }
        .navigationTitle("About")
        .tint(Theme.accent)
    }

    // MARK: - Subviews

    private func step(number: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.system(.title2, design: .serif, weight: .bold))
                .foregroundStyle(Theme.accent)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.ink)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(Theme.muted)
                    .lineSpacing(2)
            }
        }
        .padding(.vertical, 4)
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(Theme.ink)
            Spacer()
            Text(value)
                .foregroundStyle(Theme.muted)
        }
    }

    // MARK: - Data

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    private var catalogCount: Int {
        TasteDomain.allCases.reduce(0) { $0 + DomainCatalog.items(for: $1).count }
    }
}
