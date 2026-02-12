import PhotosUI
import SwiftUI

struct UploadScreen: View {
    @Binding var path: NavigationPath
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var images: [UIImage] = []
    @State private var isLoading = false
    @State private var loadError = false

    var body: some View {
        VStack(spacing: 24) {
            if images.isEmpty {
                emptyState
            } else {
                photoGrid
            }

            Spacer()

            Button {
                EventLogger.shared.logEvent("photos_confirmed", metadata: ["count": "\(images.count)"])
                path.append(Route.context(images))
            } label: {
                Text("Next")
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
            .disabled(images.isEmpty || isLoading)
        }
        .padding()
        .navigationTitle("Upload")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    path.append(Route.settings)
                } label: {
                    Image(systemName: "gearshape")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 16) {
                    Button {
                        path.append(Route.favorites)
                    } label: {
                        Image(systemName: "heart")
                    }
                    Button {
                        path.append(Route.history)
                    } label: {
                        Image(systemName: "clock.arrow.circlepath")
                    }
                }
            }
        }
        .alert("Unable to Load Photos", isPresented: $loadError) {
            Button("OK") {}
        } message: {
            Text("The selected photos couldn't be loaded. Please try again with different images.")
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "camera.viewfinder")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)

            Text("Show us your space")
                .font(.title2.weight(.semibold))

            Text("Select up to 5 photos of your room. We'll analyze your style and recommend pieces that fit.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            photoPicker

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
                                    .shadow(radius: 2)
                            }
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
                    photoPicker
                }
            }
            .padding(.horizontal)
        }
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
                .background(.thinMaterial)
                .cornerRadius(10)
        }
        .onChange(of: selectedItems) {
            Task { await loadImages() }
        }
    }

    // MARK: - Actions

    private func removePhoto(at index: Int) {
        guard images.indices.contains(index) else { return }
        images.remove(at: index)
        // Keep selectedItems in sync — remove corresponding picker item
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
