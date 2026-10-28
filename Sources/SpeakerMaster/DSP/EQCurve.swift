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

    public func sanitized() -> EQCurve {
        EQCurve(
            bands: bands.map { $0.sanitized() },
            broadbandGainDb: SafetyLimits.clampBroadbandGain(broadbandGainDb),
            bypassed: bypassed
        )
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
