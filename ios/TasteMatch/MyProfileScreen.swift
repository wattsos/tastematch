import SwiftUI

struct MyProfileScreen: View {
    let profileId: UUID
    @Binding var path: NavigationPath

    @State private var saved: SavedProfile?
    @State private var calibrationRecord: CalibrationRecord?
    @State private var vector: TasteVector = .zero
    @State private var axisScores: AxisScores = .zero
    @State private var namingResult: ProfileNamingResult?
    @State private var readingText: String = ""
    @State private var topCommerce: [RecommendationItem] = []
    @State private var topDiscovery: [DiscoveryItem] = []
    @State private var showShareSheet = false

    var body: some View {
        ScrollView {
            if let saved {
                VStack(alignment: .leading, spacing: 32) {
                    identitySection(saved)
                    selectionSection(saved)
                    evolutionSection(saved)
                    radarSection(saved)
                }
                .padding(16)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 120)
            }
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    Haptics.tap()
                    showShareSheet = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.callout)
                        .foregroundStyle(Theme.ink)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("New") {
                    Haptics.tap()
                    path = NavigationPath()
                }
                .foregroundStyle(Theme.ink)
                .font(.callout.weight(.semibold))
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let saved {
                ShareSheet(text: ShareTextBuilder.build(
                    profile: saved.tasteProfile,
                    recommendations: saved.recommendations
                ))
            }
        }
        .onAppear { loadData() }
    }

    // MARK: - Data Loading

    private func loadData() {
        guard let s = ProfileStore.loadAll().first(where: { $0.id == profileId }) else { return }
        saved = s
        let profile = s.tasteProfile

        calibrationRecord = CalibrationStore.load(for: profileId)
        vector = resolveBaseVector(profile: profile)
        axisScores = AxisMapping.computeAxisScores(from: vector)

        let swipeCount = calibrationRecord?.swipeCount ?? 0
        let existingProfile = s.tasteProfile
        let result = ProfileNamingEngine.resolve(
            vector: vector, swipeCount: swipeCount, existingProfile: existingProfile
        )
        namingResult = result
        if result.didUpdate {
            ProfileStore.updateNaming(profileId: profileId, result: result)
        }

        let name = result.name.isEmpty ? profile.displayName : result.name
        readingText = AxisPresentation.oneLineReading(profileName: name, axisScores: axisScores)

        topCommerce = Array(RecommendationEngine.rankWithVector(
            s.recommendations,
            vector: vector,
            catalog: MockCatalog.items,
            context: s.roomContext,
            goal: s.designGoal
        ).prefix(6))

        let allDiscovery = DiscoveryEngine.loadAll()
        let signals = DiscoverySignalStore.load(for: profileId)
        topDiscovery = DiscoveryEngine.dailyRadar(
            items: allDiscovery,
            axisScores: axisScores,
            signals: signals,
            profileId: profileId,
            vector: vector
        )
    }

    private func resolveBaseVector(profile: TasteProfile) -> TasteVector {
        if let record = CalibrationStore.load(for: profile.id) {
            let imageVector = TasteEngine.vectorFromProfile(profile)
            return TasteVector.blend(
                image: imageVector,
                swipe: record.vector.normalized(),
                mode: .wantMore
            )
        } else {
            return TasteEngine.vectorFromProfile(profile)
        }
    }

    // MARK: - Stability

    private var stability: String {
        guard let record = calibrationRecord else { return "Low" }
        return record.vector.stabilityLevel(swipeCount: record.swipeCount)
    }

    private var refineCTALabel: String {
        switch stability {
        case "Stable": return "Explore variations"
        case "Developing": return "Refine a bit more"
        default: return "Refine your profile"
        }
    }

    // MARK: - Section A: Identity

    private func identitySection(_ saved: SavedProfile) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("PROFILE 01")
                .sectionLabel()

            if let naming = namingResult, !naming.name.isEmpty {
                Text(naming.name)
                    .font(.system(size: 48, weight: .semibold, design: .serif))
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text(saved.tasteProfile.displayName)
                    .font(.system(size: 48, weight: .semibold, design: .serif))
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !readingText.isEmpty {
                Text(readingText)
                    .font(.subheadline)
                    .foregroundStyle(Theme.ink.opacity(0.85))
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            RadarChart(axisScores: axisScores)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)

            // Influences
            let influencePhrases = AxisPresentation.influencePhrases(axisScores: axisScores)
            if !influencePhrases.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("INFLUENCES")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Theme.muted)
                        .tracking(1.0)

                    FlowLayout(spacing: 6) {
                        ForEach(influencePhrases, id: \.self) { phrase in
                            Text(phrase)
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(Theme.ink)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Theme.bg)
                                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                        }
                    }
                }
            }

            // Avoids
            let avoidPhrases = AxisPresentation.avoidPhrases(axisScores: axisScores)
            if !avoidPhrases.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("AVOIDS")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Theme.muted)
                        .tracking(1.0)

                    FlowLayout(spacing: 6) {
                        ForEach(avoidPhrases, id: \.self) { phrase in
                            Text(phrase)
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(Theme.muted)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Theme.bg)
                                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                        }
                    }
                }
            }

            // Confidence
            let swipeCount = calibrationRecord?.swipeCount ?? 0
            let level = vector.confidenceLevel(swipeCount: swipeCount)
            HStack(spacing: 10) {
                Text("CONFIDENCE")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Theme.muted)
                    .tracking(1.0)
                Text(level)
                    .font(.caption2)
                    .foregroundStyle(Theme.ink)
            }
        }
    }

    // MARK: - Section B: Selection

    private func selectionSection(_ saved: SavedProfile) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("SELECTION")
                .sectionLabel()

            if topCommerce.isEmpty {
                Text("No pieces matched your profile.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.muted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
            } else {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16)
                    ],
                    spacing: 16
                ) {
                    ForEach(topCommerce) { item in
                        Button {
                            path.append(Route.recommendationDetail(item, tasteProfileId: profileId))
                        } label: {
                            pickCard(item)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Shop entry
            Button {
                Haptics.tap()
                path.append(Route.shop(saved.tasteProfile))
            } label: {
                VStack(alignment: .leading, spacing: 8) {
                    Text("ENTER SHOP")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.muted)
                        .tracking(1.2)

                    Text("Browse inside your profile.")
                        .font(.system(.subheadline, design: .serif, weight: .medium))
                        .foregroundStyle(Theme.ink)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .labSurface(padded: true, bordered: true)
            }
            .buttonStyle(.plain)
        }
    }

    private func pickCard(_ item: RecommendationItem) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            CachedImage(url: item.resolvedImageURL, height: 150)

            VStack(alignment: .leading, spacing: 6) {
                Text(item.title)
                    .font(.system(.subheadline, design: .default, weight: .medium))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(2)

                Text("$\(Int(item.price))")
                    .font(.caption.monospacedDigit().weight(.medium))
                    .foregroundStyle(Theme.muted)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
        .labSurface(padded: false, bordered: true)
    }

    // MARK: - Section C: Evolution

    private func evolutionSection(_ saved: SavedProfile) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("EVOLUTION")
                .sectionLabel()

            if let record = calibrationRecord {
                let calScores = AxisMapping.computeAxisScores(from: record.vector)
                let phrases = AxisPresentation.influencePhrases(axisScores: calScores)

                if !phrases.isEmpty {
                    Text(phrases.joined(separator: ", "))
                        .font(.subheadline)
                        .foregroundStyle(Theme.ink)
                }

                HStack(spacing: 10) {
                    Text("STABILITY")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Theme.muted)
                        .tracking(1.0)
                    Text(stability)
                        .font(.caption2)
                        .foregroundStyle(Theme.ink)
                }
            } else {
                Text("Refine to sharpen your profile.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.muted)
            }

            // Primary CTA
            Button {
                Haptics.tap()
                path.append(Route.calibration(saved.tasteProfile, saved.recommendations))
            } label: {
                Text(refineCTALabel)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Theme.ink)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.radius, style: .continuous))
            }
            .buttonStyle(.plain)

            // Board CTA — only when Stable
            if stability == "Stable" {
                Button {
                    Haptics.tap()
                    path.append(Route.board(saved.recommendations))
                } label: {
                    Text("Generate a board")
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(Theme.ink)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.radius, style: .continuous)
                                .stroke(Theme.hairline, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }

            // Board empty state preview — when no bookmarks
            let savedCount = FavoritesStore.loadAll().count
            if savedCount < 3 {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Nothing saved yet")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Theme.muted)
                    Text("Save 3 pieces to unlock your board.")
                        .font(.caption2)
                        .foregroundStyle(Theme.muted)
                }
                .padding(.top, 4)
            }
        }
        .labSurface(padded: true, bordered: true)
    }

    // MARK: - Section D: Radar (Discovery)

    private func radarSection(_ saved: SavedProfile) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("RADAR")
                    .sectionLabel()

                Text("Updated today.")
                    .font(.caption2)
                    .foregroundStyle(Theme.muted)
            }

            if topDiscovery.isEmpty {
                Text("No signals found.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.muted)
                    .padding(.vertical, 16)
            } else {
                ForEach(topDiscovery) { item in
                    Button {
                        path.append(Route.discoveryDetail(item))
                    } label: {
                        discoveryCard(item)
                    }
                    .buttonStyle(.plain)
                }
            }

            Button {
                Haptics.tap()
                path.append(Route.result(saved.tasteProfile, saved.recommendations))
            } label: {
                Text("See more")
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(Theme.ink)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.radius, style: .continuous)
                            .stroke(Theme.hairline, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
    }

    private func discoveryCard(_ item: DiscoveryItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(item.type.rawValue.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Theme.muted)
                .tracking(1.0)

            Text(item.title)
                .font(.system(.subheadline, design: .serif, weight: .semibold))
                .foregroundStyle(Theme.ink)

            if !item.primaryRegion.isEmpty {
                Text(item.primaryRegion)
                    .font(.caption2)
                    .foregroundStyle(Theme.muted)
            }

            Text(item.body)
                .font(.caption)
                .foregroundStyle(Theme.muted)
                .lineLimit(3)
                .lineSpacing(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .labSurface(padded: true, bordered: true)
    }
}
