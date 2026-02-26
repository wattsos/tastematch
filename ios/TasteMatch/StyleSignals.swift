import Foundation

/// 11 interpretable visual signals extracted from an image.
struct StyleSignals: Codable, Equatable {

    // Photometric
    var brightness: Double           // 0..1  average luminance
    var contrast: Double             // 0..1  RMS contrast
    var saturation: Double           // 0..1  average chroma
    var warmth: Double               // 0..1  red-minus-blue balance

    // Composition
    var edgeDensity: Double          // 0..1  Sobel magnitude density
    var symmetry: Double             // 0..1  left-right Pearson r
    var clutter: Double              // 0..1  local-variance mean

    // Material / Mood
    var materialHardness: Double     // 0..1  high-edge + low-warmth proxy
    var organicVsIndustrial: Double  // 0..1  1 = organic
    var ornateVsMinimal: Double      // 0..1  1 = ornate
    var vintageVsModern: Double      // 0..1  1 = vintage

    /// Number of signals (stable across app versions).
    static let count = 11

    /// Returns all 11 signals as a Double array. Order is stable.
    var asVector: [Double] {
        [brightness, contrast, saturation, warmth,
         edgeDensity, symmetry, clutter,
         materialHardness, organicVsIndustrial,
         ornateVsMinimal, vintageVsModern]
    }

    /// Neutral mid-point signals — used as safe fallback.
    static let neutral = StyleSignals(
        brightness: 0.5, contrast: 0.5, saturation: 0.5, warmth: 0.5,
        edgeDensity: 0.5, symmetry: 0.5, clutter: 0.5,
        materialHardness: 0.5, organicVsIndustrial: 0.5,
        ornateVsMinimal: 0.5, vintageVsModern: 0.5
    )

    /// Human-readable description of the top 4 dominant signals.
    var signalDescription: String {
        let pairs: [(String, Double)] = [
            ("brightness", brightness), ("contrast", contrast),
            ("saturation", saturation), ("warmth", warmth),
            ("edges", edgeDensity), ("symmetry", symmetry),
            ("clutter", clutter), ("hardness", materialHardness),
            ("organic", organicVsIndustrial), ("ornate", ornateVsMinimal),
            ("vintage", vintageVsModern)
        ]
        return pairs
            .sorted { $0.1 > $1.1 }
            .prefix(4)
            .map { "\($0.0): \(String(format: "%.2f", $0.1))" }
            .joined(separator: ", ")
    }
}
