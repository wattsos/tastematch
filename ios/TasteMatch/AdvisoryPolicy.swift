import Foundation

// MARK: - Advisory Level

enum AdvisoryLevel: String, CaseIterable, Codable {
    case soft, standard, strict

    var displayName: String {
        switch self {
        case .soft:     return "Soft"
        case .standard: return "Standard"
        case .strict:   return "Strict"
        }
    }

    var helperText: String {
        switch self {
        case .soft:     return "Only warn on big mismatches."
        case .standard: return "Balanced guidance."
        case .strict:   return "High sensitivity."
        }
    }
}

// MARK: - Advisory Verdict

enum AdvisoryVerdict: String, Codable {
    case green, yellow, red

    var headline: String {
        switch self {
        case .green:  return "Aligned."
        case .yellow: return "Consider."
        case .red:    return "High drift."
        }
    }

    var subhead: String {
        switch self {
        case .green:  return "This sits comfortably inside your Objects identity."
        case .yellow: return "This nudges you toward a different signal."
        case .red:    return "This may pull your Objects identity off-center."
        }
    }
}

// MARK: - Conflict Result

struct ConflictResult: Equatable {
    let alignment: Double       // 0..1
    let drift: Double           // 0..1
    let conflictAxes: [String]  // top 2 axis names (human-readable)
}

// MARK: - Advisory Decision

struct AdvisoryDecision: Equatable {
    let verdict: AdvisoryVerdict
    let shouldIntercept: Bool
    let conflict: ConflictResult
}

// MARK: - Advisory Policy

enum AdvisoryPolicy {

    static func decide(level: AdvisoryLevel, conflict: ConflictResult, tolerance: Double = 0.0) -> AdvisoryDecision {
        let verdict: AdvisoryVerdict
        let shouldIntercept: Bool
        let a = conflict.alignment + tolerance

        switch level {
        case .soft:
            if conflict.drift >= 0.40 || a <= 0.42 {
                verdict = .red
            } else if conflict.drift >= 0.28 || a <= 0.55 {
                verdict = .yellow
            } else {
                verdict = .green
            }

        case .standard:
            if conflict.drift >= 0.30 || a <= 0.50 {
                verdict = .red
            } else if conflict.drift >= 0.20 || a <= 0.62 {
                verdict = .yellow
            } else {
                verdict = .green
            }

        case .strict:
            if conflict.drift >= 0.22 || a <= 0.58 {
                verdict = .red
            } else if conflict.drift >= 0.16 || a <= 0.70 {
                verdict = .yellow
            } else {
                verdict = .green
            }
        }

        // Soft: intercept red only. Standard + Strict: intercept yellow + red.
        shouldIntercept = (verdict == .red) || (verdict == .yellow && level != .soft)

        return AdvisoryDecision(
            verdict: verdict,
            shouldIntercept: shouldIntercept,
            conflict: conflict
        )
    }
}
