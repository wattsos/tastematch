import SwiftUI

struct SettingsScreen: View {
    @Binding var path: NavigationPath
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true
    @State private var showClearConfirmation = false
    @State private var showClearFavoritesConfirmation = false
    @State private var showResetOnboardingConfirmation = false

    var body: some View {
        List {
            Section("Data") {
                Button(role: .destructive) {
                    showClearConfirmation = true
                } label: {
                    Label("Clear Profile History", systemImage: "trash")
                }
                .confirmationDialog("Clear all profile history?", isPresented: $showClearConfirmation, titleVisibility: .visible) {
                    Button("Clear All", role: .destructive) {
                        ProfileStore.clear()
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("This will permanently delete all saved analyses. This cannot be undone.")
                }

                Button(role: .destructive) {
                    showClearFavoritesConfirmation = true
                } label: {
                    Label("Clear Favorites", systemImage: "heart.slash")
                }
                .confirmationDialog("Clear all favorites?", isPresented: $showClearFavoritesConfirmation, titleVisibility: .visible) {
                    Button("Clear All", role: .destructive) {
                        FavoritesStore.clear()
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("This will remove all saved favorites. This cannot be undone.")
                }
            }

            Section("App") {
                Button {
                    showResetOnboardingConfirmation = true
                } label: {
                    Label("Show Onboarding Again", systemImage: "arrow.counterclockwise")
                }
                .foregroundStyle(.primary)
                .confirmationDialog("Reset onboarding?", isPresented: $showResetOnboardingConfirmation, titleVisibility: .visible) {
                    Button("Reset") {
                        hasCompletedOnboarding = false
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("The welcome screen will appear next time you open the app.")
                }
            }

            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text(appVersion)
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Build")
                    Spacer()
                    Text(buildNumber)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Settings")
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
}
