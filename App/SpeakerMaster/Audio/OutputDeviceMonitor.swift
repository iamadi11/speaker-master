import CoreAudio
import Foundation
import SpeakerMaster

/// Tracks the default output device (speaker identity for persistence).
@MainActor
final class OutputDeviceMonitor: ObservableObject {
    @Published private(set) var identity: SpeakerIdentity = SpeakerIdentity(
        outputUID: "unknown",
        displayName: "No output"
    )

    private var listenerBlock: AudioObjectPropertyListenerBlock?

    init() {
        refresh()
        startListening()
    }

    deinit {
        // Listener cleanup best-effort; property address lives for process life in v1.
    }

    func refresh() {
        identity = Self.currentDefaultOutput()
    }

    private func startListening() {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        let block: AudioObjectPropertyListenerBlock = { [weak self] _, _ in
            Task { @MainActor in
                self?.refresh()
            }
        }
        listenerBlock = block
        AudioObjectAddPropertyListenerBlock(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            DispatchQueue.main,
            block
        )
    }

    static func currentDefaultOutput() -> SpeakerIdentity {
        var deviceID = AudioDeviceID(0)
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &size,
            &deviceID
        )
        guard status == noErr, deviceID != 0 else {
            return SpeakerIdentity(outputUID: "unknown", displayName: "No output")
        }
        let name = stringProperty(deviceID, kAudioObjectPropertyName) ?? "Output \(deviceID)"
        let uid = stringProperty(deviceID, kAudioDevicePropertyDeviceUID) ?? "dev-\(deviceID)"
        return SpeakerIdentity(outputUID: uid, displayName: name)
    }

    private static func stringProperty(_ device: AudioDeviceID, _ selector: AudioObjectPropertySelector) -> String? {
        var address = AudioObjectPropertyAddress(
            mSelector: selector,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var size: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(device, &address, 0, nil, &size) == noErr else {
            return nil
        }
        let ptr = UnsafeMutablePointer<CFString?>.allocate(capacity: 1)
        defer { ptr.deallocate() }
        ptr.initialize(to: nil)
        guard AudioObjectGetPropertyData(device, &address, 0, nil, &size, ptr) == noErr,
              let cf = ptr.pointee
        else {
            return nil
        }
        return cf as String
    }
}
