import Foundation

/// Dual-channel wrapper around `EQEngine` for interleaved stereo system audio.
public struct StereoEQEngine: Sendable {
    private var left: EQEngine
    private var right: EQEngine

    public init(sampleRate: Double = 48_000, curve: EQCurve = .flat) {
        left = EQEngine(sampleRate: sampleRate, curve: curve)
        right = EQEngine(sampleRate: sampleRate, curve: curve)
    }

    public mutating func apply(curve: EQCurve, sampleRate: Double) {
        left.apply(curve: curve, sampleRate: sampleRate)
        right.apply(curve: curve, sampleRate: sampleRate)
    }

    /// Process interleaved L R L R … in place.
    public mutating func processInterleaved(
        _ samples: UnsafeMutablePointer<Float>,
        frameCount: Int
    ) {
        guard frameCount > 0 else { return }
        for frame in 0..<frameCount {
            let i = frame * 2
            samples[i] = left.process(samples[i])
            samples[i + 1] = right.process(samples[i + 1])
        }
    }
}
