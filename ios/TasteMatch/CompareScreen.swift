import SwiftUI

struct CompareScreen: View {
    @Binding var path: NavigationPath
    @State private var history: [SavedProfile] = []
    @State private var selectedA: SavedProfile?
    @State private var selectedB: SavedProfile?
    @State private var pickingSlot: PickingSlot?

    private enum PickingSlot: Identifiable {
        case a, b
        var id: String { self == .a ? "a" : "b" }
    }

    var body: some View {
        List {
            Section("Select Two Analyses") {
                slotButton(label: "First", profile: selectedA) {
                    pickingSlot = .a
                }
                slotButton(label: "Second", profile: selectedB) {
                    pickingSlot = .b
                }
            }

            if let a = selectedA, let b = selectedB {
                Section("Axis Profile") {
                    axisComparison(a: a.tasteProfile, b: b.tasteProfile)
                }

                Section("Signal Comparison") {
                    signalComparison(a: a.tasteProfile, b: b.tasteProfile)
                }
            }
        }
        .navigationTitle("Compare")
        .tint(Theme.accent)
        .onAppear {
            history = ProfileStore.loadAll()
        }
        .sheet(item: $pickingSlot) { slot in
            NavigationStack {
                ProfilePickerList(
                    history: history,
                    excluding: slot == .a ? selectedB?.id : selectedA?.id
                ) { chosen in
                    switch slot {
                    case .a: selectedA = chosen
                    case .b: selectedB = chosen
                    }
                    pickingSlot = nil
                }
                .navigationTitle("Pick Analysis")
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Cancel") { pickingSlot = nil }
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }

    // MARK: - Slot Button

    @ViewBuilder
    private func slotButton(label: String, profile: SavedProfile?, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.caption)
                        .foregroundStyle(Theme.clay)
                    if let profile {
                        Text(profile.tasteProfile.displayName)
                            .font(.body.weight(.medium))
                            .foregroundStyle(Theme.espresso)
                        Text(formatted(profile.savedAt))
                            .font(.caption2)
                            .foregroundStyle(Theme.clay)
                    } else {
                        Text("Tap to select")
                            .font(.body)
                            .foregroundStyle(Theme.clay)
                    }
                }
                Spacer()
                Image(systemName: profile == nil ? "plus.circle" : "checkmark.circle.fill")
                    .foregroundStyle(profile == nil ? Theme.clay : Theme.sage)
            }
        }
        .foregroundStyle(.primary)
    }

    // MARK: - Axis Comparison

    @ViewBuilder
    private func axisComparison(a: TasteProfile, b: TasteProfile) -> some View {
        let vectorA = TasteEngine.vectorFromProfile(a)
        let vectorB = TasteEngine.vectorFromProfile(b)
        let scoresA = AxisMapping.computeAxisScores(from: vectorA)
        let scoresB = AxisMapping.computeAxisScores(from: vectorB)

        ForEach(Axis.allCases, id: \.self) { axis in
            let valA = scoresA.value(for: axis)
            let valB = scoresB.value(for: axis)

            VStack(alignment: .leading, spacing: 4) {
                Text(AxisPresentation.axisDisplayLabel(axis))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Theme.espresso)
                HStack(spacing: 12) {
                    axisBar(value: valA, label: "A")
                    axisBar(value: valB, label: "B")
                    axisShiftIndicator(from: valA, to: valB)
                }
            }
            .padding(.vertical, 2)
        }
    }

    @ViewBuilder
    private func axisBar(value: Double, label: String) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.caption2.weight(.semibold))
                .frame(width: 14)
            // Map -1..+1 to 0..1 for display
            let normalized = (value + 1) / 2
            ProgressView(value: normalized)
                .tint(Theme.accent)
                .frame(width: 60)
            Text(String(format: "%+.1f", value))
                .font(.caption2.monospacedDigit())
                .foregroundStyle(Theme.muted)
                .frame(width: 32, alignment: .trailing)
        }
    }

    @ViewBuilder
    private func axisShiftIndicator(from: Double, to: Double) -> some View {
        let delta = to - from
        if abs(delta) < 0.05 {
            Text("=")
                .font(.caption2)
                .foregroundStyle(.secondary)
        } else {
            let arrow = delta > 0 ? "arrow.up.right" : "arrow.down.right"
            let color: Color = delta > 0 ? Theme.sage : Theme.rose
            Image(systemName: arrow)
                .font(.caption2)
                .foregroundStyle(color)
        }
    }

    // MARK: - Signal Comparison

    @ViewBuilder
    private func signalComparison(a: TasteProfile, b: TasteProfile) -> some View {
        let allKeys = orderedSignalKeys(a: a, b: b)

        ForEach(allKeys, id: \.self) { key in
            let sigA = a.signals.first(where: { $0.key == key })
            let sigB = b.signals.first(where: { $0.key == key })

            HStack {
                Text(key.replacingOccurrences(of: "_", with: " ").capitalized)
                    .font(.caption)
                    .foregroundStyle(Theme.clay)
                    .frame(width: 90, alignment: .leading)
                Spacer()
                Text(sigA?.value.capitalized ?? "—")
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, alignment: .center)
                Image(systemName: sigA?.value == sigB?.value ? "equal" : "arrow.right")
                    .font(.caption2)
                    .foregroundStyle(sigA?.value == sigB?.value ? Theme.clay : Theme.amber)
                Text(sigB?.value.capitalized ?? "—")
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }

    // MARK: - Helpers

    private func orderedSignalKeys(a: TasteProfile, b: TasteProfile) -> [String] {
        var seen = Set<String>()
        var keys: [String] = []
        for signal in a.signals + b.signals {
            if seen.insert(signal.key).inserted {
                keys.append(signal.key)
            }
        }
        return keys
    }

    private func formatted(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Profile Picker List

private struct ProfilePickerList: View {
    let history: [SavedProfile]
    let excluding: UUID?
    let onSelect: (SavedProfile) -> Void

    var body: some View {
        List {
            ForEach(history.reversed()) { saved in
                if saved.id != excluding {
                    Button {
                        onSelect(saved)
                    } label: {
                        HStack {
                            Text(saved.tasteProfile.displayName)
                                .font(.body.weight(.medium))
                            Spacer()
                            Text(formatted(saved.savedAt))
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .foregroundStyle(.primary)
                }
            }
        }
    }

    private func formatted(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
