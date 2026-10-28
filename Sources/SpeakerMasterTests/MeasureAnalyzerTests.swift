import Foundation
import Testing
@testable import SpeakerMaster

@Suite("Measure analyzer")
struct MeasureAnalyzerTests {
    @Test("rejects empty or near-silent takes as bad")
    func rejectsSilent() {
        let samples = [Float](repeating: 0, count: 2048)
        let result = MeasureAnalyzer.analyze(samples: samples, sampleRate: 48_000)
        #expect(result.quality == .badTake)
        #expect(result.correction == nil)
    }

    @Test("noisy flat-ish tone yields cut-first safe curve or inconclusive")
    func analyzesAudibleTone() {
        // 200 Hz sine at modest level — energy in bass/low-mid
        let sr = 48_000.0
        var samples = [Float]()
        samples.reserveCapacity(8192)
        for i in 0..<8192 {
            let phase = 2 * Double.pi * 200 * Double(i) / sr
            samples.append(Float(0.2 * Darwin.sin(phase)))
        }
        let result = MeasureAnalyzer.analyze(samples: samples, sampleRate: sr)
        #expect(result.quality != .badTake)
        if let correction = result.correction {
            let curve = correction.sanitized()
            #expect(curve.broadbandGainDb <= SafetyLimits.maxBroadbandBoostDb)
            for band in curve.bands where band.gainDb > 0 {
                #expect(band.gainDb <= SafetyLimits.maxBandBoostDb(frequencyHz: band.frequencyHz))
            }
        }
    }

    @Test("failure path recommends flat plus limiter")
    func failureIsFlat() {
        let flat = MeasureAnalyzer.safeFallbackCurve()
        #expect(flat.bands.allSatisfy { abs($0.gainDb) < 0.01 })
        #expect(flat.broadbandGainDb == 0)
    }
}
