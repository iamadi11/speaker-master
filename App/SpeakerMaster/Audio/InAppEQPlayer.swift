import AVFoundation
import Foundation
import SpeakerMaster

enum InAppEQPlayMode: Sendable {
    case noise
    case sweep
}

/// Realtime-safe state for `AVAudioSourceNode`. Touched under `lock` from the
/// audio IO thread and from MainActor apply/start/stop — never hops actors.
private final class InAppEQRenderState: @unchecked Sendable {
    private let lock = NSLock()
    private var eqEngine = EQEngine(sampleRate: 48_000, curve: .flat)
    private var phase: Double = 0
    private var sampleRate: Double = 48_000
    private var mode: InAppEQPlayMode = .noise
    /// Tiny LCG — avoid `Float.random` / system RNG on the render thread.
    private var noiseState: UInt64 = 0xC0FFEE_DEAD_BEEF

    func resetPhase() {
        lock.lock()
        phase = 0
        lock.unlock()
    }

    func configure(mode: InAppEQPlayMode, sampleRate: Double, curve: EQCurve) {
        lock.lock()
        self.mode = mode
        self.sampleRate = sampleRate > 0 ? sampleRate : 48_000
        self.phase = 0
        eqEngine.apply(curve: curve, sampleRate: self.sampleRate)
        lock.unlock()
    }

    func apply(curve: EQCurve) {
        lock.lock()
        eqEngine.apply(curve: curve, sampleRate: sampleRate)
        lock.unlock()
    }

    func render(
        frameCount: AVAudioFrameCount,
        into audioBufferList: UnsafeMutablePointer<AudioBufferList>
    ) {
        let abl = UnsafeMutableAudioBufferListPointer(audioBufferList)
        lock.lock()
        let mode = self.mode
        let sr = self.sampleRate
        for buffer in abl {
            guard let data = buffer.mData?.assumingMemoryBound(to: Float.self) else { continue }
            let n = Int(frameCount)
            for i in 0..<n {
                let raw: Float
                switch mode {
                case .noise:
                    noiseState = noiseState &* 636_413_622_384_679_3005 &+ 1
                    let unit = Float(noiseState >> 40) / Float(1 << 24)
                    raw = (unit * 2 - 1) * 0.18
                case .sweep:
                    phase += 1
                    let t = phase / sr
                    // Log sweep ~60 Hz → 12 kHz. Amplitude kept comfortable but
                    // high enough for Built-in mic in a quiet room (pass-3 honesty).
                    let f = 60.0 * pow(200.0, (t.truncatingRemainder(dividingBy: 2.5)) / 2.5)
                    let ang = 2 * Double.pi * f * t
                    raw = Float(0.22 * sin(ang))
                }
                data[i] = eqEngine.process(raw)
            }
        }
        lock.unlock()
    }
}

/// Builds the source node off the MainActor so the render closure is not
/// actor-isolated (Swift 6 would otherwise trap on the audio IO thread).
private enum InAppEQSourceNodeFactory {
    nonisolated static func make(state: InAppEQRenderState) -> AVAudioSourceNode {
        AVAudioSourceNode { _, _, frameCount, audioBufferList -> OSStatus in
            state.render(frameCount: frameCount, into: audioBufferList)
            return noErr
        }
    }
}

/// In-app audition path: pinkish noise / sweep through `EQEngine`.
/// Proves Narrow / Measure / Custom change audible output before/alongside system-wide host.
@MainActor
final class InAppEQPlayer: ObservableObject {
    @Published private(set) var isPlaying = false

    private let engine = AVAudioEngine()
    private var sourceNode: AVAudioSourceNode?
    private let renderState = InAppEQRenderState()

    func apply(curve: EQCurve) {
        renderState.apply(curve: curve)
    }

    func setBypassed(_ bypassed: Bool, baseCurve: EQCurve) {
        var curve = baseCurve
        curve.bypassed = bypassed
        apply(curve: curve)
    }

    func start(mode: InAppEQPlayMode = .noise, curve: EQCurve) throws {
        stop()

        let output = engine.outputNode
        let format = output.outputFormat(forBus: 0)
        let sr = format.sampleRate > 0 ? format.sampleRate : 48_000
        renderState.configure(mode: mode, sampleRate: sr, curve: curve)

        let node = InAppEQSourceNodeFactory.make(state: renderState)
        sourceNode = node
        engine.attach(node)
        engine.connect(node, to: engine.mainMixerNode, format: format)
        engine.mainMixerNode.outputVolume = 0.9
        try engine.start()
        isPlaying = true
    }

    func stop() {
        engine.stop()
        if let sourceNode {
            engine.disconnectNodeOutput(sourceNode)
            engine.detach(sourceNode)
        }
        sourceNode = nil
        isPlaying = false
        renderState.resetPhase()
    }
}
