import Testing
@testable import SpeakerMaster

@Suite("EQ curve")
struct EQCurveTests {
    @Test("clamps bands through safety limits on init sanitize")
    func sanitizesHotBands() {
        let hot = EQBand(id: "b1", frequencyHz: 80, gainDb: 9, q: 1.0, type: .peaking)
        // Band-only: bass ceiling +4 dB (no broadband stacking).
        let bandOnly = EQCurve(bands: [hot], broadbandGainDb: 0, bypassed: false).sanitized()
        #expect(bandOnly.bands[0].gainDb == 4)
        // Broadband alone clamps to +3 dB.
        let loudness = EQCurve(bands: EQCurve.flat.bands, broadbandGainDb: 5, bypassed: false).sanitized()
        #expect(loudness.broadbandGainDb == 3)
        // Stacked bass + broadband still under total constructive ceiling.
        let stacked = EQCurve(bands: [hot], broadbandGainDb: 5, bypassed: false).sanitized()
        #expect(stacked.bands[0].gainDb <= 4)
        #expect(stacked.broadbandGainDb <= 3)
        #expect(stacked.worstConstructiveGainDb(sampleRate: 48_000) <= SafetyLimits.maxTotalConstructiveGainDb + 0.15)
    }

    @Test("flat curve is identity")
    func flatIsIdentity() {
        let flat = EQCurve.flat
        #expect(flat.bands.allSatisfy { $0.gainDb == 0 })
        #expect(flat.broadbandGainDb == 0)
        #expect(!flat.bypassed)
    }

    @Test("reset restores flat")
    func resetToFlat() {
        var curve = EQCurve(
            bands: [EQBand(id: "m", frequencyHz: 1000, gainDb: 3, q: 1.2, type: .peaking)],
            broadbandGainDb: 1,
            bypassed: true
        )
        curve = .flat
        #expect(curve.bands.allSatisfy { $0.gainDb == 0 })
        #expect(!curve.bypassed)
    }

    @Test("magnitude at center of peaking boost rises within cap")
    func peakingMagnitude() {
        let band = EQBand(id: "p", frequencyHz: 1000, gainDb: 6, q: 1.0, type: .peaking)
        let curve = EQCurve(bands: [band], broadbandGainDb: 0, bypassed: false).sanitized()
        let mag = curve.approximateMagnitudeDb(atFrequencyHz: 1000, sampleRate: 48_000)
        #expect(mag > 4)
        #expect(mag <= 6.1)
    }

    @Test("sanitized scales overlapping boosts under total constructive ceiling")
    func enforcesTotalConstructiveGain() {
        // Two mid boosts + broadband would exceed +6 dB at ~1 kHz without scaling.
        let bands = [
            EQBand(id: "a", frequencyHz: 800, gainDb: 6, q: 0.7, type: .peaking),
            EQBand(id: "b", frequencyHz: 1200, gainDb: 6, q: 0.7, type: .peaking),
        ]
        let curve = EQCurve(bands: bands, broadbandGainDb: 3, bypassed: false).sanitized()
        let worst = curve.worstConstructiveGainDb(sampleRate: 48_000)
        #expect(worst <= SafetyLimits.maxTotalConstructiveGainDb + 0.15)
        #expect(curve.constructiveHeadroomDb() >= -0.15)
        #expect(curve.broadbandGainDb <= SafetyLimits.maxBroadbandBoostDb)
    }
}
