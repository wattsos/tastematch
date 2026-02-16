import PhotosUI
import SwiftUI

struct UploadScreen: View {
    @Binding var path: NavigationPath
    var prefillRoom: RoomContext = .livingRoom
    var prefillGoal: DesignGoal = .refresh
    var domain: TasteDomain = DomainPreferencesStore.primaryDomain

    @State private var selectedDomain: TasteDomain
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var images: [UIImage] = []
    @State private var isLoading = false
    @State private var loadError = false
    @State private var showCamera = false
    @State private var retentionStats = RetentionStats()

    private var enabledDomains: [TasteDomain] {
        let enabled = DomainPreferencesStore.enabledDomains
        return TasteDomain.allCases.filter { enabled.contains($0) }
    }

    init(path: Binding<NavigationPath>, prefillRoom: RoomContext = .livingRoom, prefillGoal: DesignGoal = .refresh, domain: TasteDomain = DomainPreferencesStore.primaryDomain) {
        self._path = path
        self.prefillRoom = prefillRoom
        self.prefillGoal = prefillGoal
        self.domain = domain
        self._selectedDomain = State(initialValue: domain)
    }

    private struct DomainCopy {
        let headline: String
        let subtitle: String
    }

    private var domainCopy: DomainCopy {
        switch selectedDomain {
        case .space:
            return DomainCopy(headline: "Show us your space", subtitle: "Upload a few photos of a room. We'll read materials, light, and layout.")
        case .objects:
            return DomainCopy(headline: "Show us your objects", subtitle: "Upload watches, bags, accessories, shoes, or favorite pieces you own.")
        case .art:
            return DomainCopy(headline: "Show us your walls", subtitle: "Upload your walls + art you love. We'll map your collection taste.")
        }
    }

    var body: some View {
        VStack(spacing: 24) {
            if retentionStats.decisions > 0 {
                retentionHUD
            }

            // Show last result if user has a previous analysis
            if images.isEmpty, let latest = ProfileStore.loadLatest() {
                lastResultCard(latest)
            }

            if images.isEmpty {
                emptyState
            } else {
                photoGrid
            }

            Spacer()

            // Primary action button
            Button {
                EventLogger.shared.logEvent("photos_confirmed", metadata: ["count": "\(images.count)"])
                if selectedDomain == .space {
                    path.append(Route.context(images, prefillRoom, prefillGoal, selectedDomain))
                } else {
                    Task { await analyzeDirect() }
                }
            } label: {
                Text("Next")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .foregroundStyle(.white)
            .background(images.isEmpty || isLoading ? Theme.blush : Theme.accent)
            .clipShape(RoundedRectangle(cornerRadius: Theme.radius))
            .disabled(images.isEmpty || isLoading)
        }
        .padding()
        .navigationTitle("Upload")
        .alert("Unable to Load Photos", isPresented: $loadError) {
            Button("OK") {}
        } message: {
            Text("The selected photos couldn't be loaded. Please try again with different images.")
        }
        .onAppear { retentionStats = RetentionStats.compute() }
        .onReceive(NotificationCenter.default.publisher(for: DecisionStore.didRecord)) { _ in
            retentionStats = RetentionStats.compute()
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker { image in
                if images.count < 5 {
                    images.append(image)
                }
            }
            .ignoresSafeArea()
        }
    }

    // MARK: - Retention HUD

    private var retentionHUD: some View {
        HStack(spacing: 0) {
            hudStat(value: "\(retentionStats.streak)", label: "STREAK")
            hudDivider
            hudStat(value: "\(retentionStats.clarity)%", label: "CLARITY")
            hudDivider
            hudStat(value: "\(retentionStats.decisions)", label: "DECISIONS")
        }
        .padding(.vertical, 12)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.radius, style: .continuous)
                .stroke(Theme.hairline, lineWidth: 1)
        )
    }

    private func hudStat(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.subheadline.monospacedDigit().weight(.semibold))
                .foregroundStyle(Theme.ink)
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .tracking(0.8)
                .foregroundStyle(Theme.muted)
        }
        .frame(maxWidth: .infinity)
    }

    private var hudDivider: some View {
        Rectangle()
            .fill(Theme.hairline)
            .frame(width: 1, height: 28)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()

            if enabledDomains.count > 1 {
                Picker("Domain", selection: $selectedDomain) {
                    ForEach(enabledDomains) { d in Text(d.displayLabel).tag(d) }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 32)
            }

            Image(systemName: "camera.viewfinder")
                .font(.system(size: 56))
                .foregroundStyle(Theme.blush)

            Text(domainCopy.headline)
                .font(Theme.headlineFont)
                .foregroundStyle(Theme.espresso)

            Text(domainCopy.subtitle)
                .font(.subheadline)
                .foregroundStyle(Theme.clay)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            HStack(spacing: 12) {
                photoPicker
                cameraButton
            }

            // Demo button — lets users try the full flow without photos
            Button {
                runDemo()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "wand.and.stars")
                    Text("Try a Demo")
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Theme.accent)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Theme.accent.opacity(0.1))
                .clipShape(Capsule())
            }

            Spacer()
        }
    }

    // MARK: - Photo Grid

    private var photoGrid: some View {
        VStack(spacing: 12) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(images.enumerated()), id: \.offset) { index, img in
                        ZStack(alignment: .topTrailing) {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: 8))

                            Button {
                                removePhoto(at: index)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(.white)
                                    .shadow(color: .clear, radius: 0)
                            }
                            .accessibilityLabel("Remove photo \(index + 1)")
                            .offset(x: 6, y: -6)
                        }
                    }
                }
                .padding(.horizontal)
            }

            HStack {
                Text("\(images.count)/5 photo\(images.count == 1 ? "" : "s") selected")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                if images.count < 5 {
                    HStack(spacing: 8) {
                        photoPicker
                        cameraButton
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Camera Button

    private var cameraButton: some View {
        Button {
            showCamera = true
        } label: {
            Label("Take Photo", systemImage: "camera")
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Theme.blush.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: Theme.radius))
        }
        .disabled(images.count >= 5)
    }

    // MARK: - Shared Picker

    private var photoPicker: some View {
        PhotosPicker(
            selection: $selectedItems,
            maxSelectionCount: 5,
            matching: .images
        ) {
            Label(images.isEmpty ? "Select Photos" : "Add More", systemImage: "photo.on.rectangle.angled")
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Theme.blush.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: Theme.radius))
        }
        .onChange(of: selectedItems) {
            Task { await loadImages() }
        }
    }

    // MARK: - Last Result Card

    private func lastResultCard(_ saved: SavedProfile) -> some View {
        Button {
            path.append(Route.profile(saved.tasteProfile.id))
        } label: {
            HStack(spacing: 14) {
                if let primaryTag = saved.tasteProfile.tags.first {
                    TasteBadge(tagKey: primaryTag.key, size: .compact)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Your latest vibe")
                        .font(.system(.caption, design: .serif, weight: .semibold))
                        .foregroundStyle(Theme.clay)
                    Text(domainDisplayName(for: saved))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Theme.espresso)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Theme.blush)
            }
            .padding(14)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.radius))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.radius)
                    .stroke(Theme.hairline, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("View your latest taste profile")
    }

    private func domainDisplayName(for saved: SavedProfile) -> String {
        let profile = saved.tasteProfile
        let domain = saved.domain ?? .space
        let vector = TasteEngine.vectorFromProfile(profile)
        let axisScores = AxisMapping.computeAxisScores(from: vector)
        let basisHash = BasisHashBuilder.build(
            axisScores: axisScores, vector: vector,
            swipeCount: 0
        )

        switch domain {
        case .objects:
            if let record = ObjectCalibrationStore.load(for: profile.id) {
                let scores = ObjectAxisMapping.computeAxisScores(from: record.vector)
                return DomainNameDispatcher.generateObjects(objectScores: scores, basisHash: basisHash)
            }
            return DomainNameDispatcher.generate(axisScores: axisScores, basisHash: basisHash, domain: .objects)
        case .art:
            return DomainNameDispatcher.generate(axisScores: axisScores, basisHash: basisHash, domain: .art)
        case .space:
            return profile.displayName
        }
    }

    // MARK: - Demo Mode

    private func runDemo() {
        Haptics.impact()
        DomainStore.current = selectedDomain
        EventLogger.shared.logEvent("demo_started", metadata: ["domain": selectedDomain.rawValue])

        // Use preset signals that produce a nice Scandinavian + Japandi result
        let signals = VisualSignals(
            paletteTemperature: .cool,
            brightness: .high,
            contrast: .low,
            saturation: .muted,
            edgeDensity: .low,
            material: .wood
        )

        var profile = TasteEngine.analyze(
            signals: signals,
            context: .livingRoom,
            goal: .refresh
        )
        ProfileNamingEngine.applyInitialNaming(to: &profile)

        let catalog = DomainCatalog.items(for: selectedDomain)
        let recommendations = RecommendationEngine.recommend(
            profile: profile,
            catalog: catalog,
            context: .livingRoom,
            goal: .refresh,
            limit: 6
        )

        ProfileStore.save(
            profile: profile,
            recommendations: recommendations,
            roomContext: .livingRoom,
            designGoal: .refresh,
            domain: selectedDomain
        )
        DomainPreferencesStore.setLastViewed(domain: selectedDomain, for: profile.id)

        Haptics.success()
        path.append(Route.calibration(profile, recommendations, selectedDomain))
    }

    // MARK: - Direct Analysis (non-Space domains skip ContextScreen)

    private func analyzeDirect() async {
        isLoading = true
        defer { isLoading = false }

        Haptics.impact()
        DomainStore.current = selectedDomain
        EventLogger.shared.logEvent(
            "analyze_started",
            metadata: ["domain": selectedDomain.rawValue]
        )

        let imageData = images.compactMap { $0.jpegData(compressionQuality: 0.8) }
        guard !imageData.isEmpty else {
            loadError = true
            return
        }

        do {
            let response = try await APIClient.shared.analyze(
                imageData: imageData,
                roomContext: .livingRoom,
                goal: .refresh
            )
            var profile = response.tasteProfile
            ProfileNamingEngine.applyInitialNaming(to: &profile)

            let catalog = DomainCatalog.items(for: selectedDomain)
            let recommendations = RecommendationEngine.recommend(
                profile: profile,
                catalog: catalog,
                context: .livingRoom,
                goal: .refresh,
                limit: 6
            )

            ProfileStore.save(
                profile: profile,
                recommendations: recommendations,
                domain: selectedDomain
            )
            DomainPreferencesStore.setLastViewed(domain: selectedDomain, for: profile.id)

            Haptics.success()
            path.append(Route.calibration(profile, recommendations, selectedDomain))
        } catch {
            loadError = true
            EventLogger.shared.logEvent("analyze_failed", metadata: ["error": error.localizedDescription])
        }
    }

    // MARK: - Actions

    private func removePhoto(at index: Int) {
        guard images.indices.contains(index) else { return }
        images.remove(at: index)
        if selectedItems.indices.contains(index) {
            selectedItems.remove(at: index)
        }
    }

    private func loadImages() async {
        isLoading = true
        defer { isLoading = false }
        loadError = false
        var loaded: [UIImage] = []
        for item in selectedItems {
            if let data = try? await item.loadTransferable(type: Data.self),
               let img = UIImage(data: data) {
                loaded.append(img)
            }
        }
        images = loaded
        if loaded.isEmpty && !selectedItems.isEmpty {
            loadError = true
            selectedItems = []
        }
    }
}

// MARK: - Retention Stats

struct RetentionStats {
    var streak: Int = 0
    var clarity: Int = 0
    var decisions: Int = 0

    static func compute() -> RetentionStats {
        let events = DecisionStore.loadAll()
        let total = events.count
        var streak = 0
        for event in events.reversed() {
            if event.action == .aligned || event.action == .bought {
                streak += 1
            } else {
                break
            }
        }
        return RetentionStats(
            streak: streak,
            clarity: min(100, total * 2),
            decisions: total
        )
    }
}

// MARK: - Camera Picker

private struct CameraPicker: UIViewControllerRepresentable {
    var onCapture: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker
        init(_ parent: CameraPicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onCapture(image)
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
