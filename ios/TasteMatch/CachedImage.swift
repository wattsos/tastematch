import SwiftUI

// MARK: - Image Cache

final class ImageCache {
    static let shared = ImageCache()

    private let cache = NSCache<NSURL, UIImage>()

    private init() {
        cache.countLimit = 200
    }

    func image(for url: URL) -> UIImage? {
        cache.object(forKey: url as NSURL)
    }

    func store(_ image: UIImage, for url: URL) {
        cache.setObject(image, forKey: url as NSURL)
    }

    /// Exposed for testing: set a custom count limit.
    func setCountLimit(_ limit: Int) {
        cache.countLimit = limit
    }

    func removeAll() {
        cache.removeAllObjects()
    }
}

// MARK: - Image Loader

@MainActor
final class ImageLoader: ObservableObject {
    enum State {
        case loading
        case loaded(UIImage)
        case failed
    }

    @Published var state: State = .loading

    private let urlString: String?
    private var task: Task<Void, Never>?

    init(urlString: String?) {
        self.urlString = urlString
    }

    func load() {
        guard let urlString, let url = URL(string: urlString) else {
            state = .failed
            return
        }

        if let cached = ImageCache.shared.image(for: url) {
            state = .loaded(cached)
            return
        }

        task = Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                guard let image = UIImage(data: data) else {
                    #if DEBUG
                    print("[CachedImage] decode failed: \(url.host ?? url.absoluteString)")
                    #endif
                    state = .failed
                    return
                }
                ImageCache.shared.store(image, for: url)
                state = .loaded(image)
            } catch {
                #if DEBUG
                print("[CachedImage] load failed: \(url.host ?? url.absoluteString) — \(error.localizedDescription)")
                #endif
                state = .failed
            }
        }
    }

    func cancel() {
        task?.cancel()
    }
}

// MARK: - CachedImage View

struct CachedImage: View {
    let url: String?
    let height: CGFloat
    var width: CGFloat? = nil

    @StateObject private var loader: ImageLoader

    init(url: String?, height: CGFloat, width: CGFloat? = nil) {
        self.url = url
        self.height = height
        self.width = width
        _loader = StateObject(wrappedValue: ImageLoader(urlString: url))
    }

    var body: some View {
        content
            .frame(width: width, height: height)
            .clipped()
            .task(id: url) {
                loader.load()
            }
    }

    @ViewBuilder
    private var content: some View {
        switch loader.state {
        case .loading:
            shimmerPlaceholder
        case .loaded(let uiImage):
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
        case .failed:
            failurePlaceholder
        }
    }

    // MARK: - Shimmer

    private var shimmerPlaceholder: some View {
        Theme.surface
            .overlay(ShimmerOverlay())
    }

    // MARK: - Failure

    private var failurePlaceholder: some View {
        Color(white: 0.94)
            .overlay(
                VStack(spacing: 4) {
                    Image(systemName: "photo.badge.exclamationmark")
                        .font(.title3)
                        .foregroundStyle(Theme.muted.opacity(0.4))
                    Text("Image unavailable")
                        .font(.caption2)
                        .foregroundStyle(Theme.muted)
                }
            )
    }
}

// MARK: - Shimmer Overlay

private struct ShimmerOverlay: View {
    @State private var phase: CGFloat = -1

    var body: some View {
        GeometryReader { geo in
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0),
                    .init(color: Color(white: 0.94).opacity(0.6), location: 0.5),
                    .init(color: .clear, location: 1)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: geo.size.width * 1.5)
            .offset(x: phase * geo.size.width)
            .onAppear {
                withAnimation(
                    .linear(duration: 1.2)
                    .repeatForever(autoreverses: false)
                ) {
                    phase = 1.5
                }
            }
        }
        .clipped()
    }
}
