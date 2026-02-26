import SwiftUI

struct HistoryScreen: View {
    @Binding var path: NavigationPath
    @State private var evaluations: [TasteEvaluation] = []
    @State private var selectedEval: TasteEvaluation?

    var body: some View {
        Group {
            if evaluations.isEmpty {
                emptyState
            } else {
                evalList
            }
        }
        .navigationTitle("HISTORY")
        .navigationBarTitleDisplayMode(.inline)
        .tint(Theme.accent)
        .onAppear { reload() }
        .sheet(item: $selectedEval) { eval in
            HistoryDetailSheet(evaluation: eval) { updated in
                TasteEventStore.update(updated)
                reload()
            }
        }
    }

    private func reload() {
        evaluations = TasteEventStore.loadAll().reversed()
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "clock")
                .font(.system(size: 48))
                .foregroundStyle(Theme.muted)
            Text("No decisions yet")
                .font(Theme.headlineFont)
                .foregroundStyle(Theme.ink)
            Text("Scan items and record your vote to build your taste identity.")
                .font(.subheadline)
                .foregroundStyle(Theme.muted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
    }

    // MARK: - Evaluation List

    private var evalList: some View {
        List {
            ForEach(evaluations) { eval in
                Button {
                    selectedEval = eval
                } label: {
                    evalRow(eval)
                }
                .foregroundStyle(.primary)
            }
        }
        .listStyle(.plain)
    }

    private func evalRow(_ eval: TasteEvaluation) -> some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(ScoringService.alignmentLabel(eval.alignmentScore))
                        .font(.system(.subheadline, design: .default, weight: .semibold))
                        .tracking(1.0)
                        .foregroundStyle(Theme.ink)
                    if let cat = eval.furnitureCategory, cat != .other {
                        Text(cat.displayLabel.uppercased())
                            .font(.system(size: 9, weight: .medium))
                            .tracking(0.5)
                            .foregroundStyle(Theme.muted)
                    }
                }
                Text(formatted(eval.createdAt))
                    .font(.caption2)
                    .foregroundStyle(Theme.muted)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                if let vote = eval.tasteVote {
                    Text(voteLabel(vote))
                        .font(.system(size: 9, weight: .medium))
                        .tracking(0.5)
                        .foregroundStyle(Theme.muted)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Theme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .stroke(Theme.hairline, lineWidth: 1)
                        )
                }

                if PendingReinforcementStore.pending(for: eval.id) != nil {
                    Text("PENDING")
                        .font(.system(size: 9, weight: .medium))
                        .tracking(0.5)
                        .foregroundStyle(Theme.ink)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Theme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .stroke(Theme.ink.opacity(0.3), lineWidth: 1)
                        )
                }
            }

            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(Theme.muted.opacity(0.5))
        }
        .padding(.vertical, 4)
    }

    // MARK: - Helpers

    private func voteLabel(_ vote: TasteVote) -> String {
        switch vote {
        case .me:       return "ME"
        case .notMe:    return "NOT ME"
        case .maybe:    return "MAYBE"
        case .returned: return "RETURNED"
        }
    }

    private func formatted(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - History Detail Sheet

private struct HistoryDetailSheet: View {
    let evaluation: TasteEvaluation
    var onSave: (TasteEvaluation) -> Void

    @State private var selectedReturnReason: ReturnReason?
    @State private var notes: String = ""
    @State private var pendingRecord: PendingReinforcement?
    @State private var pendingConfirmed = false
    @Environment(\.dismiss) private var dismiss

    init(evaluation: TasteEvaluation, onSave: @escaping (TasteEvaluation) -> Void) {
        self.evaluation = evaluation
        self.onSave = onSave
        _selectedReturnReason = State(initialValue: evaluation.returnReason)
        _notes = State(initialValue: evaluation.notes ?? "")
        _pendingRecord = State(initialValue: PendingReinforcementStore.pending(for: evaluation.id))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    metricsSection
                    voteSection
                    if evaluation.tasteVote == .returned {
                        returnReasonSection
                    }
                    if !pendingConfirmed, let pending = pendingRecord {
                        pendingSection(pending)
                    }
                    if evaluation.tasteVote == .me || evaluation.tasteVote == .maybe {
                        markReturnedSection
                    }
                    notesSection
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
            .background(Theme.bg)
            .navigationTitle("DETAIL")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Theme.ink)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { saveAndDismiss() }
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Theme.ink)
                }
            }
        }
    }

    // MARK: - Metrics

    private var metricsSection: some View {
        HStack(spacing: 0) {
            metaStat(label: "ALIGNMENT",  value: "\(evaluation.alignmentScore)")
            Rectangle().fill(Theme.hairline).frame(width: 1, height: 28)
            metaStat(label: "PURCHASE",   value: ScoringService.purchaseConfidenceLabel(evaluation.purchaseConfidence))
            Rectangle().fill(Theme.hairline).frame(width: 1, height: 28)
            metaStat(label: "TENSION",    value: "\(evaluation.tensionScore)")
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

    // MARK: - Vote Display

    private var voteSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("TASTE VOTE")
                .font(.system(.caption, design: .default, weight: .semibold))
                .tracking(1.2)
                .foregroundStyle(Theme.muted)
            Text(evaluation.tasteVote.map { voteDisplayLabel($0) } ?? "No vote recorded")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(evaluation.tasteVote != nil ? Theme.ink : Theme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func voteDisplayLabel(_ vote: TasteVote) -> String {
        switch vote {
        case .me:       return "Me"
        case .notMe:    return "Not me"
        case .maybe:    return "Maybe"
        case .returned: return "Returned"
        }
    }

    // MARK: - Return Reason Picker

    private var returnReasonSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("RETURN REASON")
                .font(.system(.caption, design: .default, weight: .semibold))
                .tracking(1.2)
                .foregroundStyle(Theme.muted)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(ReturnReason.allCases, id: \.self) { reason in
                    returnReasonButton(reason)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func returnReasonButton(_ reason: ReturnReason) -> some View {
        let isSelected = selectedReturnReason == reason
        return Button {
            selectedReturnReason = isSelected ? nil : reason
        } label: {
            Text(reason.displayLabel)
                .font(.caption.weight(.medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(isSelected ? Theme.ink : Theme.surface)
                .foregroundStyle(isSelected ? Theme.bg : Theme.ink)
                .clipShape(RoundedRectangle(cornerRadius: Theme.radius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.radius, style: .continuous)
                        .stroke(Theme.hairline, lineWidth: 1)
                )
        }
    }

    // MARK: - Pending Reinforcement Section

    private func pendingSection(_ pending: PendingReinforcement) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ANCHOR PENDING")
                .font(.system(.caption, design: .default, weight: .semibold))
                .tracking(1.2)
                .foregroundStyle(Theme.ink)
            Text("This piece is held for 14 days before its influence is locked in. Confirm now to apply immediately.")
                .font(.subheadline)
                .foregroundStyle(Theme.muted)
            Button {
                confirmPending(pending)
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
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.radius, style: .continuous)
                .stroke(Theme.hairline, lineWidth: 1)
        )
    }

    // MARK: - Mark as Returned

    private var markReturnedSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("CHANGED YOUR MIND?")
                .font(.system(.caption, design: .default, weight: .semibold))
                .tracking(1.2)
                .foregroundStyle(Theme.muted)
            Button {
                markAsReturned()
            } label: {
                Text("Mark as Returned")
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
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Notes

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("NOTES")
                .font(.system(.caption, design: .default, weight: .semibold))
                .tracking(1.2)
                .foregroundStyle(Theme.muted)
            TextField("Optional note", text: $notes, axis: .vertical)
                .font(.subheadline)
                .foregroundStyle(Theme.ink)
                .lineLimit(3, reservesSpace: true)
                .padding(10)
                .background(Theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: Theme.radius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.radius, style: .continuous)
                        .stroke(Theme.hairline, lineWidth: 1)
                )
        }
    }

    // MARK: - Actions

    private func confirmPending(_ pending: PendingReinforcement) {
        Haptics.impact()
        if var identity = IdentityStore.load() {
            identity = ReinforcementService.finalizePending(pending, to: identity)
            IdentityStore.save(identity)
        }
        PendingReinforcementStore.remove(id: pending.id)
        pendingConfirmed = true
        Haptics.success()
    }

    private func markAsReturned() {
        // Apply returned vote with no reason yet (user can pick reason in the grid if it appears)
        if var identity = IdentityStore.load() {
            let (updated, _) = ReinforcementService.applyTasteVote(
                vote: .returned,
                candidateEmbedding: evaluation.candidate.embedding,
                category: evaluation.furnitureCategory ?? .other,
                returnReason: nil,
                evaluationId: evaluation.id,
                to: identity
            )
            identity = updated
            IdentityStore.save(identity)
        }
        // Cancel any pending record if it exists
        PendingReinforcementStore.removeAll(for: evaluation.id)

        var updated = evaluation
        updated.tasteVote = .returned
        onSave(updated)
        dismiss()
    }

    private func saveAndDismiss() {
        var updated = evaluation
        updated.returnReason = selectedReturnReason
        updated.notes = notes.isEmpty ? nil : notes

        // If return reason was added to an existing .returned vote, apply style learning
        if evaluation.tasteVote == .returned,
           evaluation.returnReason == nil,
           let reason = selectedReturnReason, reason.affectsStyleLearning,
           var identity = IdentityStore.load() {
            let (updatedIdentity, _) = ReinforcementService.applyTasteVote(
                vote: .returned,
                candidateEmbedding: evaluation.candidate.embedding,
                category: evaluation.furnitureCategory ?? .other,
                returnReason: reason,
                evaluationId: evaluation.id,
                to: identity
            )
            identity = updatedIdentity
            IdentityStore.save(identity)
        }

        onSave(updated)
        dismiss()
    }
}
