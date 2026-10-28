import AudioToolbox
import CoreAudio
import Foundation
import SpeakerMaster

/// Owns tap lifecycle and applies `StereoEQEngine` inside the aggregate IOProc.
/// Cross-thread by design (UI → start/stop/apply; realtime IOProc → process).
final class ProcessTapEngine: ProcessTapCapture.RenderTarget, @unchecked Sendable {
    private static let scratchFrames = 16_384

    private let capture = ProcessTapCapture()
    private let lock = NSLock()
    private var stereo = StereoEQEngine(sampleRate: 48_000, curve: .flat)
    private var sampleRate: Double = 48_000

    private let scratch = UnsafeMutablePointer<Float>.allocate(
        capacity: ProcessTapEngine.scratchFrames * 2
    )
    private(set) var isRunning = false

    deinit {
        capture.stop()
        scratch.deallocate()
    }

    /// Blocking — call off the main actor.
    func start(outputUID: String, curve: EQCurve) throws {
        stop()
        let deviceID = try CoreAudioDeviceLookup.resolveDeviceID(uid: outputUID)
        let reported = CoreAudioDeviceLookup.sampleRate(for: deviceID)
        lock.lock()
        sampleRate = reported > 0 ? reported : 48_000
        stereo.apply(curve: curve, sampleRate: sampleRate)
        lock.unlock()
        isRunning = true
        do {
            try capture.start(outputDeviceID: deviceID, renderTarget: self)
        } catch {
            isRunning = false
            capture.stop()
            throw error
        }
    }

    func stop() {
        capture.stop()
        isRunning = false
    }

    func apply(curve: EQCurve) {
        lock.lock()
        stereo.apply(curve: curve, sampleRate: sampleRate)
        lock.unlock()
    }

    nonisolated func handleUnifiedRender(
        inputData: UnsafePointer<AudioBufferList>,
        outputData: UnsafeMutablePointer<AudioBufferList>,
        tapStreamCount: Int
    ) {
        smZeroFillAudioBuffers(outputData)
        let outputBuffers = UnsafeMutableAudioBufferListPointer(outputData)
        let capacity = smWritableFrameCapacity(outputBuffers)
        guard capacity > 0 else { return }

        let inputCount = Int(inputData.pointee.mNumberBuffers)
        let tapStart = smTapBufferStartIndex(bufferCount: inputCount, tapStreamCount: tapStreamCount)
        let frameLimit = min(capacity, Self.scratchFrames)
        let frameCount = smNormalizeToInterleavedStereo(
            inputData,
            into: scratch,
            maxFrames: frameLimit,
            startingAtBuffer: tapStart
        )
        guard frameCount > 0 else { return }

        lock.lock()
        stereo.processInterleaved(scratch, frameCount: frameCount)
        lock.unlock()

        smWriteInterleavedStereo(scratch, frameCount: frameCount, to: outputBuffers)
    }
}
