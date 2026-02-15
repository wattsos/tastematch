import SwiftUI

struct GoalSelectionScreen: View {
    @Binding var isPresented: Bool
    var onComplete: (() -> Void)?

    @State private var selected: Set<TasteDomain> = []
    private let isEditMode: Bool

    init(isPresented: Binding<Bool>, onComplete: (() -> Void)? = nil) {
        self._isPresented = isPresented
        self.onComplete = onComplete
        let enabled = DomainPreferencesStore.enabledDomains
        let editing = DomainPreferencesStore.isOnboardingComplete
        self.isEditMode = editing
        self._selected = State(initialValue: editing ? enabled : [])
    }

    private struct DomainOption {
        let domain: TasteDomain
        let label: String
        let subtitle: String
    }

    private let options: [DomainOption] = [
        DomainOption(domain: .space, label: "SPACE", subtitle: "Home + interiors."),
        DomainOption(domain: .objects, label: "OBJECTS", subtitle: "The things you carry, collect, and live with."),
        DomainOption(domain: .art, label: "ART", subtitle: "Work for your walls + collection direction."),
    ]

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 8) {
                Text("What are you defining\nyour taste for?")
                    .font(.system(.title2, design: .serif, weight: .bold))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            VStack(spacing: 12) {
                ForEach(options, id: \.domain) { option in
                    domainCard(option)
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            VStack(spacing: 12) {
                Button {
                    confirmSelection()
                } label: {
                    Text("Continue")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selected.isEmpty ? Theme.hairline : Theme.ink)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.radius))
                }
                .disabled(selected.isEmpty)

                if !isEditMode {
                    Button {
                        selected = [.space]
                        confirmSelection()
                    } label: {
                        Text("Skip for now")
                            .font(.subheadline)
                            .foregroundStyle(Theme.muted)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
        .background(Theme.bg.ignoresSafeArea())
    }

    private func domainCard(_ option: DomainOption) -> some View {
        let isSelected = selected.contains(option.domain)
        return Button {
            Haptics.tap()
            if isSelected {
                selected.remove(option.domain)
            } else {
                selected.insert(option.domain)
            }
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                Text(option.label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.ink)
                    .tracking(1.2)
                Text(option.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(Theme.muted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.radius, style: .continuous)
                    .stroke(isSelected ? Theme.ink : Theme.hairline, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func confirmSelection() {
        Haptics.impact()
        DomainPreferencesStore.setEnabled(selected)
        if isEditMode {
            isPresented = false
        }
        onComplete?()
    }
}
