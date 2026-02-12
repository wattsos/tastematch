import SwiftUI

struct ContextScreen: View {
    @Binding var path: NavigationPath
    let images: [UIImage]

    @State private var selectedRoom: RoomContext
    @State private var selectedGoal: DesignGoal

    init(path: Binding<NavigationPath>, images: [UIImage], initialRoom: RoomContext = .livingRoom, initialGoal: DesignGoal = .refresh) {
        _path = path
        self.images = images
        _selectedRoom = State(initialValue: initialRoom)
        _selectedGoal = State(initialValue: initialGoal)
    }

    @State private var isAnalyzing = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
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
                        Text("Analyze My Taste")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isAnalyzing ? Theme.blush : Theme.accent)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(isAnalyzing)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                }
            }

            if isAnalyzing {
                AnalyzingView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isAnalyzing)
        .navigationTitle("Context")
        .tint(Theme.accent)
        .alert("Analysis Failed", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "An unexpected error occurred.")
        }
    }

    private func analyze() async {
        isAnalyzing = true
        defer { isAnalyzing = false }

        Haptics.impact()
        EventLogger.shared.logEvent(
            "analyze_started",
            metadata: ["room": selectedRoom.rawValue, "goal": selectedGoal.rawValue]
        )

        let imageData = images.compactMap { $0.jpegData(compressionQuality: 0.8) }

        guard !imageData.isEmpty else {
            errorMessage = "None of the selected photos could be processed. Please try different images."
            return
        }

        do {
            let response = try await APIClient.shared.analyze(
                imageData: imageData,
                roomContext: selectedRoom,
                goal: selectedGoal
            )
            ProfileStore.save(profile: response.tasteProfile, recommendations: response.recommendations, roomContext: selectedRoom, designGoal: selectedGoal)
            Haptics.success()
            path.append(Route.result(response.tasteProfile, response.recommendations))
        } catch {
            errorMessage = error.localizedDescription
            EventLogger.shared.logEvent("analyze_failed", metadata: ["error": error.localizedDescription])
        }
    }
}
