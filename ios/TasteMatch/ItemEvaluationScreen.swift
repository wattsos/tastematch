import SwiftUI

struct ItemEvaluationScreen: View {
    @Binding var path: NavigationPath
    let evaluation: TasteEvaluation
    var readOnly: Bool = false

    @State private var voted = false
    @State private var selectedVote: TasteVote?
    @State private var showReturnReasonPicker = false
    @State private var selectedReturnReason: ReturnReason?
    @State private var pendingRecord: PendingReinforcement?
    @State private var anchorConfirmed = false

    private var category: FurnitureCategory { evaluation.furnitureCategory ?? .other }

    private var tensionLabel: String {
        switch evaluation.tensionScore {
        case 0...20:  return "None"
        case 21...50: return "Low"
        case 51...70: return "Moderate"
        default:      return "High"
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                alignmentHero
                metaRow
                if evaluation.tensionScore > 60 {
                    tensionCallout
                } else if !evaluation.tensionFlags.isEmpty {
                    tensionSection
                }
                reasonsSection

                if !readOnly && !voted {
                    voteButtons
                } else if voted {
                    voteResultSection
                } else if readOnly, let vote = evaluation.tasteVote {
                    existingVoteBadge(vote)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
        .background(Theme.bg)
        .navigationTitle("READING")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showReturnReasonPicker) {
            returnReasonSheet
        }
    }

    // MARK: - Hero

    private var alignmentHero: some View {
        VStack(spacing: 8) {
            if category.isAnchor {
                Text("ANCHOR PIECE")
                    .font(.system(size: 9, weight: .medium))
                    .tracking(1.2)
                    .foregroundStyle(Theme.muted)
                    .padding(.bottom, 4)
            }

            Text(ScoringService.alignmentLabel(evaluation.alignmentScore))
                .font(.system(size: 36, weight: .semibold, design: .default))
                .tracking(4)
                .foregroundStyle(Theme.ink)

            if let cat = evaluation.furnitureCategory, cat != .other {
                Text(cat.displayLabel.uppercased())
                    .font(.system(size: 9, weight: .medium))
                    .tracking(0.8)
                    .foregroundStyle(Theme.muted.opacity(0.7))
                    .padding(.top, 4)
            }
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
                value: ScoringService.confidenceLabel(evaluation.confidence),
                sub: nil
            )
            Rectangle().fill(Theme.hairline).frame(width: 1, height: 28)
            metaStat(
                label: "PURCHASE",
                value: ScoringService.purchaseConfidenceLabel(evaluation.purchaseConfidence),
                sub: nil
            )
            Rectangle().fill(Theme.hairline).frame(width: 1, height: 28)
            metaStat(
                label: "TENSION",
                value: tensionLabel,
                sub: nil
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

    private func metaStat(label: String, value: String, sub: String?) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Theme.ink)
            if let sub {
                Text(sub)
                    .font(.system(size: 9, weight: .regular, design: .monospaced))
                    .foregroundStyle(Theme.muted.opacity(0.7))
            }
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .tracking(0.8)
                .foregroundStyle(Theme.muted)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Tension Callout (tension > 60)

    private var tensionCallout: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Rectangle()
                    .fill(Theme.ink)
                    .frame(width: 2, height: 16)
                Text("TENSION ALERT")
                    .font(.system(.caption, design: .default, weight: .semibold))
                    .tracking(1.2)
                    .foregroundStyle(Theme.ink)
            }
            Text("This item conflicts with your recorded preferences. Tension score: \(evaluation.tensionScore)")
                .font(.subheadline)
                .foregroundStyle(Theme.ink)
            ForEach(evaluation.tensionFlags, id: \.self) { flag in
                Text("— \(flag)")
                    .font(.caption)
                    .foregroundStyle(Theme.muted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.radius, style: .continuous)
                .stroke(Theme.hairline, lineWidth: 1)
        )
    }

    // MARK: - Tension Section (tension ≤ 60)

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

    // MARK: - Vote Buttons

    private var voteButtons: some View {
        VStack(spacing: 12) {
            HairlineDivider()
            Text("THIS FEELS LIKE")
                .font(.system(.caption, design: .default, weight: .semibold))
                .tracking(1.2)
                .foregroundStyle(Theme.muted)
            HStack(spacing: 10) {
                voteButton(label: "Me",      vote: .me)
                voteButton(label: "Not me",  vote: .notMe)
                voteButton(label: "Maybe",   vote: .maybe)
            }
            Button {
                showReturnReasonPicker = true
            } label: {
                Text("Returned")
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
            .foregroundStyle(Theme.muted)
        }
    }

    private func voteButton(label: String, vote: TasteVote) -> some View {
        Button {
            recordVote(vote, returnReason: nil)
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

    // MARK: - Vote Result Section

    @ViewBuilder
    private var voteResultSection: some View {
        VStack(spacing: 12) {
            HairlineDivider()

            if let pending = pendingRecord, !anchorConfirmed {
                anchorPendingView(pending)
            } else if let vote = selectedVote {
                confirmedBadge(vote)
            }
        }
    }

    private func anchorPendingView(_ pending: PendingReinforcement) -> some View {
        VStack(spacing: 10) {
            Text("ANCHOR PIECE — HELD")
                .font(.system(.caption, design: .default, weight: .semibold))
                .tracking(1.2)
                .foregroundStyle(Theme.ink)

            Text("Logged. We'll lock this in after you've lived with it.")
                .font(.subheadline)
                .foregroundStyle(Theme.muted)
                .multilineTextAlignment(.center)

            Button {
                confirmPendingNow(pending)
            } label: {
                Text("Confirm Now")
                    .font(.subheadline.weight(.medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Theme.ink)
                    .foregroundStyle(Theme.bg)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.radius, style: .continuous))
            }
        }
        .padding(14)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.radius, style: .continuous)
                .stroke(Theme.hairline, lineWidth: 1)
        )
    }

    private func confirmedBadge(_ vote: TasteVote) -> some View {
        VStack(spacing: 6) {
            Text(voteConfirmLabel(vote))
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

    private func existingVoteBadge(_ vote: TasteVote) -> some View {
        VStack(spacing: 6) {
            HairlineDivider()
            Text("VOTED — \(voteDisplayLabel(vote).uppercased())")
                .font(.system(.caption, design: .default, weight: .semibold))
                .tracking(1.2)
                .foregroundStyle(Theme.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }

    private func voteConfirmLabel(_ vote: TasteVote) -> String {
        switch vote {
        case .me:       return "RECORDED — ME"
        case .notMe:    return "RECORDED — NOT ME"
        case .maybe:    return "RECORDED — MAYBE"
        case .returned: return "RECORDED — RETURNED"
        }
    }

    private func voteDisplayLabel(_ vote: TasteVote) -> String {
        switch vote {
        case .me:       return "Me"
        case .notMe:    return "Not me"
        case .maybe:    return "Maybe"
        case .returned: return "Returned"
        }
    }

    // MARK: - Return Reason Sheet

    private var returnReasonSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Text("Why are you returning it?")
                        .font(.subheadline)
                        .foregroundStyle(Theme.muted)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(ReturnReason.allCases, id: \.self) { reason in
                            returnReasonButton(reason)
                        }
                    }

                    Button {
                        if let reason = selectedReturnReason {
                            showReturnReasonPicker = false
                            recordVote(.returned, returnReason: reason)
                        }
                    } label: {
                        Text("Confirm")
                            .font(.subheadline.weight(.medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(selectedReturnReason != nil ? Theme.ink : Theme.hairline)
                            .foregroundStyle(selectedReturnReason != nil ? Theme.bg : Theme.muted)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.radius, style: .continuous))
                    }
                    .disabled(selectedReturnReason == nil)
                }
                .padding(20)
            }
            .background(Theme.bg)
            .navigationTitle("RETURNED")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { showReturnReasonPicker = false }
                        .foregroundStyle(Theme.ink)
                }
            }
        }
    }

    private func returnReasonButton(_ reason: ReturnReason) -> some View {
        let isSelected = selectedReturnReason == reason
        return Button {
            selectedReturnReason = isSelected ? nil : reason
        } label: {
            Text(reason.displayLabel)
                .font(.caption.weight(.medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(isSelected ? Theme.ink : Theme.surface)
                .foregroundStyle(isSelected ? Theme.bg : Theme.ink)
                .clipShape(RoundedRectangle(cornerRadius: Theme.radius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.radius, style: .continuous)
                        .stroke(Theme.hairline, lineWidth: 1)
                )
        }
    }

    // MARK: - Record Vote

    private func recordVote(_ vote: TasteVote, returnReason: ReturnReason?) {
        guard !voted else { return }
        Haptics.impact()
        selectedVote = vote

        // 1. Optimistic local reinforcement (instant; keeps UI snappy)
        let session  = BurgundySession.shared
        let identity = session.current
        let result   = ReinforcementService.applyTasteVote(
            vote: vote,
            candidateEmbedding: evaluation.candidate.embedding,
            category: category,
            returnReason: returnReason,
            evaluationId: evaluation.id,
            to: identity
        )
        session.current = result.identity  // persists locally via BurgundySession

        if let pending = result.pending {
            PendingReinforcementStore.append(pending)
            pendingRecord = pending
        }

        var updatedEval = evaluation
        updatedEval.tasteVote    = vote
        updatedEval.returnReason = returnReason
        TasteEventStore.append(updatedEval)

        // 2. Fire-and-forget to server (non-blocking)
        Task {
            _ = try? await BurgundyAPI.recordEvent(
                vote: vote,
                evaluation: evaluation,
                returnReason: returnReason,
                identity: identity
            )
        }

        Haptics.success()
        voted = true
    }

    // MARK: - Confirm Pending Now

    private func confirmPendingNow(_ pending: PendingReinforcement) {
        Haptics.impact()
        let session  = BurgundySession.shared
        let updated  = ReinforcementService.finalizePending(pending, to: session.current)
        session.current = updated
        PendingReinforcementStore.remove(id: pending.id)
        anchorConfirmed = true
        Haptics.success()
    }
}
