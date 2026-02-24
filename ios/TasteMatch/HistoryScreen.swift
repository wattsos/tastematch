import SwiftUI

struct HistoryScreen: View {
    @Binding var path: NavigationPath
    @State private var events: [TasteEvent] = []
    @State private var selectedEvent: TasteEvent?

    var body: some View {
        Group {
            if events.isEmpty {
                emptyState
            } else {
                eventList
            }
        }
        .navigationTitle("HISTORY")
        .navigationBarTitleDisplayMode(.inline)
        .tint(Theme.accent)
        .onAppear {
            events = TasteEventStore.loadAll().reversed()
        }
        .sheet(item: $selectedEvent) { event in
            NavigationStack {
                ItemEvaluationScreen(
                    path: .constant(NavigationPath()),
                    evaluation: event.evaluation,
                    candidateVector: .zero,
                    readOnly: true
                )
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") { selectedEvent = nil }
                            .foregroundStyle(Theme.ink)
                    }
                }
            }
        }
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
            Text("Scan items and record your decisions to build your identity.")
                .font(.subheadline)
                .foregroundStyle(Theme.muted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
    }

    // MARK: - Event List

    private var eventList: some View {
        List {
            ForEach(events) { event in
                Button {
                    selectedEvent = event
                } label: {
                    eventRow(event)
                }
                .foregroundStyle(.primary)
            }
        }
        .listStyle(.plain)
    }

    private func eventRow(_ event: TasteEvent) -> some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(ScoringService.alignmentLabel(event.alignmentScore))
                    .font(.system(.subheadline, design: .default, weight: .semibold))
                    .tracking(1.0)
                    .foregroundStyle(Theme.ink)
                Text(formatted(event.timestamp))
                    .font(.caption2)
                    .foregroundStyle(Theme.muted)
            }

            Spacer()

            if !event.tensionFlags.isEmpty {
                Text("\(event.tensionFlags.count)T")
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

            Text(actionLabel(event.action))
                .font(.caption2)
                .tracking(0.8)
                .foregroundStyle(Theme.muted)

            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(Theme.muted.opacity(0.5))
        }
        .padding(.vertical, 4)
    }

    // MARK: - Helpers

    private func actionLabel(_ action: TasteAction) -> String {
        switch action {
        case .bought:    return "BOUGHT"
        case .rejected:  return "PASSED"
        case .regretted: return "REGRET"
        }
    }

    private func formatted(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
