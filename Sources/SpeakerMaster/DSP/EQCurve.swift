import Foundation

/// Full EQ curve: bands + optional broadband makeup (still capped).
public struct EQCurve: Hashable, Sendable, Codable {
    public var bands: [EQBand]
    public var broadbandGainDb: Double
    public var bypassed: Bool

    public init(bands: [EQBand], broadbandGainDb: Double, bypassed: Bool) {
        self.bands = bands
        self.broadbandGainDb = broadbandGainDb
        self.bypassed = bypassed
    }

    /// Default Custom / Measure failure path: flat, limiter still applied by host.
    public static let flat = EQCurve(
        bands: EQCurve.defaultBandScaffold.map {
            EQBand(id: $0.id, frequencyHz: $0.hz, gainDb: 0, q: $0.q, type: .peaking)
        },
        broadbandGainDb: 0,
        bypassed: false
    )

    /// Five-band scaffold for Custom progressive disclosure (v1 shallow).
    public static let defaultBandScaffold: [(id: String, hz: Double, q: Double)] = [
        ("band-bass", 80, 0.9),
        ("band-lowmid", 250, 1.0),
        ("band-mid", 1000, 1.0),
        ("band-presence", 3500, 1.1),
        ("band-air", 10000, 0.9),
    ]

    /// Probe grid for total constructive-gain enforcement (`docs/safety-limits.md` §2).
    public static let constructiveProbeHz: [Double] = [
        40, 60, 80, 120, 250, 500, 1_000, 2_000, 3_500, 6_000, 10_000, 16_000,
    ]

    /// Clamp per-band / broadband ceilings, then scale overlapping positive gain so
    /// approximate magnitude never exceeds `SafetyLimits.maxTotalConstructiveGainDb`.
    public func sanitized() -> EQCurve {
        var nextBands = bands.map { $0.sanitized() }
        var broadband = SafetyLimits.clampBroadbandGain(broadbandGainDb)
        // Iteratively scale positive boosts (+ broadband) until the worst probe is in cap.
        for _ in 0..<8 {
            let probe = EQCurve(bands: nextBands, broadbandGainDb: broadband, bypassed: false)
            let worst = probe.worstConstructiveGainDb(sampleRate: 48_000)
            guard worst > SafetyLimits.maxTotalConstructiveGainDb + 1e-6 else { break }
            let scale = SafetyLimits.maxTotalConstructiveGainDb / worst
            for i in nextBands.indices where nextBands[i].gainDb > 0 {
                nextBands[i].gainDb *= scale
            }
            if broadband > 0 {
                broadband *= scale
            }
        }
        return EQCurve(bands: nextBands, broadbandGainDb: broadband, bypassed: bypassed)
    }

    /// Worst-case approximate constructive magnitude across the probe grid (dB).
    /// Cuts do not reduce this — only positive contributions + broadband count upward.
    public func worstConstructiveGainDb(sampleRate: Double) -> Double {
        if bypassed { return 0 }
        return Self.constructiveProbeHz
            .map { approximateMagnitudeDb(atFrequencyHz: $0, sampleRate: sampleRate) }
            .max() ?? 0
    }

    /// Headroom under the total constructive ceiling at the hottest probe (dB ≥ 0 when under cap).
    public func constructiveHeadroomDb(sampleRate: Double = 48_000) -> Double {
        SafetyLimits.maxTotalConstructiveGainDb - worstConstructiveGainDb(sampleRate: sampleRate)
    }

    /// Rough magnitude estimate for tests / UI preview (not a full FFT analyzer).
    public func approximateMagnitudeDb(atFrequencyHz frequency: Double, sampleRate: Double) -> Double {
        if bypassed { return 0 }
        var total = broadbandGainDb
        for band in bands {
            total += Self.bandContributionDb(band: band, frequencyHz: frequency, sampleRate: sampleRate)
        }
        return total
    }

    private static func bandContributionDb(band: EQBand, frequencyHz: Double, sampleRate _: Double) -> Double {
        guard band.gainDb != 0 else { return 0 }
        let f0 = max(1.0, band.frequencyHz)
        let ratio = frequencyHz / f0
        let logRatio = Darwin.log2(max(ratio, 1e-9))
        // Simple resonant peaking / shelf shape for preview + tests.
        switch band.type {
        case .peaking:
            let width = max(0.15, 1.0 / max(band.q, 0.1))
            let exponent = -0.5 * (logRatio * logRatio) / (width * width)
            let w = Darwin.exp(exponent)
            return band.gainDb * w
        case .lowShelf:
            return band.gainDb * (frequencyHz <= f0 ? 1.0 : max(0.0, 1.0 - abs(logRatio)))
        case .highShelf:
            return band.gainDb * (frequencyHz >= f0 ? 1.0 : max(0.0, 1.0 - abs(logRatio)))
        case .lowPass, .highPass:
            return 0
        }
    }
}
