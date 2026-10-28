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
        // Multi-partial tone — energy across several scaffold bands (not a single sine).
        let sr = 48_000.0
        var samples = [Float]()
        samples.reserveCapacity(16_384)
        for i in 0..<16_384 {
            let t = Double(i) / sr
            let v =
                0.12 * sin(2 * Double.pi * 80 * t)
                + 0.10 * sin(2 * Double.pi * 250 * t)
                + 0.08 * sin(2 * Double.pi * 1000 * t)
                + 0.06 * sin(2 * Double.pi * 3500 * t)
                + 0.04 * sin(2 * Double.pi * 10000 * t)
            samples.append(Float(v))
        }
        let result = MeasureAnalyzer.analyze(samples: samples, sampleRate: sr)
        #expect(result.quality != .badTake)
        #expect(!result.relativeBandDb.isEmpty)
        #expect(result.snrDbEstimate > 0)
        if let correction = result.correction {
            let curve = correction.sanitized()
            #expect(curve.broadbandGainDb <= SafetyLimits.maxBroadbandBoostDb)
            for band in curve.bands where band.gainDb > 0 {
                #expect(band.gainDb <= SafetyLimits.maxBandBoostDb(frequencyHz: band.frequencyHz))
            }
        }
    }

    @Test("boom-heavy bass tone prefers cuts on low bands")
    func cutFirstOnBoom() {
        let sr = 48_000.0
        var samples = [Float]()
        samples.reserveCapacity(16_384)
        for i in 0..<16_384 {
            let t = Double(i) / sr
            // Strong 80 Hz + weaker highs → expect bass cut, not bass boost chase.
            let v =
                0.35 * sin(2 * Double.pi * 80 * t)
                + 0.05 * sin(2 * Double.pi * 1000 * t)
                + 0.04 * sin(2 * Double.pi * 3500 * t)
            samples.append(Float(v))
        }
        let result = MeasureAnalyzer.analyze(samples: samples, sampleRate: sr)
        #expect(result.quality != .badTake)
        guard let correction = result.correction else {
            Issue.record("expected correction")
            return
        }
        let bass = correction.bands.first { $0.id == "band-bass" }
        #expect(bass != nil)
        #expect((bass?.gainDb ?? 0) <= 0.5)
        let summary = MeasureAnalyzer.bandCorrectionSummary(from: result)
        #expect(!summary.isEmpty)
    }

    @Test("failure path recommends flat plus limiter")
    func failureIsFlat() {
        let flat = MeasureAnalyzer.safeFallbackCurve()
        #expect(flat.bands.allSatisfy { abs($0.gainDb) < 0.01 })
        #expect(flat.broadbandGainDb == 0)
    }

    @Test("hard-clipped samples are a bad take")
    func rejectsClip() {
        let samples = [Float](repeating: 0.99, count: 4096)
        let result = MeasureAnalyzer.analyze(samples: samples, sampleRate: 48_000)
        #expect(result.quality == .badTake)
        #expect(result.correction == nil)
        #expect(result.notes.lowercased().contains("clip"))
    }

    @Test("spiky impulse-like takes are refused")
    func rejectsSpiky() {
        var samples = [Float](repeating: 0.001, count: 8192)
        samples[100] = 0.9
        samples[101] = -0.85
        let result = MeasureAnalyzer.analyze(samples: samples, sampleRate: 48_000)
        #expect(result.quality == .badTake)
        #expect(result.correction == nil)
    }

    @Test("near-clip takes stay cautious — never labeled good")
    func nearClipIsInconclusive() {
        let sr = 48_000.0
        var samples = [Float]()
        samples.reserveCapacity(16_384)
        // Single partial at 0.90 — peak stays in [0.85, 0.98) without hard clip.
        for i in 0..<16_384 {
            let t = Double(i) / sr
            samples.append(Float(0.90 * sin(2 * Double.pi * 1000 * t)))
        }
        let peak = samples.map { abs($0) }.max() ?? 0
        #expect(peak >= 0.85 && peak < 0.98)
        let result = MeasureAnalyzer.analyze(samples: samples, sampleRate: sr)
        #expect(result.quality != .good)
        if result.correction != nil {
            #expect(result.quality == .inconclusive)
            #expect(result.notes.lowercased().contains("clip") || result.notes.lowercased().contains("cautious"))
        }
    }
}
