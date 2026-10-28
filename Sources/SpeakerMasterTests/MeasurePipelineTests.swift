import Foundation
import Testing
@testable import SpeakerMaster

@Suite("Measure pipeline")
struct MeasurePipelineTests {
    @Test("good analyze decides apply with sanitized curve")
    func appliesGoodTake() {
        let bands = EQCurve.defaultBandScaffold.map {
            EQBand(id: $0.id, frequencyHz: $0.hz, gainDb: 2, q: $0.q, type: .peaking)
        }
        let result = MeasureAnalysisResult(
            quality: .good,
            correction: EQCurve(bands: bands, broadbandGainDb: 0, bypassed: false),
            peakDbFS: -12,
            notes: "ok"
        )
        let decision = MeasurePipeline.decision(from: result)
        guard case .apply(let curve, let notes) = decision else {
            Issue.record("expected apply")
            return
        }
        #expect(notes == "ok")
        #expect(curve.broadbandGainDb <= SafetyLimits.maxBroadbandBoostDb)
        for band in curve.bands where band.gainDb > 0 {
            #expect(band.gainDb <= SafetyLimits.maxBandBoostDb(frequencyHz: band.frequencyHz))
        }
    }

    @Test("bad take refuses and never invents a curve")
    func refusesBadTake() {
        let result = MeasureAnalysisResult(
            quality: .badTake,
            correction: nil,
            peakDbFS: -80,
            notes: "Near-silent"
        )
        let decision = MeasurePipeline.decision(from: result)
        guard case .refuse(let notes) = decision else {
            Issue.record("expected refuse")
            return
        }
        #expect(notes.contains("Near-silent"))
    }

    @Test("good quality without correction refuses")
    func refusesMissingCorrection() {
        let result = MeasureAnalysisResult(
            quality: .good,
            correction: nil,
            peakDbFS: -10,
            notes: ""
        )
        let decision = MeasurePipeline.decision(from: result)
        guard case .refuse = decision else {
            Issue.record("expected refuse when correction nil")
            return
        }
    }

    @Test("idle fallback is flat")
    func idleIsFlat() {
        let idle = MeasurePipeline.safeIdleCurve()
        #expect(idle.bands.allSatisfy { abs($0.gainDb) < 0.01 })
        #expect(idle.broadbandGainDb == 0)
    }

    @Test("clipped synthetic take is refused by analyzer then pipeline")
    func clippedRefusedEndToEnd() {
        let samples = [Float](repeating: 1.0, count: 2048)
        let result = MeasureAnalyzer.analyze(samples: samples, sampleRate: 48_000)
        #expect(result.quality == .badTake)
        let decision = MeasurePipeline.decision(from: result)
        guard case .refuse = decision else {
            Issue.record("expected refuse on clip")
            return
        }
    }
}
