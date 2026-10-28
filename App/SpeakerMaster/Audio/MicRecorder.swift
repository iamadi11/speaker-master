import AVFoundation
import CoreAudio
import Foundation
import SpeakerMaster

struct MicDevice: Identifiable, Hashable {
    var id: String
    var name: String
}

enum MicRecorderError: LocalizedError, Equatable {
    case noDeviceSelected
    case deviceNotInput(String)
    case cannotBindInput(String)
    case engineStartFailed(String)
    case emptyCapture(String)
    case cancelled

    var errorDescription: String? {
        switch self {
        case .noDeviceSelected:
            return "Select a microphone first"
        case .deviceNotInput(let name):
            return "“\(name)” has no input streams — pick another mic"
        case .cannotBindInput(let detail):
            return "Could not use that mic (\(detail))"
        case .engineStartFailed(let detail):
            return "Mic capture failed to start (\(detail))"
        case .emptyCapture(let name):
            return "“\(name)” returned no audio — try Built-in Microphone, or refresh and re-select"
        case .cancelled:
            return "Measure cancelled"
        }
    }
}

@MainActor
final class MicRecorder: ObservableObject {
    private static let lastMicKey = "speaker-master.lastMicUID"

    @Published private(set) var devices: [MicDevice] = []
    @Published var selectedDeviceID: String? {
        didSet {
            persistLastMicIfAppropriate(selectedDeviceID)
        }
    }
    @Published private(set) var permission: AVAuthorizationStatus = .notDetermined
    @Published private(set) var isRecording = false
    /// Rough peak of the latest capture (0…1) for UI honesty after a run.
    @Published private(set) var lastPeakLinear: Float = 0

    init() {
        permission = Self.currentPermission()
        refreshDevices()
    }

    /// Re-read HAL inputs and clamp selection to a live UID.
    /// Continuity is never sticky across launches when a local mic exists.
    func refreshDevices() {
        let list = MicInputCatalog.listInputs()
        devices = list

        let remembered = UserDefaults.standard.string(forKey: Self.lastMicKey)
        // Drop legacy Continuity sticky defaults so Built-in wins on next launch.
        if let remembered,
           let name = list.first(where: { $0.id == remembered })?.name,
           !MicSelectionPolicy.shouldPersistAsLastMic(name: name)
        {
            UserDefaults.standard.removeObject(forKey: Self.lastMicKey)
        }

        let policyDevices = list.map { MicSelectionPolicy.Device(id: $0.id, name: $0.name) }
        selectedDeviceID = MicSelectionPolicy.resolveSelection(
            devices: policyDevices,
            rememberedID: UserDefaults.standard.string(forKey: Self.lastMicKey),
            currentID: selectedDeviceID
        )
    }

    /// Prefer a local Mac mic over Continuity/iPhone for first-run Measure reliability.
    static func preferredInputID(from list: [MicDevice]) -> String? {
        MicSelectionPolicy.preferredInputID(
            from: list.map { MicSelectionPolicy.Device(id: $0.id, name: $0.name) }
        )
    }

    static func looksLikeContinuityMic(_ device: MicDevice) -> Bool {
        MicSelectionPolicy.looksLikeContinuityMic(name: device.name)
    }

    var selectedDeviceLooksLikeContinuity: Bool {
        guard let id = selectedDeviceID,
              let device = devices.first(where: { $0.id == id })
        else { return false }
        return Self.looksLikeContinuityMic(device)
    }

    /// Smoke / recovery helper — select Built-in when present; clear Continuity sticky.
    func preferBuiltInMicrophoneIfAvailable() {
        clearStickyContinuityDefault()
        if let builtIn = devices.first(where: { $0.id == "BuiltInMicrophoneDevice" }) {
            selectedDeviceID = builtIn.id
        } else if let preferred = Self.preferredInputID(from: devices) {
            selectedDeviceID = preferred
        }
    }

    /// After Continuity empty capture — snap to Built-in and forget Continuity sticky.
    func recoverFromContinuityEmptyCapture() {
        preferBuiltInMicrophoneIfAvailable()
    }

    private func clearStickyContinuityDefault() {
        guard let remembered = UserDefaults.standard.string(forKey: Self.lastMicKey) else { return }
        if let name = devices.first(where: { $0.id == remembered })?.name,
           !MicSelectionPolicy.shouldPersistAsLastMic(name: name)
        {
            UserDefaults.standard.removeObject(forKey: Self.lastMicKey)
            return
        }
        // Legacy sticky Continuity UID may not be in the live list anymore.
        if remembered.lowercased().contains("iphone")
            || remembered.lowercased().contains("ipad")
            || remembered.lowercased().contains("continuity")
        {
            UserDefaults.standard.removeObject(forKey: Self.lastMicKey)
        }
    }

    private func persistLastMicIfAppropriate(_ uid: String?) {
        guard let uid else { return }
        let name = devices.first(where: { $0.id == uid })?.name ?? uid
        if MicSelectionPolicy.shouldPersistAsLastMic(name: name) {
            UserDefaults.standard.set(uid, forKey: Self.lastMicKey)
        }
        // Continuity: session-only — do not write sticky default.
    }

    /// Prefer `AVAudioApplication` (HAL / AVAudioEngine record path) and keep
    /// `AVCaptureDevice` in sync — either denied blocks Measure capture.
    func requestPermission() async -> Bool {
        permission = Self.currentPermission()
        if permission == .authorized {
            refreshDevices()
            return true
        }
        if permission == .denied || permission == .restricted {
            refreshDevices()
            return false
        }

        let audioGranted = await Self.requestAudioApplicationPermission()
        let captureGranted = await AVCaptureDevice.requestAccess(for: .audio)
        permission = Self.currentPermission()
        refreshDevices()
        return audioGranted && captureGranted && permission == .authorized
    }

    var isAuthorizedForCapture: Bool {
        permission == .authorized
    }

    private static func currentPermission() -> AVAuthorizationStatus {
        let capture = AVCaptureDevice.authorizationStatus(for: .audio)
        let audio = AVAudioApplication.shared.recordPermission
        switch audio {
        case .granted:
            return capture == .denied || capture == .restricted ? capture : .authorized
        case .denied:
            return .denied
        case .undetermined:
            return capture
        @unknown default:
            return capture
        }
    }

    private static func requestAudioApplicationPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    /// Play stimulus via `player` while capturing the **user-selected** mic for `duration`.
    ///
    /// Uses `AVAudioRecorder` (not a second `AVAudioEngine` input). Two AVAudioEngines
    /// on this Mac starve the input tap to empty buffers — verified in gap-fix.
    /// Temp WAV is deleted after load (no durable capture files).
    func recordWhilePlaying(
        duration: TimeInterval,
        player: InAppEQPlayer,
        stimulusCurve: EQCurve
    ) async throws -> (samples: [Float], sampleRate: Double) {
        guard let uid = selectedDeviceID else {
            throw MicRecorderError.noDeviceSelected
        }
        let displayName = devices.first(where: { $0.id == uid })?.name ?? uid
        let deviceID: AudioDeviceID
        do {
            deviceID = try CoreAudioDeviceLookup.resolveDeviceID(uid: uid)
        } catch {
            throw MicRecorderError.cannotBindInput(error.localizedDescription)
        }
        guard CoreAudioDeviceLookup.inputStreamCount(for: deviceID) > 0 else {
            throw MicRecorderError.deviceNotInput(displayName)
        }

        player.stop()
        lastPeakLinear = 0

        let previousDefault = Self.defaultInputDeviceID()
        do {
            try Self.setDefaultInputDeviceID(deviceID)
        } catch {
            throw MicRecorderError.cannotBindInput(error.localizedDescription)
        }
        defer {
            if let previousDefault {
                try? Self.setDefaultInputDeviceID(previousDefault)
            }
        }

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("speaker-master-measure-\(UUID().uuidString).wav")
        defer { try? FileManager.default.removeItem(at: url) }

        let sampleRateHint = CoreAudioDeviceLookup.sampleRate(for: deviceID)
        let rate = sampleRateHint > 0 ? sampleRateHint : 48_000
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: rate,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 32,
            AVLinearPCMIsFloatKey: true,
            AVLinearPCMIsNonInterleaved: false,
        ]

        let recorder: AVAudioRecorder
        do {
            recorder = try AVAudioRecorder(url: url, settings: settings)
        } catch {
            throw MicRecorderError.engineStartFailed(error.localizedDescription)
        }
        guard recorder.prepareToRecord() else {
            throw MicRecorderError.engineStartFailed("prepareToRecord returned false")
        }

        isRecording = true
        defer { isRecording = false }

        guard recorder.record() else {
            throw MicRecorderError.engineStartFailed("record() returned false")
        }

        do {
            // Short pre-settle so AVAudioRecorder / default-input bind stabilize before stimulus.
            try await Self.sleepCheckingCancellation(seconds: 0.25)

            do {
                try player.start(mode: .sweep, curve: stimulusCurve)
            } catch {
                recorder.stop()
                throw error
            }

            try await Self.sleepCheckingCancellation(seconds: duration)

            player.stop()
            // Brief post-settle captures room ring without truncating the sweep body.
            try await Self.sleepCheckingCancellation(seconds: 0.15)
            recorder.stop()
        } catch is CancellationError {
            player.stop()
            recorder.stop()
            throw MicRecorderError.cancelled
        } catch {
            player.stop()
            recorder.stop()
            throw error
        }

        let captured: [Float]
        let fileRate: Double
        do {
            (captured, fileRate) = try Self.loadMonoFloats(from: url)
        } catch {
            throw MicRecorderError.engineStartFailed(error.localizedDescription)
        }

        lastPeakLinear = captured.map { abs($0) }.max() ?? 0
        if captured.isEmpty {
            throw MicRecorderError.emptyCapture(displayName)
        }
        return (captured, fileRate)
    }

    /// Slice sleeps so Cancel can abort mid-sweep without waiting for the full duration.
    private static func sleepCheckingCancellation(seconds: TimeInterval) async throws {
        var remaining = max(0, seconds)
        let slice: TimeInterval = 0.05
        while remaining > 0 {
            try Task.checkCancellation()
            let step = min(slice, remaining)
            try await Task.sleep(nanoseconds: UInt64(step * 1_000_000_000))
            remaining -= step
        }
    }

    // MARK: - Default input (AVAudioRecorder listens here)

    private static func defaultInputDeviceID() -> AudioDeviceID? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var deviceID = AudioDeviceID(0)
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &size,
            &deviceID
        )
        return status == noErr && deviceID != 0 ? deviceID : nil
    }

    private static func setDefaultInputDeviceID(_ deviceID: AudioDeviceID) throws {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var id = deviceID
        let status = AudioObjectSetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            UInt32(MemoryLayout<AudioDeviceID>.size),
            &id
        )
        try CoreAudioDeviceLookup.check(status, operation: "set default input device")
    }

    private static func loadMonoFloats(from url: URL) throws -> ([Float], Double) {
        let file = try AVAudioFile(forReading: url)
        let format = file.processingFormat
        let frameCount = AVAudioFrameCount(file.length)
        guard frameCount > 0,
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)
        else {
            return ([], format.sampleRate)
        }
        try file.read(into: buffer)
        let frames = Int(buffer.frameLength)
        guard frames > 0 else { return ([], format.sampleRate) }

        if let channel = buffer.floatChannelData?[0] {
            return (Array(UnsafeBufferPointer(start: channel, count: frames)), format.sampleRate)
        }
        return ([], format.sampleRate)
    }
}
