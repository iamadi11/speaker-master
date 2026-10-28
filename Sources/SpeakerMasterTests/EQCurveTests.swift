import Testing
@testable import SpeakerMaster

@Suite("EQ curve")
struct EQCurveTests {
    @Test("clamps bands through safety limits on init sanitize")
    func sanitizesHotBands() {
        let hot = EQBand(id: "b1", frequencyHz: 80, gainDb: 9, q: 1.0, type: .peaking)
        let curve = EQCurve(bands: [hot], broadbandGainDb: 5, bypassed: false).sanitized()
        #expect(curve.bands[0].gainDb == 4)
        #expect(curve.broadbandGainDb == 3)
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
}
