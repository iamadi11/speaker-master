import Foundation

/// Result of Auto Measure analyze step (record → analyze → apply).
public struct MeasureAnalysisResult: Sendable {
    public enum Quality: String, Sendable {
        case good
        case inconclusive
        case badTake
    }

    public var quality: Quality
    /// Best safe Auto EQ within caps; nil when quality is `.badTake`.
    public var correction: EQCurve?
    public var peakDbFS: Double
    public var notes: String

    public init(quality: Quality, correction: EQCurve?, peakDbFS: Double, notes: String) {
        self.quality = quality
        self.correction = correction
        self.peakDbFS = peakDbFS
        self.notes = notes
    }
}

/// Simplified v1 analyzer: band energy → cut-first correction under safety caps.
/// Not a lab FR solver — honesty: useful first pass, not “calibrated world-class” claim alone.
public enum MeasureAnalyzer: Sendable {
    private static let bandCentersHz: [Double] = EQCurve.defaultBandScaffold.map(\.hz)

    public static func safeFallbackCurve() -> EQCurve { .flat }

    public static func analyze(samples: [Float], sampleRate: Double) -> MeasureAnalysisResult {
        guard !samples.isEmpty else {
            return MeasureAnalysisResult(
                quality: .badTake,
                correction: nil,
                peakDbFS: -120,
                notes: "Empty capture"
            )
        }

        let peak = samples.map { abs($0) }.max() ?? 0
        let peakDb = peak > 0 ? 20 * log10(Double(peak)) : -120

        if peak < 0.01 {
            return MeasureAnalysisResult(
                quality: .badTake,
                correction: nil,
                peakDbFS: peakDb,
                notes: "Near-silent take — check mic and level"
            )
        }

        let energies = bandEnergies(samples: samples, sampleRate: sampleRate)
        let mean = energies.reduce(0, +) / Double(energies.count)
        guard mean > 1e-12 else {
            return MeasureAnalysisResult(
                quality: .badTake,
                correction: nil,
                peakDbFS: peakDb,
                notes: "No usable band energy"
            )
        }

        // Target: flatten toward mean with cut-first bias (prefer negative gains).
        var bands: [EQBand] = []
        for (scaffold, energy) in zip(EQCurve.defaultBandScaffold, energies) {
            let relativeDb = 10 * log10(energy / mean)
            // Invert error; prefer cuts for peaks; boost dips cautiously.
            var gain = -relativeDb
            if gain > 0 {
                gain *= 0.5 // cut-first: half-strength boosts
            }
            // Don't chase deep nulls.
            if gain > 3 { gain = 3 }
            if gain < -12 { gain = -12 }
            bands.append(
                EQBand(
                    id: scaffold.id,
                    frequencyHz: scaffold.hz,
                    gainDb: gain,
                    q: scaffold.q,
                    type: .peaking
                )
            )
        }

        let curve = EQCurve(bands: bands, broadbandGainDb: 0, bypassed: false).sanitized()
        let quality: MeasureAnalysisResult.Quality = peakDb > -3 ? .inconclusive : .good
        return MeasureAnalysisResult(
            quality: quality,
            correction: curve,
            peakDbFS: peakDb,
            notes: quality == .good
                ? "Cut-first correction within safety caps"
                : "Hot input — correction proposed but re-level recommended"
        )
    }

    /// Goertzel-ish band energy around each scaffold center.
    private static func bandEnergies(samples: [Float], sampleRate: Double) -> [Double] {
        bandCentersHz.map { center in
            goertzelPower(samples: samples, sampleRate: sampleRate, frequencyHz: center)
        }
    }

    private static func goertzelPower(samples: [Float], sampleRate: Double, frequencyHz: Double) -> Double {
        let n = samples.count
        guard n > 8 else { return 0 }
        let k = Int(0.5 + (Double(n) * frequencyHz / sampleRate))
        let w = 2 * Double.pi * Double(k) / Double(n)
        let coeff = 2 * cos(w)
        var s0 = 0.0, s1 = 0.0, s2 = 0.0
        for sample in samples {
            s0 = Double(sample) + coeff * s1 - s2
            s2 = s1
            s1 = s0
        }
        let power = s1 * s1 + s2 * s2 - coeff * s1 * s2
        return max(power, 0)
    }
}
