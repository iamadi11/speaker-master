import AVFoundation
import Foundation
import SpeakerMaster

struct MicDevice: Identifiable, Hashable {
    var id: String
    var name: String
}

@MainActor
final class MicRecorder: ObservableObject {
    @Published private(set) var devices: [MicDevice] = []
    @Published var selectedDeviceID: String?
    @Published private(set) var permission: AVAuthorizationStatus = .notDetermined
    @Published private(set) var isRecording = false

    private var engine: AVAudioEngine?
    private var samples: [Float] = []
    private var sampleRate: Double = 48_000

    init() {
        permission = AVCaptureDevice.authorizationStatus(for: .audio)
        refreshDevices()
    }

    func refreshDevices() {
        let list = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.microphone, .external],
            mediaType: .audio,
            position: .unspecified
        ).devices.map { MicDevice(id: $0.uniqueID, name: $0.localizedName) }
        devices = list
        if selectedDeviceID == nil {
            selectedDeviceID = list.first?.id
        }
    }

    func requestPermission() async -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        if status == .authorized {
            permission = status
            return true
        }
        let granted = await AVCaptureDevice.requestAccess(for: .audio)
        permission = AVCaptureDevice.authorizationStatus(for: .audio)
        refreshDevices()
        return granted
    }

    /// Play stimulus via `player` while capturing mic for `duration`.
    func recordWhilePlaying(
        duration: TimeInterval,
        player: InAppEQPlayer,
        stimulusCurve: EQCurve
    ) async throws -> (samples: [Float], sampleRate: Double) {
        samples = []
        let engine = AVAudioEngine()
        self.engine = engine
        let input = engine.inputNode
        let format = input.inputFormat(forBus: 0)
        sampleRate = format.sampleRate > 0 ? format.sampleRate : 48_000

        input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            guard let channel = buffer.floatChannelData?[0] else { return }
            let count = Int(buffer.frameLength)
            let chunk = Array(UnsafeBufferPointer(start: channel, count: count))
            Task { @MainActor in
                self?.samples.append(contentsOf: chunk)
            }
        }

        try engine.start()
        isRecording = true
        try player.start(mode: .sweep, curve: stimulusCurve)

        try await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))

        player.stop()
        input.removeTap(onBus: 0)
        engine.stop()
        isRecording = false
        self.engine = nil

        let captured = samples
        samples = []
        return (captured, sampleRate)
    }
}
