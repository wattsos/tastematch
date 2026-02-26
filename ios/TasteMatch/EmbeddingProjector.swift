import Foundation

/// Maps an 11-dim StyleSignals vector to a 64-dim StyleEmbedding via a fixed
/// Gaussian random-projection matrix seeded with LCG seed 1337.
enum EmbeddingProjector {

    static let outputDim = StyleEmbedding.size   // 64
    static let inputDim  = StyleSignals.count    // 11

    // MARK: - Public API

    static func embed(_ signals: StyleSignals) -> StyleEmbedding {
        let v = signals.asVector
        var raw = [Double](repeating: 0.0, count: outputDim)
        for o in 0..<outputDim {
            var sum = 0.0
            for i in 0..<inputDim {
                sum += matrix[o][i] * v[i]
            }
            raw[o] = sum
        }
        return StyleEmbedding(dims: raw).normalized()
    }

    // MARK: - Fixed Projection Matrix (64 × 11)
    //
    // Generated once via seeded LCG (Knuth constants) + Box-Muller N(0,1).
    // The matrix is a compile-time constant — never changes between builds.

    static let matrix: [[Double]] = {
        var state: UInt64 = 1337

        func next() -> Double {
            // LCG: a=6364136223846793005, c=1442695040888963407 (Knuth)
            state = state &* 6364136223846793005 &+ 1442695040888963407
            return Double(state >> 33) / Double(UInt64(1) << 31)   // uniform [0,1)
        }

        func gaussian() -> Double {
            // Box-Muller: use first of the pair
            let u1 = max(1e-10, next())
            let u2 = next()
            return sqrt(-2.0 * log(u1)) * cos(2.0 * .pi * u2)
        }

        return (0..<64).map { _ in (0..<11).map { _ in gaussian() } }
    }()
}
