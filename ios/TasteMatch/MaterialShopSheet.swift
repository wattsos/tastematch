import SwiftUI

struct MaterialShopSheet: View {
    let material: DiscoveryItem
    var domain: TasteDomain = .space
    var profileId: UUID? = nil
    @Environment(\.openURL) private var openURL
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var advisorySettings: AdvisorySettings

    @State private var guardItem: RecommendationItem?
    @State private var guardDecision: AdvisoryDecision?
    @State private var showShiftToast = false

    private var rankedItems: [RecommendationItem] {
        let syntheticVector = AxisMapping.syntheticVector(fromAxes: material.axisWeights)
        let axisScores = AxisMapping.computeAxisScores(from: syntheticVector)
        let materialFilter = material.title.split(separator: " ").first.map(String.init)
        return Array(
            RecommendationEngine.rankCommerceItems(
                vector: syntheticVector,
                axisScores: axisScores,
                items: DomainCatalog.items(for: domain),
                materialFilter: materialFilter,
                domain: domain
            ).prefix(20)
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("SELECTION")
                        .sectionLabel()
                        .padding(.top, 8)

                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: 16),
                            GridItem(.flexible(), spacing: 16)
                        ],
                        spacing: 16
                    ) {
                        ForEach(rankedItems) { item in
                            Button {
                                handleOutboundTap(item)
                            } label: {
                                shopCard(item)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(16)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle(material.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Theme.ink)
                        .font(.callout.weight(.semibold))
                }
            }
        }
        .presentationDragIndicator(.visible)
        .sheet(item: $guardItem) { item in
            if let decision = guardDecision {
                TasteGuardSheet(
                    item: item,
                    decision: decision,
                    advisoryLevel: advisorySettings.level,
                    profileId: profileId ?? UUID(),
                    onProceed: {
                        let urlString = item.affiliateURL ?? item.productURL
                        if let url = URL(string: urlString) { openURL(url) }
                    },
                    onSave: { },
                    onIntentionalShift: {
                        if let pid = profileId {
                            ObjectAdvisory.applyIntentionalShift(item: item, profileId: pid)
                            showShiftToast = true
                        }
                    }
                )
                .presentationDetents([.medium])
            }
        }
        .overlay(alignment: .bottom) {
            if showShiftToast {
                Text("Profile updated.")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Theme.ink)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.radius, style: .continuous))
                    .padding(.bottom, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            withAnimation { showShiftToast = false }
                        }
                    }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showShiftToast)
    }

    // MARK: - Advisory

    private func handleOutboundTap(_ item: RecommendationItem) {
        if domain == .objects, let pid = profileId,
           let decision = ObjectAdvisory.decision(
               for: item, profileId: pid,
               level: advisorySettings.level,
               tolerance: AdvisoryToleranceStore.tolerance
           ),
           decision.shouldIntercept {
            guardItem = item
            guardDecision = decision
        } else {
            let urlString = item.affiliateURL ?? item.productURL
            if let url = URL(string: urlString) {
                openURL(url)
            }
        }
    }

    // MARK: - Card

    private func shopCard(_ item: RecommendationItem) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            CachedImage(url: item.resolvedImageURL, height: 150)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(item.title)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Theme.ink)
                        .lineLimit(2)
                    if domain == .objects, let pid = profileId,
                       let decision = ObjectAdvisory.decision(
                           for: item, profileId: pid,
                           level: advisorySettings.level,
                           tolerance: AdvisoryToleranceStore.tolerance
                       ) {
                        Spacer()
                        ObjectFitBadge(decision: decision, compact: true)
                    }
                }
                Text(item.brand)
                    .font(.caption2)
                    .foregroundStyle(Theme.muted)
                    .lineLimit(1)
                Text("$\(Int(item.price))")
                    .font(.caption2.monospacedDigit().weight(.medium))
                    .foregroundStyle(Theme.ink)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
        }
        .labSurface(padded: false, bordered: true)
    }
}
