import SwiftUI

struct SettingsScreen: View {
    @Binding var path: NavigationPath
    @EnvironmentObject private var advisorySettings: AdvisorySettings
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true
    @State private var showClearConfirmation = false
    @State private var showClearFavoritesConfirmation = false
    @State private var showResetOnboardingConfirmation = false
    @State private var showDomainSettings = false
    @State private var showIdentityDebug = false

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
                        Haptics.warning()
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
                        Haptics.warning()
                        FavoritesStore.clear()
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("This will remove all saved favorites. This cannot be undone.")
                }
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("ADVISORY")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.muted)
                        .tracking(1.2)

                    Picker("Guidance level", selection: $advisorySettings.level) {
                        ForEach(AdvisoryLevel.allCases, id: \.self) { level in
                            Text(level.displayName).tag(level)
                        }
                    }
                    .pickerStyle(.segmented)

                    Text(advisorySettings.level.helperText)
                        .font(.caption2)
                        .foregroundStyle(Theme.muted)
                }
            }

            Section("App") {
                Button {
                    showDomainSettings = true
                } label: {
                    HStack {
                        Label("Domains", systemImage: "square.grid.3x3")
                            .foregroundStyle(Theme.espresso)
                        Spacer()
                        Text(domainSummary)
                            .font(.subheadline)
                            .foregroundStyle(Theme.clay)
                    }
                }

                Button {
                    showResetOnboardingConfirmation = true
                } label: {
                    Label("Show Welcome Again", systemImage: "arrow.counterclockwise")
                        .foregroundStyle(Theme.espresso)
                }
                .confirmationDialog("Reset welcome screen?", isPresented: $showResetOnboardingConfirmation, titleVisibility: .visible) {
                    Button("Reset") {
                        hasCompletedOnboarding = false
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("The welcome screen will appear next time you open \(Brand.name).")
                }
            }

            Section("About") {
                NavigationLink(value: Route.about) {
                    Label("About \(Brand.name)", systemImage: "info.circle")
                        .foregroundStyle(Theme.espresso)
                }
                HStack {
                    Text("Version")
                        .foregroundStyle(Theme.espresso)
                    Spacer()
                    Text(appVersion)
                        .foregroundStyle(Theme.clay)
                }
                HStack {
                    Text("Build")
                        .foregroundStyle(Theme.espresso)
                    Spacer()
                    Text(buildNumber)
                        .foregroundStyle(Theme.clay)
                }
            }
        }
        Section("Developer") {
            Button {
                showIdentityDebug = true
            } label: {
                Label("Identity Debug", systemImage: "ladybug")
                    .foregroundStyle(Theme.muted)
            }
        }
        .navigationTitle("Settings")
        .tint(Theme.accent)
        .sheet(isPresented: $showDomainSettings) {
            GoalSelectionScreen(isPresented: $showDomainSettings)
        }
        .sheet(isPresented: $showIdentityDebug) {
            NavigationStack { IdentityDebugView() }
        }
    }

    private var domainSummary: String {
        let enabled = DomainPreferencesStore.enabledDomains
        let labels = TasteDomain.allCases.filter { enabled.contains($0) }.map(\.displayLabel)
        return labels.joined(separator: ", ")
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
}
