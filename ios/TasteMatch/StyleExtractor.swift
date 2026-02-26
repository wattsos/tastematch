import UIKit

/// Deterministic extraction of StyleSignals from UIImage(s) via CoreGraphics pixel analysis.
enum StyleExtractor {

    private static let tileSize = 64

    // MARK: - Public

    static func extract(from image: UIImage) -> StyleSignals {
        let pixels = render(image)
        return compute(pixels)
    }

    /// Averages signals across multiple images. Returns neutral signals if empty.
    static func extract(from images: [UIImage]) -> StyleSignals {
        guard !images.isEmpty else { return .neutral }
        let all = images.map { extract(from: $0) }
        let n = Double(all.count)
        return StyleSignals(
            brightness:          all.map(\.brightness).reduce(0, +) / n,
            contrast:            all.map(\.contrast).reduce(0, +) / n,
            saturation:          all.map(\.saturation).reduce(0, +) / n,
            warmth:              all.map(\.warmth).reduce(0, +) / n,
            edgeDensity:         all.map(\.edgeDensity).reduce(0, +) / n,
            symmetry:            all.map(\.symmetry).reduce(0, +) / n,
            clutter:             all.map(\.clutter).reduce(0, +) / n,
            materialHardness:    all.map(\.materialHardness).reduce(0, +) / n,
            organicVsIndustrial: all.map(\.organicVsIndustrial).reduce(0, +) / n,
            ornateVsMinimal:     all.map(\.ornateVsMinimal).reduce(0, +) / n,
            vintageVsModern:     all.map(\.vintageVsModern).reduce(0, +) / n
        )
    }

    // MARK: - Render to 64×64 RGBA buffer

    private static func render(_ image: UIImage) -> [UInt8] {
        let size = tileSize
        var buf = [UInt8](repeating: 0, count: size * size * 4)
        guard let cgImage = image.cgImage,
              let ctx = CGContext(
                data: &buf,
                width: size, height: size,
                bitsPerComponent: 8, bytesPerRow: size * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
              ) else { return buf }
        ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: size, height: size))
        return buf
    }

    // MARK: - Compute all signals from pixel buffer

    private static func compute(_ buf: [UInt8]) -> StyleSignals {
        let size = tileSize
        let n = size * size
        var lum = [Double](repeating: 0, count: n)
        var r   = [Double](repeating: 0, count: n)
        var b   = [Double](repeating: 0, count: n)
        var sat = [Double](repeating: 0, count: n)

        for i in 0..<n {
            let ri = Double(buf[i * 4])     / 255.0
            let gi = Double(buf[i * 4 + 1]) / 255.0
            let bi = Double(buf[i * 4 + 2]) / 255.0
            r[i] = ri; b[i] = bi
            lum[i] = 0.299 * ri + 0.587 * gi + 0.114 * bi
            let mx = max(ri, gi, bi); let mn = min(ri, gi, bi)
            sat[i] = mx > 0 ? (mx - mn) / mx : 0.0
        }

        let meanLum = lum.reduce(0, +) / Double(n)
        let brightness = clamp(meanLum)

        let rmsContrast = sqrt(lum.map { ($0 - meanLum) * ($0 - meanLum) }.reduce(0, +) / Double(n))
        let contrast = clamp(rmsContrast * 4.0)   // scale ~0..0.25 → 0..1

        let saturation = clamp(sat.reduce(0, +) / Double(n))

        let meanR = r.reduce(0, +) / Double(n)
        let meanB = b.reduce(0, +) / Double(n)
        let warmth = clamp((meanR - meanB + 1.0) / 2.0)   // 0=cool, 1=warm

        // Sobel edge density
        var edgeSum = 0.0
        for row in 1..<(size - 1) {
            for col in 1..<(size - 1) {
                let p: (Int, Int) -> Double = { lum[$0 * size + $1] }
                let gx = -p(row-1, col-1) + p(row-1, col+1)
                       - 2*p(row, col-1)  + 2*p(row, col+1)
                       - p(row+1, col-1)  + p(row+1, col+1)
                let gy = -p(row-1, col-1) - 2*p(row-1, col) - p(row-1, col+1)
                       +  p(row+1, col-1) + 2*p(row+1, col) + p(row+1, col+1)
                edgeSum += sqrt(gx * gx + gy * gy)
            }
        }
        let edgeDensity = clamp(edgeSum / Double((size - 2) * (size - 2)) / 2.0)

        // Left-right symmetry (Pearson r)
        let half = size / 2
        var leftCol  = [Double](); leftCol.reserveCapacity(half * size)
        var rightCol = [Double](); rightCol.reserveCapacity(half * size)
        for row in 0..<size {
            for col in 0..<half {
                leftCol.append(lum[row * size + col])
                rightCol.append(lum[row * size + (size - 1 - col)])
            }
        }
        let symmetry = clamp((pearson(leftCol, rightCol) + 1.0) / 2.0)

        // Clutter: mean local variance over 4×4 patches
        let patchSize = 4
        var totalVar = 0.0; var patches = 0
        var pr = 0
        while pr < size - patchSize {
            var pc = 0
            while pc < size - patchSize {
                var vals = [Double]()
                for ri in pr..<(pr + patchSize) {
                    for ci in pc..<(pc + patchSize) { vals.append(lum[ri * size + ci]) }
                }
                let mean = vals.reduce(0, +) / Double(vals.count)
                totalVar += vals.map { ($0 - mean) * ($0 - mean) }.reduce(0, +) / Double(vals.count)
                patches += 1
                pc += patchSize
            }
            pr += patchSize
        }
        let clutter = clamp((totalVar / Double(max(1, patches))) * 10.0)

        // Derived signals
        let materialHardness    = clamp(edgeDensity * 0.6 + (1.0 - warmth) * 0.4)
        let organicVsIndustrial = clamp(warmth * 0.5 + (1.0 - edgeDensity) * 0.5)
        let ornateVsMinimal     = clamp(clutter * 0.6 + edgeDensity * 0.4)
        let vintageVsModern     = clamp(warmth * 0.4 + (1.0 - saturation) * 0.3 + (1.0 - contrast) * 0.3)

        return StyleSignals(
            brightness: brightness, contrast: contrast,
            saturation: saturation, warmth: warmth,
            edgeDensity: edgeDensity, symmetry: symmetry, clutter: clutter,
            materialHardness: materialHardness, organicVsIndustrial: organicVsIndustrial,
            ornateVsMinimal: ornateVsMinimal, vintageVsModern: vintageVsModern
        )
    }

    // MARK: - Helpers

    private static func clamp(_ v: Double) -> Double { max(0.0, min(1.0, v)) }

    private static func pearson(_ a: [Double], _ b: [Double]) -> Double {
        let n = Double(a.count)
        let meanA = a.reduce(0, +) / n
        let meanB = b.reduce(0, +) / n
        var cov = 0.0, varA = 0.0, varB = 0.0
        for i in 0..<a.count {
            let da = a[i] - meanA, db = b[i] - meanB
            cov += da * db; varA += da * da; varB += db * db
        }
        let denom = sqrt(varA * varB)
        return denom > 0 ? cov / denom : 0.0
    }
}
