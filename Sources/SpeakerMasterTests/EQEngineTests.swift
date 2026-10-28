import Foundation
import Testing
@testable import SpeakerMaster

@Suite("EQ engine")
struct EQEngineTests {
    @Test("bypass leaves samples unchanged")
    func bypassPassthrough() {
        var engine = EQEngine(
            sampleRate: 48_000,
            curve: EQCurve(
                bands: [EQBand(id: "p", frequencyHz: 1000, gainDb: 6, q: 1, type: .peaking)],
                broadbandGainDb: 0,
                bypassed: true
            )
        )
        #expect(engine.process(0.25) == 0.25)
    }

    @Test("peaking boost increases midband energy vs flat")
    func peakingAudible() {
        let sr = 48_000.0
        var tone = [Float]()
        tone.reserveCapacity(2048)
        for i in 0..<2048 {
            let phase = 2 * Double.pi * 1000 * Double(i) / sr
            tone.append(Float(0.2 * Darwin.sin(phase)))
        }
        var flatEngine = EQEngine(sampleRate: sr, curve: .flat)
        var boosted = EQEngine(
            sampleRate: sr,
            curve: EQCurve(
                bands: [EQBand(id: "p", frequencyHz: 1000, gainDb: 6, q: 1, type: .peaking)],
                broadbandGainDb: 0,
                bypassed: false
            ).sanitized()
        )
        var flatOut = tone
        var boostOut = tone
        flatEngine.processBuffer(&flatOut)
        boosted.processBuffer(&boostOut)
        let flatRMS = rms(flatOut)
        let boostRMS = rms(boostOut)
        #expect(boostRMS > flatRMS * 1.2)
    }

    @Test("limiter keeps hot sample under ceiling magnitude")
    func limiterCapsPeak() {
        var engine = EQEngine(sampleRate: 48_000, curve: .flat)
        let out = abs(engine.process(1.5))
        let ceiling = Float(Darwin.pow(10, SafetyLimits.truePeakCeilingDbTP / 20))
        #expect(out <= ceiling + 0.05)
    }

    private func rms(_ samples: [Float]) -> Double {
        guard !samples.isEmpty else { return 0 }
        let sum = samples.reduce(0.0) { $0 + Double($1) * Double($1) }
        return Darwin.sqrt(sum / Double(samples.count))
    }
}
