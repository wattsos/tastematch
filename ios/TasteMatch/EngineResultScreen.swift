import SwiftUI

struct EngineResultScreen: View {
    @Binding var path: NavigationPath
    let profile: TasteProfile
    let recommendations: [RecommendationItem]
    var domain: TasteDomain = .space

    private var topItem: RecommendationItem? { recommendations.first }

    private var confidence: Double {
        profile.tags.first?.confidence ?? 0
    }

    private var qualitativeLabel: String {
        switch confidence {
        case 0.8...: return "High"
        case 0.5...: return "Moderate"
        default:     return "Low"
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                matchHeader
                decisionRow
                if !recommendations.isEmpty {
                    selectionList
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 48)
            .padding(.bottom, 48)
        }
        .background {
            Theme.bg.ignoresSafeArea()
        }
        .navigationBarTitleDisplayMode(.inline)
        .tint(Theme.ink)
    }

    // MARK: - Match Header

    private var matchHeader: some View {
        VStack(spacing: 8) {
            Text("MATCH")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.muted)
                .tracking(1.2)

            Text("\(Int(confidence * 100))%")
                .font(.system(size: 56, weight: .bold, design: .serif))
                .foregroundStyle(Theme.ink)

            Text(qualitativeLabel)
                .font(.caption)
                .foregroundStyle(Theme.muted)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Decision Buttons

    private var decisionRow: some View {
        HStack(spacing: 12) {
            decisionButton("Me", action: .aligned)
            decisionButton("Not me", action: .notForMe)
            decisionButton("Buy", action: .bought)
        }
    }

    private func decisionButton(_ label: String, action: DecisionAction) -> some View {
        Button {
            recordDecision(action)
        } label: {
            Text(label)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Theme.ink)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: Theme.radius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.radius, style: .continuous)
                        .stroke(Theme.hairline, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Top 3 Selection

    private var selectionList: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("SELECTION")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.muted)
                .tracking(1.2)

            VStack(spacing: 0) {
                ForEach(Array(recommendations.prefix(3).enumerated()), id: \.element.id) { index, item in
                    if index > 0 {
                        HairlineDivider()
                    }
                    Button {
                        path.append(Route.recommendationDetail(item, tasteProfileId: profile.id, domain: domain))
                    } label: {
                        HStack(spacing: 12) {
                            CachedImage(url: item.resolvedImageURL, height: 40, width: 40)
                                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.title)
                                    .font(.subheadline)
                                    .foregroundStyle(Theme.ink)
                                    .lineLimit(1)

                                Text("$\(Int(item.price))")
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(Theme.muted)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(Theme.muted)
                        }
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Decision Logic

    private func recordDecision(_ action: DecisionAction) {
        guard let item = topItem else { return }

        let event = DecisionEvent(
            id: UUID(),
            profileId: profile.id,
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

        applyDecisionShift(item: item, multiplier: multiplier)

        EventLogger.shared.logEvent(
            "decision_\(action.rawValue)",
            tasteProfileId: profile.id,
            metadata: [
                "skuId": item.skuId,
                "merchant": item.merchant,
                "confidence": String(format: "%.2f", item.attributionConfidence),
            ]
        )

        Haptics.tap()
        path = NavigationPath()
    }

    private func applyDecisionShift(item: RecommendationItem, multiplier: Double) {
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
            var record = CalibrationStore.load(for: profile.id) ?? CalibrationRecord(
                tasteProfileId: profile.id,
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
            guard var record = ObjectCalibrationStore.load(for: profile.id) else { return }
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
}
