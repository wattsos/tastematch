import Foundation
import UIKit
import CoreGraphics

/// Extracts `VisualSignals` from raw image data using deterministic pixel sampling.
/// Falls back to neutral defaults if the image cannot be decoded.
enum SignalExtractor {

    // MARK: - Public

    /// Analyze all decodable images in `imageData` and return aggregated visual signals.
    /// Pixels from every image are pooled for color/brightness metrics.
    /// Edge density is computed per-image (grid-dependent) then averaged.
    static func extract(from imageData: [Data]) -> VisualSignals {
        var allPixels: [RGB] = []
        var perImageEdge: [EdgeDensity] = []

        for data in imageData {
            guard let image = UIImage(data: data),
                  let cgImage = image.cgImage else { continue }
            let pixels = samplePixels(from: cgImage, gridSize: 8)
            guard !pixels.isEmpty else { continue }
            allPixels.append(contentsOf: pixels)
            perImageEdge.append(edgeDensityLevel(pixels, gridSize: 8))
        }

        guard !allPixels.isEmpty else { return defaults }

        let brightness = averageBrightness(allPixels)
        let temperature = paletteTemperature(allPixels)
        let contrast = contrastLevel(allPixels, averageBrightness: brightness)
        let saturation = saturationLevel(allPixels)
        let edgeDensity = averageEdgeDensity(perImageEdge)
        let material = estimateMaterial(temperature: temperature, saturation: saturation, brightness: brightness)

        return VisualSignals(
            paletteTemperature: temperature,
            brightness: toBrightness(brightness),
            contrast: contrast,
            saturation: saturation,
            edgeDensity: edgeDensity,
            material: material
        )
    }

    // MARK: - Defaults

    static let defaults = VisualSignals(
        paletteTemperature: .neutral,
        brightness: .medium,
        contrast: .medium,
        saturation: .neutral,
        edgeDensity: .medium,
        material: .mixed
    )
}

// MARK: - Pixel Sampling

private extension SignalExtractor {

    struct RGB {
        let r: Double
        let g: Double
        let b: Double

        var brightness: Double { (r + g + b) / 3.0 }
        var maxComponent: Double { max(r, max(g, b)) }
        var minComponent: Double { min(r, min(g, b)) }
        var saturation: Double {
            let mx = maxComponent
            guard mx > 0 else { return 0 }
            return (mx - minComponent) / mx
        }
    }

    /// Sample an NxN grid of pixels from the image. Returns RGB values normalized to 0–1.
    static func samplePixels(from cgImage: CGImage, gridSize: Int) -> [RGB] {
        let width = cgImage.width
        let height = cgImage.height

        guard width > 0, height > 0 else { return [] }

        // Render into a known RGBA8 bitmap for consistent byte layout.
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        var rawData = [UInt8](repeating: 0, count: height * bytesPerRow)

        guard let colorSpace = cgImage.colorSpace ?? CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(
                  data: &rawData,
                  width: width,
                  height: height,
                  bitsPerComponent: 8,
                  bytesPerRow: bytesPerRow,
                  space: colorSpace,
                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
              ) else {
            return []
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        var pixels: [RGB] = []
        pixels.reserveCapacity(gridSize * gridSize)

        let stepX = max(1, width / gridSize)
        let stepY = max(1, height / gridSize)

        for row in 0..<gridSize {
            let y = min(row * stepY, height - 1)
            for col in 0..<gridSize {
                let x = min(col * stepX, width - 1)
                let offset = (y * bytesPerRow) + (x * bytesPerPixel)
                let r = Double(rawData[offset]) / 255.0
                let g = Double(rawData[offset + 1]) / 255.0
                let b = Double(rawData[offset + 2]) / 255.0
                pixels.append(RGB(r: r, g: g, b: b))
            }
        }

        return pixels
    }
}

// MARK: - Signal Computation

private extension SignalExtractor {

    // -- Brightness --

    static func averageBrightness(_ pixels: [RGB]) -> Double {
        pixels.reduce(0.0) { $0 + $1.brightness } / Double(pixels.count)
    }

    static func toBrightness(_ avg: Double) -> Brightness {
        switch avg {
        case ..<0.35:  return .low
        case 0.35..<0.65: return .medium
        default:       return .high
        }
    }

    // -- Palette Temperature --
    // Warm if reds dominate, cool if blues dominate, neutral otherwise.

    static func paletteTemperature(_ pixels: [RGB]) -> PaletteTemperature {
        let avgR = pixels.reduce(0.0) { $0 + $1.r } / Double(pixels.count)
        let avgB = pixels.reduce(0.0) { $0 + $1.b } / Double(pixels.count)
        let diff = avgR - avgB

        switch diff {
        case 0.05...:    return .warm
        case ..<(-0.05): return .cool
        default:         return .neutral
        }
    }

    // -- Contrast --
    // Standard deviation of pixel brightness. High stddev → high contrast.

    static func contrastLevel(_ pixels: [RGB], averageBrightness avg: Double) -> Contrast {
        let variance = pixels.reduce(0.0) { $0 + pow($1.brightness - avg, 2) } / Double(pixels.count)
        let stddev = sqrt(variance)

        switch stddev {
        case ..<0.12:  return .low
        case 0.12..<0.22: return .medium
        default:       return .high
        }
    }

    // -- Saturation --

    static func saturationLevel(_ pixels: [RGB]) -> Saturation {
        let avgSat = pixels.reduce(0.0) { $0 + $1.saturation } / Double(pixels.count)

        switch avgSat {
        case ..<0.15:  return .muted
        case 0.15..<0.4: return .neutral
        default:       return .vivid
        }
    }

    // -- Edge Density --
    // Measure average brightness delta between adjacent grid samples.

    static func edgeDensityLevel(_ pixels: [RGB], gridSize: Int) -> EdgeDensity {
        var totalDelta = 0.0
        var comparisons = 0

        for row in 0..<gridSize {
            for col in 0..<gridSize {
                let idx = row * gridSize + col
                // Right neighbor
                if col + 1 < gridSize {
                    let right = row * gridSize + col + 1
                    totalDelta += abs(pixels[idx].brightness - pixels[right].brightness)
                    comparisons += 1
                }
                // Bottom neighbor
                if row + 1 < gridSize {
                    let below = (row + 1) * gridSize + col
                    totalDelta += abs(pixels[idx].brightness - pixels[below].brightness)
                    comparisons += 1
                }
            }
        }

        guard comparisons > 0 else { return .medium }
        let avgDelta = totalDelta / Double(comparisons)

        switch avgDelta {
        case ..<0.06:  return .low
        case 0.06..<0.14: return .medium
        default:       return .high
        }
    }

    // -- Edge Density Aggregation --
    // Average per-image edge density values. Maps to ordinal: low=0, medium=1, high=2.

    static func averageEdgeDensity(_ values: [EdgeDensity]) -> EdgeDensity {
        guard !values.isEmpty else { return .medium }
        let sum = values.reduce(0.0) { acc, v in
            switch v {
            case .low: return acc + 0.0
            case .medium: return acc + 1.0
            case .high: return acc + 2.0
            }
        }
        let avg = sum / Double(values.count)
        switch avg {
        case ..<0.67:  return .low
        case 0.67..<1.33: return .medium
        default:       return .high
        }
    }

    // -- Material --
    // Heuristic: warm + low saturation → wood, cool + low saturation → metal,
    // high saturation → textile, otherwise mixed.

    static func estimateMaterial(temperature: PaletteTemperature, saturation: Saturation, brightness: Brightness) -> Material {
        switch (temperature, saturation) {
        case (.warm, .muted), (.warm, .neutral):
            return .wood
        case (.cool, .muted):
            return .metal
        case (_, .vivid):
            return .textile
        default:
            return .mixed
        }
    }
}
