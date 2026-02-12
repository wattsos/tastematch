import SwiftUI

struct ContextScreen: View {
    @Binding var path: NavigationPath
    let images: [UIImage]

    @State private var selectedRoom: RoomContext = .livingRoom
    @State private var selectedGoal: DesignGoal = .refresh
    @State private var isAnalyzing = false

    var body: some View {
        Form {
            Section("Room") {
                Picker("Room type", selection: $selectedRoom) {
                    ForEach(RoomContext.allCases) { room in
                        Text(room.rawValue).tag(room)
                    }
                }
                .pickerStyle(.menu)
            }

            Section("Goal") {
                Picker("Design goal", selection: $selectedGoal) {
                    ForEach(DesignGoal.allCases) { goal in
                        Text(goal.rawValue).tag(goal)
                    }
                }
                .pickerStyle(.menu)
            }

            Section {
                Button {
                    Task { await analyze() }
                } label: {
                    if isAnalyzing {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Analyze My Taste")
                            .frame(maxWidth: .infinity)
                    }
                }
                .disabled(isAnalyzing)
            }
        }
        .navigationTitle("Context")
    }

    private func analyze() async {
        isAnalyzing = true
        defer { isAnalyzing = false }

        EventLogger.shared.logEvent(
            "analyze_started",
            metadata: ["room": selectedRoom.rawValue, "goal": selectedGoal.rawValue]
        )

        let imageData = images.compactMap { $0.jpegData(compressionQuality: 0.8) }

        do {
            let response = try await APIClient.shared.analyze(
                imageData: imageData,
                roomContext: selectedRoom,
                goal: selectedGoal
            )
            path.append(Route.result(response.tasteProfile, response.recommendations))
        } catch {
            EventLogger.shared.logEvent("analyze_failed", metadata: ["error": error.localizedDescription])
        }
    }
}
