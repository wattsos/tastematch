import SwiftUI

struct ResultScreen: View {
    @Binding var path: NavigationPath
    let profile: TasteProfile
    let recommendations: [RecommendationItem]

    var body: some View {
        List {
            Section("Your Taste Tags") {
                ForEach(profile.tags) { tag in
                    HStack(spacing: 12) {
                        Text(tag.label)
                            .font(.body.weight(.medium))
                        Spacer()
                        ProgressView(value: tag.confidence)
                            .frame(width: 80)
                        Text("\(Int(tag.confidence * 100))%")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                            .frame(width: 36, alignment: .trailing)
                    }
                }
            }

            Section("Story") {
                Text(profile.story)
                    .font(.body)
                    .lineSpacing(3)
            }

            Section("Signals") {
                ForEach(profile.signals) { signal in
                    HStack {
                        Text(signal.key.replacingOccurrences(of: "_", with: " ").capitalized)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(width: 120, alignment: .leading)
                        Spacer()
                        Text(signal.value.capitalized)
                            .font(.body)
                    }
                }
            }

            Section("Recommendations") {
                ForEach(recommendations) { item in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(item.title)
                                .font(.headline)
                            Spacer()
                            Text(confidenceLabel(item.attributionConfidence))
                                .font(.caption2.weight(.medium))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(confidenceColor(item.attributionConfidence).opacity(0.15))
                                .foregroundStyle(confidenceColor(item.attributionConfidence))
                                .clipShape(Capsule())
                        }
                        Text(item.subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(item.reason)
                            .font(.callout)
                            .italic()
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Results")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Start Over") {
                    ProfileStore.clear()
                    path = NavigationPath()
                }
                .font(.subheadline)
            }
        }
        .onAppear {
            EventLogger.shared.logEvent("results_viewed", tasteProfileId: profile.id)
        }
    }

    // MARK: - Attribution Helpers

    private func confidenceLabel(_ value: Double) -> String {
        switch value {
        case 0.8...: return "Strong match"
        case 0.5...: return "Good match"
        default:     return "Partial match"
        }
    }

    private func confidenceColor(_ value: Double) -> Color {
        switch value {
        case 0.8...: return .green
        case 0.5...: return .orange
        default:     return .secondary
        }
    }
}
