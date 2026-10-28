import Foundation
import Testing
@testable import SpeakerMaster

@Suite("Stereo EQ engine")
struct StereoEQEngineTests {
    @Test("interleaved peaking boost raises both channels")
    func interleavedBoost() {
        let sr = 48_000.0
        var frames = [Float](repeating: 0, count: 512 * 2)
        for i in 0..<512 {
            let phase = 2 * Double.pi * 1000 * Double(i) / sr
            let s = Float(0.2 * Darwin.sin(phase))
            frames[i * 2] = s
            frames[i * 2 + 1] = s
        }
        var flat = StereoEQEngine(sampleRate: sr, curve: .flat)
        var boosted = StereoEQEngine(
            sampleRate: sr,
            curve: EQCurve(
                bands: [EQBand(id: "p", frequencyHz: 1000, gainDb: 6, q: 1, type: .peaking)],
                broadbandGainDb: 0,
                bypassed: false
            ).sanitized()
        )
        var flatOut = frames
        var boostOut = frames
        flatOut.withUnsafeMutableBufferPointer { buf in
            flat.processInterleaved(buf.baseAddress!, frameCount: 512)
        }
        boostOut.withUnsafeMutableBufferPointer { buf in
            boosted.processInterleaved(buf.baseAddress!, frameCount: 512)
        }
        #expect(rms(boostOut) > rms(flatOut) * 1.2)
    }

    @Test("permission copy points at Screen & System Audio Recording")
    func permissionCopy() {
        #expect(SystemAudioPermissionCopy.grantSteps.contains("Screen & System Audio Recording"))
        #expect(SystemAudioPermissionCopy.settingsURLString.contains("Privacy_ScreenCapture"))
    }

    private func rms(_ samples: [Float]) -> Double {
        guard !samples.isEmpty else { return 0 }
        let sum = samples.reduce(0.0) { $0 + Double($1) * Double($1) }
        return Darwin.sqrt(sum / Double(samples.count))
    }
}
