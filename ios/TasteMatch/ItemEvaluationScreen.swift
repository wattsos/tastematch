import SwiftUI

struct ItemEvaluationScreen: View {
    @Binding var path: NavigationPath
    let evaluation: TasteEvaluatedObject
    let candidateVector: TasteVector
    var readOnly: Bool = false

    @State private var acted = false
    @State private var selectedAction: TasteAction?

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                alignmentHero
                metaRow
                if !evaluation.tensionFlags.isEmpty {
                    tensionSection
                }
                reasonsSection
                if !readOnly && !acted {
                    actionButtons
                } else if acted, let action = selectedAction {
                    confirmedBadge(action)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
        .background(Theme.bg)
        .navigationTitle("READING")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Hero

    private var alignmentHero: some View {
        VStack(spacing: 8) {
            Text(ScoringService.alignmentLabel(evaluation.alignmentScore))
                .font(.system(size: 36, weight: .semibold, design: .default))
                .tracking(4)
                .foregroundStyle(Theme.ink)

            Text("\(evaluation.alignmentScore)")
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(Theme.muted)
                .padding(.top, 2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.radius, style: .continuous)
                .stroke(Theme.hairline, lineWidth: 1)
        )
    }

    // MARK: - Meta Row

    private var metaRow: some View {
        HStack(spacing: 0) {
            metaStat(
                label: "CONFIDENCE",
                value: ScoringService.confidenceLabel(evaluation.confidence)
            )
            Rectangle().fill(Theme.hairline).frame(width: 1, height: 28)
            metaStat(
                label: "REGRET RISK",
                value: ScoringService.riskLabel(evaluation.riskOfRegret)
            )
            Rectangle().fill(Theme.hairline).frame(width: 1, height: 28)
            metaStat(
                label: "PROFILE v\(evaluation.identityVersionUsed)",
                value: evaluation.tensionFlags.isEmpty ? "Clean" : "\(evaluation.tensionFlags.count) flag\(evaluation.tensionFlags.count == 1 ? "" : "s")"
            )
        }
        .padding(.vertical, 14)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.radius, style: .continuous)
                .stroke(Theme.hairline, lineWidth: 1)
        )
    }

    private func metaStat(label: String, value: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Theme.ink)
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .tracking(0.8)
                .foregroundStyle(Theme.muted)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Tension Section

    private var tensionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("TENSION FLAGS")
                .font(.system(.caption, design: .default, weight: .semibold))
                .tracking(1.2)
                .foregroundStyle(Theme.muted)

            VStack(alignment: .leading, spacing: 6) {
                ForEach(evaluation.tensionFlags, id: \.self) { flag in
                    HStack(spacing: 8) {
                        Rectangle()
                            .fill(Theme.ink.opacity(0.4))
                            .frame(width: 2, height: 14)
                        Text(flag)
                            .font(.subheadline)
                            .foregroundStyle(Theme.ink)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Reasons Section

    private var reasonsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("SIGNALS")
                .font(.system(.caption, design: .default, weight: .semibold))
                .tracking(1.2)
                .foregroundStyle(Theme.muted)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(evaluation.reasons, id: \.self) { reason in
                    HStack(alignment: .top, spacing: 10) {
                        Rectangle()
                            .fill(Theme.hairline)
                            .frame(width: 1, height: nil)
                            .frame(minHeight: 14)
                        Text(reason)
                            .font(.subheadline)
                            .foregroundStyle(Theme.ink)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            HairlineDivider()
            Text("RECORD DECISION")
                .font(.system(.caption, design: .default, weight: .semibold))
                .tracking(1.2)
                .foregroundStyle(Theme.muted)

            HStack(spacing: 10) {
                actionButton(label: "Bought", action: .bought)
                actionButton(label: "Passed", action: .rejected)
                actionButton(label: "Regret", action: .regretted)
            }
        }
    }

    private func actionButton(label: String, action: TasteAction) -> some View {
        Button {
            recordAction(action)
        } label: {
            Text(label)
                .font(.subheadline.weight(.medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: Theme.radius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.radius, style: .continuous)
                        .stroke(Theme.hairline, lineWidth: 1)
                )
        }
        .foregroundStyle(Theme.ink)
    }

    private func confirmedBadge(_ action: TasteAction) -> some View {
        VStack(spacing: 6) {
            HairlineDivider()
            Text(actionConfirmLabel(action))
                .font(.system(.caption, design: .default, weight: .semibold))
                .tracking(1.2)
                .foregroundStyle(Theme.muted)
            Text("Identity updated")
                .font(.caption2)
                .foregroundStyle(Theme.muted.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }

    private func actionConfirmLabel(_ action: TasteAction) -> String {
        switch action {
        case .bought:    return "RECORDED — BOUGHT"
        case .rejected:  return "RECORDED — PASSED"
        case .regretted: return "RECORDED — REGRET"
        }
    }

    // MARK: - Record

    private func recordAction(_ action: TasteAction) {
        Haptics.impact()
        selectedAction = action

        var identity = IdentityStore.load() ?? TasteIdentity(vector: candidateVector)
        let versionBefore = identity.version
        identity = ReinforcementService.apply(
            action: action,
            candidateVector: candidateVector,
            to: identity
        )
        IdentityStore.save(identity)

        let event = TasteEvent(
            id: UUID(),
            action: action,
            evaluation: evaluation,
            identityVersionBefore: versionBefore,
            identityVersionAfter: identity.version,
            timestamp: Date()
        )
        TasteEventStore.append(event: event)

        Haptics.success()
        acted = true
    }
}
