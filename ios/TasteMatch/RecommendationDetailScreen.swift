import SwiftUI

struct RecommendationDetailScreen: View {
    let item: RecommendationItem
    let tasteProfileId: UUID
    var domain: TasteDomain = .space
    @Environment(\.openURL) private var openURL
    @EnvironmentObject private var advisorySettings: AdvisorySettings
    @State private var isFavorited = false
    @State private var showGuard = false
    @State private var showShiftToast = false
    @Environment(\.dismiss) private var dismiss

    private var objectDecision: AdvisoryDecision? {
        guard domain == .objects else { return nil }
        return ObjectAdvisory.decision(
            for: item,
            profileId: tasteProfileId,
            level: advisorySettings.level,
            tolerance: AdvisoryToleranceStore.tolerance
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                heroImage

                VStack(alignment: .leading, spacing: 28) {
                    titleSection
                    reasonSection
                    matchSection
                    shopButton
                    decisionButtons
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 48)
            }
        }
        .background {
            Theme.bg.ignoresSafeArea()
        }
        .navigationBarTitleDisplayMode(.inline)
        .tint(Theme.ink)
        .onAppear {
            isFavorited = FavoritesStore.isFavorited(item)
            EventLogger.shared.logEvent("product_viewed", tasteProfileId: tasteProfileId, metadata: eventMeta)
        }
        .sheet(isPresented: $showGuard) {
            if let decision = objectDecision {
                TasteGuardSheet(
                    item: item,
                    decision: decision,
                    advisoryLevel: advisorySettings.level,
                    profileId: tasteProfileId,
                    onProceed: {
                        let urlString = item.affiliateURL ?? item.productURL
                        if let url = URL(string: urlString) { openURL(url) }
                    },
                    onSave: {
                        if !isFavorited { toggleFavorite() }
                    },
                    onIntentionalShift: {
                        ObjectAdvisory.applyIntentionalShift(item: item, profileId: tasteProfileId)
                        showShiftToast = true
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

    // MARK: - Hero Image

    private var heroImage: some View {
        ZStack(alignment: .bottomTrailing) {
            CachedImage(url: item.resolvedImageURL, height: 300)

            Button {
                toggleFavorite()
            } label: {
                Image(systemName: isFavorited ? "bookmark.fill" : "bookmark")
                    .font(.title3)
                    .foregroundStyle(isFavorited ? Theme.accent : Theme.ink.opacity(0.55))
                    .padding(10)
                    .background(Theme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.radius, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.radius, style: .continuous)
                            .stroke(Theme.hairline, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .padding(16)
            .accessibilityLabel(isFavorited ? "Saved" : "Save")
        }
    }

    // MARK: - Title

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(item.title)
                .font(Theme.headlineFont)
                .foregroundStyle(Theme.ink)

            HStack(spacing: 16) {
                Text(item.merchant)
                    .font(.subheadline)
                    .foregroundStyle(Theme.muted)

                Text("$\(Int(item.price))")
                    .font(.title2.monospacedDigit().weight(.semibold))
                    .foregroundStyle(Theme.ink)
            }
        }
    }

    // MARK: - Why This Fits

    private var reasonSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Why This Fits")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.muted)

            Text(item.reason)
                .font(.body)
                .foregroundStyle(Theme.ink.opacity(0.85))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radius))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.radius)
                .stroke(Theme.hairline, lineWidth: 1)
        )
    }

    // MARK: - Match / FIT Section

    @ViewBuilder
    private var matchSection: some View {
        if domain == .objects, let decision = objectDecision {
            HStack(spacing: 12) {
                Text("FIT")
                    .font(.caption.weight(.semibold))
                    .tracking(1)
                    .foregroundStyle(Theme.muted)
                Spacer()
                ObjectFitBadge(decision: decision)
            }
        } else {
            HStack(spacing: 12) {
                Text("ALIGNMENT")
                    .font(.caption.weight(.semibold))
                    .tracking(1)
                    .foregroundStyle(Theme.muted)

                ProgressView(value: item.attributionConfidence)
                    .tint(confidenceColor)

                Text("\(Int(item.attributionConfidence * 100))%")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(Theme.muted)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Alignment, \(Int(item.attributionConfidence * 100)) percent")
        }
    }

    // MARK: - Shop Button

    private var shopButton: some View {
        Button {
            EventLogger.shared.logEvent("product_clicked", tasteProfileId: tasteProfileId, metadata: eventMeta)
            handleOutboundTap()
        } label: {
            Text("View")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .foregroundStyle(.white)
        .background(Theme.accent)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radius))
    }

    // MARK: - Decision Buttons

    private var decisionButtons: some View {
        HStack(spacing: 12) {
            decisionButton("Aligned", action: .aligned)
            decisionButton("Not for me", action: .notForMe)
            decisionButton("Bought", action: .bought)
        }
    }

    private func decisionButton(_ label: String, action: DecisionAction) -> some View {
        Button {
            recordDecision(action)
        } label: {
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundStyle(Theme.ink)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: Theme.radius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.radius, style: .continuous)
                        .stroke(Theme.hairline, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private func recordDecision(_ action: DecisionAction) {
        let event = DecisionEvent(
            id: UUID(),
            profileId: tasteProfileId,
            skuId: item.skuId,
            action: action,
            timestamp: Date()
        )
        DecisionStore.record(event)

        let multiplier: Double
        switch action {
        case .aligned:  multiplier = 0.15
        case .notForMe: multiplier = -0.10
        case .bought:   multiplier = 0.25
        }

        applyDecisionShift(multiplier: multiplier)

        EventLogger.shared.logEvent(
            "decision_\(action.rawValue)",
            tasteProfileId: tasteProfileId,
            metadata: eventMeta
        )

        Haptics.tap()
        dismiss()
    }

    private func applyDecisionShift(multiplier: Double) {
        let catalog = DomainCatalog.items(for: domain)
        guard let catalogItem = catalog.first(where: { $0.skuId == item.skuId }) else { return }

        switch domain {
        case .space:
            guard !catalogItem.commerceAxisWeights.isEmpty else { return }
            let synthetic = AxisMapping.syntheticVector(fromAxes: catalogItem.commerceAxisWeights)
            var scaled: [String: Double] = [:]
            for (key, val) in synthetic.weights {
                scaled[key] = val * multiplier
            }
            var record = CalibrationStore.load(for: tasteProfileId) ?? CalibrationRecord(
                tasteProfileId: tasteProfileId,
                vector: .zero,
                swipeCount: 0,
                createdAt: Date()
            )
            for (key, val) in scaled {
                record.vector.weights[key, default: 0] += val
            }
            record.vector = record.vector.normalized()
            CalibrationStore.save(record)

        case .objects:
            guard !catalogItem.objectAxisWeights.isEmpty else { return }
            guard var record = ObjectCalibrationStore.load(for: tasteProfileId) else { return }
            for axis in ObjectAxis.allCases {
                let key = axis.rawValue
                let current = record.vector.weights[key, default: 0.0]
                let itemVal = catalogItem.objectAxisWeights[key, default: 0.0]
                record.vector.weights[key] = current + multiplier * itemVal
            }
            ObjectCalibrationStore.save(record)

        default:
            break
        }
    }

    // MARK: - Advisory

    private func handleOutboundTap() {
        if domain == .objects, let decision = objectDecision, decision.shouldIntercept {
            showGuard = true
        } else {
            let urlString = item.affiliateURL ?? item.productURL
            if let url = URL(string: urlString) {
                openURL(url)
            }
        }
    }

    // MARK: - Favorites

    private func toggleFavorite() {
        Haptics.tap()
        if isFavorited {
            let stored = FavoritesStore.loadAll()
            if let match = stored.first(where: { $0.title == item.title && $0.subtitle == item.subtitle }) {
                FavoritesStore.remove(id: match.id)
            }
            EventLogger.shared.logEvent("product_unsaved", tasteProfileId: tasteProfileId, metadata: eventMeta)
        } else {
            FavoritesStore.add(item)
            EventLogger.shared.logEvent("product_saved", tasteProfileId: tasteProfileId, metadata: eventMeta)
        }
        isFavorited.toggle()
    }

    // MARK: - Attribution Helpers

    private var confidenceLabel: String {
        switch item.attributionConfidence {
        case 0.8...: return "High"
        case 0.5...: return "Moderate"
        default:     return "Low"
        }
    }

    private var confidenceColor: Color {
        switch item.attributionConfidence {
        case 0.8...: return Theme.strongMatch
        case 0.5...: return Theme.goodMatch
        default:     return Theme.partialMatch
        }
    }

    // MARK: - Event Metadata

    private var eventMeta: [String: String] {
        [
            "skuId": item.skuId,
            "merchant": item.merchant,
            "confidence": String(format: "%.2f", item.attributionConfidence),
        ]
    }
}
