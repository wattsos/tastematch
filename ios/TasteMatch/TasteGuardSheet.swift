import SwiftUI

// MARK: - Taste Guard Sheet

struct TasteGuardSheet: View {
    let item: RecommendationItem
    let decision: AdvisoryDecision
    let advisoryLevel: AdvisoryLevel
    let profileId: UUID
    let onProceed: () -> Void
    let onSave: () -> Void
    let onIntentionalShift: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            header
            metricsSection
            verdictBadge
            HairlineDivider()
            actionButtons
            advisoryFooter
        }
        .padding(24)
        .background(Theme.bg.ignoresSafeArea())
        .onAppear {
            EventLogger.shared.logEvent(
                "taste_check_shown",
                tasteProfileId: profileId,
                metadata: eventMetadata
            )
            AdvisorySignalStore.record(AdvisorySignal(
                timestamp: Date(), action: "shown",
                verdict: decision.verdict.rawValue, skuId: item.skuId
            ))
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("TASTE CHECK")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.muted)
                .tracking(1.2)

            Text(item.title)
                .font(.system(.headline, design: .default, weight: .medium))
                .foregroundStyle(Theme.ink)
                .lineLimit(2)

            Text(item.brand)
                .font(.caption)
                .foregroundStyle(Theme.muted)
        }
    }

    // MARK: - Metrics

    private var metricsSection: some View {
        VStack(spacing: 10) {
            metricRow(label: "Fit", value: "\(Int(decision.conflict.alignment * 100))")
            metricRow(label: "Drift", value: "\(Int(decision.conflict.drift * 100))")
            if !decision.conflict.conflictAxes.isEmpty {
                HStack {
                    Text("Conflict")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Theme.muted)
                    Spacer()
                    Text(decision.conflict.conflictAxes.joined(separator: " \u{00B7} "))
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Theme.ink)
                }
            }
        }
        .padding(16)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.radius, style: .continuous)
                .stroke(Theme.hairline, lineWidth: 1)
        )
    }

    private func metricRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundStyle(Theme.muted)
            Spacer()
            Text(value)
                .font(.subheadline.monospacedDigit().weight(.medium))
                .foregroundStyle(Theme.ink)
        }
    }

    // MARK: - Verdict Badge

    private var verdictBadge: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(verdictColor)
                .frame(width: 6, height: 6)
            Text(decision.verdict.headline)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.ink)
            Text(decision.verdict.subhead)
                .font(.caption2)
                .foregroundStyle(Theme.muted)
                .lineLimit(2)
        }
    }

    // MARK: - Actions

    private var actionButtons: some View {
        VStack(spacing: 10) {
            Button {
                EventLogger.shared.logEvent(
                    "taste_check_proceeded",
                    tasteProfileId: profileId,
                    metadata: eventMetadata
                )
                AdvisorySignalStore.record(AdvisorySignal(
                    timestamp: Date(), action: "proceeded",
                    verdict: decision.verdict.rawValue, skuId: item.skuId
                ))
                if decision.verdict == .red {
                    EventLogger.shared.logEvent(
                        "taste_check_overridden",
                        tasteProfileId: profileId,
                        metadata: eventMetadata
                    )
                }
                onProceed()
                dismiss()
            } label: {
                Text("Proceed anyway")
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

            HStack(spacing: 10) {
                Button {
                    EventLogger.shared.logEvent(
                        "taste_check_saved",
                        tasteProfileId: profileId,
                        metadata: eventMetadata
                    )
                    onSave()
                    dismiss()
                } label: {
                    Text("Save")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Theme.muted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.plain)

                Button {
                    EventLogger.shared.logEvent(
                        "taste_check_intentional_shift",
                        tasteProfileId: profileId,
                        metadata: eventMetadata
                    )
                    AdvisorySignalStore.record(AdvisorySignal(
                        timestamp: Date(), action: "intentionalShift",
                        verdict: decision.verdict.rawValue, skuId: item.skuId
                    ))
                    onIntentionalShift()
                    dismiss()
                } label: {
                    Text("Intentional shift")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Theme.muted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Footer

    private var advisoryFooter: some View {
        Text("Advisory: \(advisoryLevel.displayName)")
            .font(.caption2)
            .foregroundStyle(Theme.muted)
    }

    // MARK: - Helpers

    private var verdictColor: Color {
        ObjectAdvisory.verdictDotColor(decision.verdict)
    }

    private var eventMetadata: [String: String] {
        [
            "domain": "objects",
            "skuId": item.skuId,
            "advisoryLevel": advisoryLevel.rawValue,
            "verdict": decision.verdict.rawValue,
            "alignment": String(format: "%.2f", decision.conflict.alignment),
            "drift": String(format: "%.2f", decision.conflict.drift),
            "conflictAxes": decision.conflict.conflictAxes.joined(separator: ","),
        ]
    }
}
