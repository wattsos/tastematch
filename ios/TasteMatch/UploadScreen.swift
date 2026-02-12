import PhotosUI
import SwiftUI

struct UploadScreen: View {
    @Binding var path: NavigationPath
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var images: [UIImage] = []
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 24) {
            PhotosPicker(
                selection: $selectedItems,
                maxSelectionCount: 5,
                matching: .images
            ) {
                Label("Select Photos", systemImage: "photo.on.rectangle.angled")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.thinMaterial)
                    .cornerRadius(12)
            }
            .onChange(of: selectedItems) {
                Task { await loadImages() }
            }

            if !images.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(images.enumerated()), id: \.offset) { _, img in
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    .padding(.horizontal)
                }

                Text("\(images.count) photo\(images.count == 1 ? "" : "s") selected")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
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
    }

    private func loadImages() async {
        isLoading = true
        defer { isLoading = false }
        var loaded: [UIImage] = []
        for item in selectedItems {
            if let data = try? await item.loadTransferable(type: Data.self),
               let img = UIImage(data: data) {
                loaded.append(img)
            }
        }
        images = loaded
    }
}
