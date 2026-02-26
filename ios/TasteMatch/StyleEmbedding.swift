import Foundation

/// A 64-dimensional dense embedding of a visual style.
struct StyleEmbedding: Codable, Equatable {

    var dims: [Double]   // always length 64

    static let size = 64

    static var zero: StyleEmbedding {
        StyleEmbedding(dims: Array(repeating: 0.0, count: size))
    }

    init(dims: [Double]) {
        self.dims = dims
    }

    var isZero: Bool { dims.allSatisfy { abs($0) < 1e-9 } }

    // MARK: - Cosine Similarity

    func cosine(with other: StyleEmbedding) -> Double {
        var dot = 0.0, magA = 0.0, magB = 0.0
        for i in 0..<dims.count {
            dot  += dims[i] * other.dims[i]
            magA += dims[i] * dims[i]
            magB += other.dims[i] * other.dims[i]
        }
        let denom = sqrt(magA) * sqrt(magB)
        return denom > 0 ? dot / denom : 0.0
    }

    // MARK: - L2 Normalise

    func normalized() -> StyleEmbedding {
        var mag = 0.0
        for d in dims { mag += d * d }
        mag = sqrt(mag)
        guard mag > 1e-9 else { return .zero }
        return StyleEmbedding(dims: dims.map { $0 / mag })
    }

    // MARK: - Blend (exponential moving average toward target)

    mutating func blend(toward other: StyleEmbedding, weight w: Double) {
        let w = max(0.0, min(1.0, w))
        for i in 0..<dims.count {
            dims[i] = dims[i] * (1.0 - w) + other.dims[i] * w
        }
    }

    // MARK: - Decay (shrink toward zero)

    mutating func decay(by factor: Double) {
        let f = max(0.0, min(1.0, factor))
        for i in 0..<dims.count {
            dims[i] *= (1.0 - f)
        }
    }
}
