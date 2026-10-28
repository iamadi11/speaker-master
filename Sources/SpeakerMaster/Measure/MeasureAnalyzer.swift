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
    /// Crest factor (peak/RMS) in dB — honesty signal for spiky / clicky takes.
    public var crestDb: Double
    /// Rough signal-over-floor estimate in dB (not a lab SNR).
    public var snrDbEstimate: Double
    /// Per-scaffold relative band energy vs mean (dB). Empty on early rejects.
    public var relativeBandDb: [Double]

    public init(
        quality: Quality,
        correction: EQCurve?,
        peakDbFS: Double,
        notes: String,
        crestDb: Double = 0,
        snrDbEstimate: Double = 0,
        relativeBandDb: [Double] = []
    ) {
        self.quality = quality
        self.correction = correction
        self.peakDbFS = peakDbFS
        self.notes = notes
        self.crestDb = crestDb
        self.snrDbEstimate = snrDbEstimate
        self.relativeBandDb = relativeBandDb
    }
}

/// Simplified analyzer: windowed band energy → cut-first correction under safety caps.
///
/// Honesty contract (`docs/agent-measure-loop.md`):
/// - Useful first pass for Auto Measure — **not** a lab FR / calibrated claim.
/// - Bad / clipped / silent / too-noisy takes refuse; never invent a hot guess.
/// - Built-in mic OK for first pass; SNR and crest are approximate, not metrology.
public enum MeasureAnalyzer: Sendable {
    private static let bandCentersHz: [Double] = EQCurve.defaultBandScaffold.map(\.hz)

    public static func safeFallbackCurve() -> EQCurve { .flat }

    public static func analyze(samples: [Float], sampleRate: Double) -> MeasureAnalysisResult {
        guard !samples.isEmpty else {
            return MeasureAnalysisResult(
                quality: .badTake,
                correction: nil,
                peakDbFS: -120,
                notes: "Empty capture — nothing applied"
            )
        }

        // Use the middle of the capture so play/stop edges don't dominate band energy.
        let analysis = midWindow(samples)
        let peak = analysis.map { abs($0) }.max() ?? 0
        let peakDb = peak > 0 ? 20 * log10(Double(peak)) : -120

        // Hard clip on the mic path → refuse (safety-limits Measure failure → safe).
        if peak >= 0.98 {
            return MeasureAnalysisResult(
                quality: .badTake,
                correction: nil,
                peakDbFS: peakDb,
                notes: "Input clipped — lower speaker or mic level, then retry"
            )
        }

        if peak < 0.01 {
            return MeasureAnalysisResult(
                quality: .badTake,
                correction: nil,
                peakDbFS: peakDb,
                notes: "Near-silent take — check mic selection, placement, and level"
            )
        }

        let rms = rootMeanSquare(analysis)
        let crestDb = peak > 0 && rms > 1e-9
            ? 20 * log10(Double(peak) / Double(rms))
            : 0
        // Extremely peaky / clicky captures are usually bad room noise, not a sweep.
        if crestDb > 28 {
            return MeasureAnalysisResult(
                quality: .badTake,
                correction: nil,
                peakDbFS: peakDb,
                notes: "Too noisy or spiky — quiet the room and retry, or use Narrow",
                crestDb: crestDb
            )
        }

        let snrDb = approximateSNRDb(analysis)
        if snrDb < 6 {
            return MeasureAnalysisResult(
                quality: .badTake,
                correction: nil,
                peakDbFS: peakDb,
                notes: "Weak signal vs noise floor — closer mic, louder (comfortable) level, or Narrow",
                crestDb: crestDb,
                snrDbEstimate: snrDb
            )
        }

        let windowed = hannWindow(analysis)
        let energies = bandEnergies(samples: windowed, sampleRate: sampleRate)
        let mean = energies.reduce(0, +) / Double(energies.count)
        guard mean > 1e-12 else {
            return MeasureAnalysisResult(
                quality: .badTake,
                correction: nil,
                peakDbFS: peakDb,
                notes: "No usable band energy — nothing applied",
                crestDb: crestDb,
                snrDbEstimate: snrDb
            )
        }

        let relativeBandDb = energies.map { 10 * log10($0 / mean) }

        // Target: flatten toward mean with cut-first bias (prefer negative gains).
        var bands: [EQBand] = []
        for (scaffold, relativeDb) in zip(EQCurve.defaultBandScaffold, relativeBandDb) {
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
        let quality = classifyQuality(peakDb: peakDb, snrDb: snrDb, relativeBandDb: relativeBandDb)
        let notes = honestyNotes(quality: quality, snrDb: snrDb, relativeBandDb: relativeBandDb)
        return MeasureAnalysisResult(
            quality: quality,
            correction: curve,
            peakDbFS: peakDb,
            notes: notes,
            crestDb: crestDb,
            snrDbEstimate: snrDb,
            relativeBandDb: relativeBandDb
        )
    }

    /// Human-readable band deltas for UI (e.g. "80 Hz −2.1 dB").
    public static func bandCorrectionSummary(from result: MeasureAnalysisResult, limit: Int = 3) -> String {
        guard let correction = result.correction else { return "" }
        let ranked = correction.bands
            .map { ($0, abs($0.gainDb)) }
            .sorted { $0.1 > $1.1 }
            .prefix(limit)
            .filter { $0.1 >= 0.5 }
        guard !ranked.isEmpty else { return "Near-flat correction" }
        return ranked.map { band, _ in
            let hz = band.frequencyHz >= 1000
                ? String(format: "%.1fk", band.frequencyHz / 1000)
                : "\(Int(band.frequencyHz))"
            return String(format: "%@ %+.1f", hz, band.gainDb)
        }
        .joined(separator: " · ")
    }

    // MARK: - Quality

    private static func classifyQuality(
        peakDb: Double,
        snrDb: Double,
        relativeBandDb: [Double]
    ) -> MeasureAnalysisResult.Quality {
        let spread = (relativeBandDb.max() ?? 0) - (relativeBandDb.min() ?? 0)
        if peakDb > -3 || snrDb < 12 || spread > 24 {
            return .inconclusive
        }
        return .good
    }

    private static func honestyNotes(
        quality: MeasureAnalysisResult.Quality,
        snrDb: Double,
        relativeBandDb: [Double]
    ) -> String {
        let cuts = relativeBandDb.filter { $0 > 1.5 }.count
        switch quality {
        case .good:
            return "Cut-first correction within safety caps · ~\(Int(snrDb.rounded())) dB SNR est. · limiter on"
        case .inconclusive:
            if cuts > 0 {
                return "Usable but cautious — re-level / quieter room next time · \(cuts) peak band(s) cut"
            }
            return "Hot or uneven take — correction proposed; re-level recommended"
        case .badTake:
            return "Bad take — nothing applied"
        }
    }

    // MARK: - Signal helpers

    /// Keep the central 60% of the capture (stimulus body; drop start/stop edges).
    private static func midWindow(_ samples: [Float]) -> [Float] {
        guard samples.count > 64 else { return samples }
        let start = samples.count / 5
        let end = samples.count - start
        return Array(samples[start..<end])
    }

    private static func hannWindow(_ samples: [Float]) -> [Float] {
        let n = samples.count
        guard n > 1 else { return samples }
        return samples.enumerated().map { index, sample in
            let w = 0.5 - 0.5 * cos(2 * Double.pi * Double(index) / Double(n - 1))
            return Float(Double(sample) * w)
        }
    }

    private static func rootMeanSquare(_ samples: [Float]) -> Float {
        guard !samples.isEmpty else { return 0 }
        var sum: Float = 0
        for sample in samples {
            sum += sample * sample
        }
        return sqrt(sum / Float(samples.count))
    }

    /// Rough signal-over-floor estimate — not metrology.
    /// Steady sweeps have near-equal frame RMS; those use an absolute floor so
    /// we do not reject clean tones as “weak SNR.”
    private static func approximateSNRDb(_ samples: [Float]) -> Double {
        let rms = Double(rootMeanSquare(samples))
        guard samples.count >= 64, rms > 1e-9 else { return 0 }
        let frame = max(32, samples.count / 16)
        var frameRMS: [Double] = []
        var i = 0
        while i + frame <= samples.count {
            let slice = Array(samples[i..<(i + frame)])
            frameRMS.append(Double(rootMeanSquare(slice)))
            i += frame
        }
        guard frameRMS.count >= 4 else {
            return 20 * log10(rms / 1e-4)
        }
        let sorted = frameRMS.sorted()
        let quiet = max(sorted[sorted.count / 4], 1e-9)
        let loud = max(sorted[(sorted.count * 3) / 4], 1e-9)
        // Steady stimulus: quiet ≈ loud → score vs absolute digital floor.
        if loud / quiet < 1.35 {
            return 20 * log10(rms / 1e-4)
        }
        return 20 * log10(loud / quiet)
    }

    /// Band power ≈ mean of Goertzel at center ± 1/6 octave (not a single fragile bin).
    private static func bandEnergies(samples: [Float], sampleRate: Double) -> [Double] {
        bandCentersHz.map { center in
            bandPower(samples: samples, sampleRate: sampleRate, centerHz: center)
        }
    }

    private static func bandPower(samples: [Float], sampleRate: Double, centerHz: Double) -> Double {
        guard samples.count > 16, sampleRate > 0, centerHz > 0 else { return 0 }
        let lowHz = centerHz / pow(2.0, 1.0 / 6.0)
        let highHz = centerHz * pow(2.0, 1.0 / 6.0)
        let probes = [lowHz, centerHz, highHz]
        let sum = probes.reduce(0.0) { partial, hz in
            partial + goertzelPower(samples: samples, sampleRate: sampleRate, frequencyHz: hz)
        }
        return max(sum / Double(probes.count), 0)
    }

    private static func goertzelPower(samples: [Float], sampleRate: Double, frequencyHz: Double) -> Double {
        let n = samples.count
        guard n > 8 else { return 0 }
        let k = Int(0.5 + (Double(n) * frequencyHz / sampleRate))
        guard k > 0, k < n / 2 else { return 0 }
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
