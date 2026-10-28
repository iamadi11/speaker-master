import Foundation

/// Product decision after analyze: apply best-within-caps Auto EQ, or refuse (no hot guess).
public enum MeasureApplyDecision: Sendable, Equatable {
    case apply(curve: EQCurve, notes: String)
    case refuse(notes: String)
}

/// Pure seam for Auto Measure step 3 (apply) — testable without mic / Core Audio.
///
/// Contract: `docs/agent-measure-loop.md` — best means cut-first within `SafetyLimits`;
/// bad takes never become a new profile.
public enum MeasurePipeline: Sendable {
    public static func decision(from result: MeasureAnalysisResult) -> MeasureApplyDecision {
        switch result.quality {
        case .badTake:
            return .refuse(notes: result.notes)
        case .good, .inconclusive:
            guard let correction = result.correction else {
                return .refuse(
                    notes: result.notes.isEmpty
                        ? "Analyze produced no correction — nothing applied"
                        : result.notes
                )
            }
            let safe = correction.sanitized()
            return .apply(curve: safe, notes: result.notes)
        }
    }

    /// Curve used when Measure refuses and there is no prior good profile to keep.
    public static func safeIdleCurve() -> EQCurve {
        MeasureAnalyzer.safeFallbackCurve()
    }
}
