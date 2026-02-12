import SwiftUI

struct ResultScreen: View {
    let profile: TasteProfile
    let recommendations: [RecommendationItem]

    var body: some View {
        List {
            Section("Your Taste Tags") {
                ForEach(profile.tags) { tag in
                    HStack {
                        Text(tag.label)
                        Spacer()
                        Text("\(Int(tag.confidence * 100))%")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("Story") {
                Text(profile.story)
                    .font(.body)
            }

            Section("Signals") {
                ForEach(profile.signals) { signal in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(signal.key.replacingOccurrences(of: "_", with: " ").capitalized)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(signal.value)
                    }
                }
            }

            Section("Recommendations") {
                ForEach(recommendations) { item in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.title).font(.headline)
                        Text(item.subtitle).font(.subheadline).foregroundStyle(.secondary)
                        Text(item.reason).font(.caption)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Results")
        .onAppear {
            EventLogger.shared.logEvent("results_viewed", tasteProfileId: profile.id)
        }
    }
}
