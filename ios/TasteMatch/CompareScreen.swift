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
                Section("Tag Comparison") {
                    tagComparison(a: a.tasteProfile, b: b.tasteProfile)
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
                        Text(profile.tasteProfile.tags.first?.label ?? "Unknown")
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

    // MARK: - Tag Comparison

    @ViewBuilder
    private func tagComparison(a: TasteProfile, b: TasteProfile) -> some View {
        let allKeys = orderedTagKeys(a: a, b: b)

        ForEach(allKeys, id: \.self) { key in
            let tagA = a.tags.first(where: { $0.key == key })
            let tagB = b.tags.first(where: { $0.key == key })
            let label = tagA?.label ?? tagB?.label ?? key

            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Theme.espresso)
                HStack(spacing: 12) {
                    confidenceBar(value: tagA?.confidence, label: "A")
                    confidenceBar(value: tagB?.confidence, label: "B")
                    shiftIndicator(
                        from: tagA?.confidence ?? 0,
                        to: tagB?.confidence ?? 0
                    )
                }
            }
            .padding(.vertical, 2)
        }
    }

    @ViewBuilder
    private func confidenceBar(value: Double?, label: String) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.caption2.weight(.semibold))
                .frame(width: 14)
            if let value {
                ProgressView(value: value)
                    .tint(Theme.accent)
                    .frame(width: 60)
                Text("\(Int(value * 100))%")
                    .font(.caption2.monospacedDigit())
                    .frame(width: 32, alignment: .trailing)
            } else {
                Text("—")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .frame(width: 92)
            }
        }
    }

    @ViewBuilder
    private func shiftIndicator(from: Double, to: Double) -> some View {
        let delta = to - from
        if abs(delta) < 0.01 {
            Text("=")
                .font(.caption2)
                .foregroundStyle(.secondary)
        } else {
            let arrow = delta > 0 ? "arrow.up.right" : "arrow.down.right"
            let color: Color = delta > 0 ? Theme.sage : Theme.rose
            HStack(spacing: 2) {
                Image(systemName: arrow)
                    .font(.caption2)
                Text("\(Int(abs(delta) * 100))%")
                    .font(.caption2.monospacedDigit())
            }
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

    private func orderedTagKeys(a: TasteProfile, b: TasteProfile) -> [String] {
        var seen = Set<String>()
        var keys: [String] = []
        for tag in a.tags + b.tags {
            if seen.insert(tag.key).inserted {
                keys.append(tag.key)
            }
        }
        return keys
    }

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
                            VStack(alignment: .leading, spacing: 2) {
                                Text(saved.tasteProfile.tags.first?.label ?? "Unknown")
                                    .font(.body.weight(.medium))
                                if let secondary = saved.tasteProfile.tags.dropFirst().first {
                                    Text(secondary.label)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
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
