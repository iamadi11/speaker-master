import AVFoundation
import Foundation
import SpeakerMaster

/// In-app audition path: pinkish noise / sweep through `EQEngine`.
/// Proves Narrow / Measure / Custom change audible output before/alongside system-wide host.
@MainActor
final class InAppEQPlayer: ObservableObject {
    @Published private(set) var isPlaying = false

    private let engine = AVAudioEngine()
    private var sourceNode: AVAudioSourceNode?
    private var eqEngine = EQEngine(sampleRate: 48_000, curve: .flat)
    private var phase: Double = 0
    private var sampleRate: Double = 48_000
    private var mode: Mode = .noise
    private let lock = NSLock()

    enum Mode {
        case noise
        case sweep
    }

    func apply(curve: EQCurve) {
        lock.lock()
        eqEngine.apply(curve: curve, sampleRate: sampleRate)
        lock.unlock()
    }

    func setBypassed(_ bypassed: Bool, baseCurve: EQCurve) {
        var curve = baseCurve
        curve.bypassed = bypassed
        apply(curve: curve)
    }

    func start(mode: Mode = .noise, curve: EQCurve) throws {
        stop()
        self.mode = mode
        apply(curve: curve)

        let output = engine.outputNode
        let format = output.outputFormat(forBus: 0)
        sampleRate = format.sampleRate > 0 ? format.sampleRate : 48_000
        apply(curve: curve)

        let node = AVAudioSourceNode { [weak self] _, _, frameCount, audioBufferList -> OSStatus in
            guard let self else { return noErr }
            let abl = UnsafeMutableAudioBufferListPointer(audioBufferList)
            for buffer in abl {
                guard let data = buffer.mData?.assumingMemoryBound(to: Float.self) else { continue }
                let n = Int(frameCount)
                self.lock.lock()
                for i in 0..<n {
                    let raw: Float
                    switch self.mode {
                    case .noise:
                        raw = Float.random(in: -0.18...0.18)
                    case .sweep:
                        // Log sweep 60 Hz → 12 kHz over ~2 s
                        self.phase += 1
                        let t = self.phase / self.sampleRate
                        let f = 60.0 * pow(200.0, (t.truncatingRemainder(dividingBy: 2.0)) / 2.0)
                        let ang = 2 * Double.pi * f * t
                        raw = Float(0.15 * sin(ang))
                    }
                    data[i] = self.eqEngine.process(raw)
                }
                self.lock.unlock()
            }
            return noErr
        }

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
        phase = 0
    }
}
