import AVFoundation
import CoreAudio
import Foundation
import SpeakerMaster

struct MicDevice: Identifiable, Hashable {
    var id: String
    var name: String
}

/// File-scoped so the AVAudioEngine tap never closes over a MainActor type.
private final class MicSampleBuffer: @unchecked Sendable {
    private let lock = NSLock()
    private var values: [Float] = []

    init(capacity: Int) {
        values.reserveCapacity(capacity)
    }

    func append(_ chunk: UnsafePointer<Float>, count: Int) {
        guard count > 0 else { return }
        lock.lock()
        values.append(contentsOf: UnsafeBufferPointer(start: chunk, count: count))
        lock.unlock()
    }

    func snapshot() -> [Float] {
        lock.lock()
        defer { lock.unlock() }
        return values
    }
}

/// Install tap off the MainActor — Swift 6 isolates closures created inside
/// `@MainActor` methods, which traps on `RealtimeMessenger.mServiceQueue`.
private enum MicTapFactory {
    nonisolated static func install(
        on input: AVAudioInputNode,
        format: AVAudioFormat,
        buffer: MicSampleBuffer
    ) {
        input.installTap(onBus: 0, bufferSize: 1024, format: format) { buf, _ in
            guard let channel = buf.floatChannelData?[0] else { return }
            buffer.append(channel, count: Int(buf.frameLength))
        }
    }
}

enum MicRecorderError: LocalizedError {
    case noDeviceSelected
    case deviceNotInput(String)
    case cannotBindInput(String)
    case engineStartFailed(String)
    case emptyCapture(String)

    var errorDescription: String? {
        switch self {
        case .noDeviceSelected:
            return "Select a microphone first"
        case .deviceNotInput(let name):
            return "“\(name)” has no input streams — pick another mic"
        case .cannotBindInput(let detail):
            return "Could not use that mic (\(detail))"
        case .engineStartFailed(let detail):
            return "Mic engine failed to start (\(detail))"
        case .emptyCapture(let name):
            return "“\(name)” returned no audio — try Built-in Microphone, or refresh and re-select"
        }
    }
}

@MainActor
final class MicRecorder: ObservableObject {
    private static let lastMicKey = "speaker-master.lastMicUID"

    @Published private(set) var devices: [MicDevice] = []
    @Published var selectedDeviceID: String? {
        didSet {
            if let selectedDeviceID {
                UserDefaults.standard.set(selectedDeviceID, forKey: Self.lastMicKey)
            }
        }
    }
    @Published private(set) var permission: AVAuthorizationStatus = .notDetermined
    @Published private(set) var isRecording = false
    /// Rough peak of the latest capture (0…1) for UI honesty after a run.
    @Published private(set) var lastPeakLinear: Float = 0

    private var engine: AVAudioEngine?
    private var samples: [Float] = []
    private var sampleRate: Double = 48_000
    private var tapInstalled = false

    init() {
        permission = Self.currentPermission()
        refreshDevices()
    }

    /// Re-read HAL inputs and clamp selection to a live UID.
    func refreshDevices() {
        let list = MicInputCatalog.listInputs()
        devices = list

        let remembered = UserDefaults.standard.string(forKey: Self.lastMicKey)
        if let remembered, list.contains(where: { $0.id == remembered }) {
            selectedDeviceID = remembered
        } else if let current = selectedDeviceID, list.contains(where: { $0.id == current }) {
            // keep current selection
        } else {
            selectedDeviceID = Self.preferredInputID(from: list)
        }
    }

    /// Prefer a local Mac mic over Continuity/iPhone for first-run Measure reliability.
    static func preferredInputID(from list: [MicDevice]) -> String? {
        if let builtIn = list.first(where: { $0.id == "BuiltInMicrophoneDevice" }) {
            return builtIn.id
        }
        if let macBook = list.first(where: {
            let name = $0.name.lowercased()
            return name.contains("macbook") && name.contains("microphone")
        }) {
            return macBook.id
        }
        if let local = list.first(where: { !looksLikeContinuityMic($0) }) {
            return local.id
        }
        return list.first?.id
    }

    static func looksLikeContinuityMic(_ device: MicDevice) -> Bool {
        let name = device.name.lowercased()
        return name.contains("iphone") || name.contains("ipad") || name.contains("continuity")
    }

    /// Smoke / recovery helper — select Built-in when present without wiping user memory forever.
    func preferBuiltInMicrophoneIfAvailable() {
        if let builtIn = devices.first(where: { $0.id == "BuiltInMicrophoneDevice" }) {
            selectedDeviceID = builtIn.id
        } else if let preferred = Self.preferredInputID(from: devices) {
            selectedDeviceID = preferred
        }
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
    /// Samples stay in memory only; cleared after return (no durable capture files).
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

        samples = []
        lastPeakLinear = 0
        let engine = AVAudioEngine()
        self.engine = engine

        do {
            try Self.bindInputDevice(deviceID, on: engine)
        } catch {
            cleanupEngine()
            throw MicRecorderError.cannotBindInput(error.localizedDescription)
        }

        engine.prepare()
        let input = engine.inputNode
        let format = input.inputFormat(forBus: 0)
        sampleRate = format.sampleRate > 0 ? format.sampleRate : 48_000

        // Shared buffer: audio thread appends; MainActor reads only after tap removed + engine stopped.
        let buffer = MicSampleBuffer(capacity: Int(sampleRate * duration) + 4096)
        MicTapFactory.install(on: input, format: format, buffer: buffer)
        tapInstalled = true

        do {
            try engine.start()
        } catch {
            cleanupEngine()
            throw MicRecorderError.engineStartFailed(error.localizedDescription)
        }
        isRecording = true
        // Brief settle so the input tap is delivering buffers before the sweep.
        try await Task.sleep(nanoseconds: 180_000_000)

        do {
            try player.start(mode: .sweep, curve: stimulusCurve)
        } catch {
            cleanupEngine()
            throw error
        }

        try await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))

        player.stop()
        cleanupEngine()

        let captured = buffer.snapshot()
        samples = []
        lastPeakLinear = captured.map { abs($0) }.max() ?? 0
        // Empty buffer after a "successful" start is an infrastructure failure, not a room take.
        if captured.isEmpty {
            throw MicRecorderError.emptyCapture(displayName)
        }
        return (captured, sampleRate)
    }

    private func cleanupEngine() {
        if let engine {
            if tapInstalled {
                engine.inputNode.removeTap(onBus: 0)
                tapInstalled = false
            }
            engine.stop()
        }
        engine = nil
        isRecording = false
    }

    /// Bind HAL input device to `AVAudioEngine`’s input node (macOS).
    private static func bindInputDevice(_ deviceID: AudioDeviceID, on engine: AVAudioEngine) throws {
        guard let audioUnit = engine.inputNode.audioUnit else {
            throw MicRecorderError.cannotBindInput("missing input AudioUnit")
        }
        var id = deviceID
        let status = AudioUnitSetProperty(
            audioUnit,
            kAudioOutputUnitProperty_CurrentDevice,
            kAudioUnitScope_Global,
            0,
            &id,
            UInt32(MemoryLayout<AudioDeviceID>.size)
        )
        try CoreAudioDeviceLookup.check(status, operation: "set CurrentDevice on input")
    }
}
