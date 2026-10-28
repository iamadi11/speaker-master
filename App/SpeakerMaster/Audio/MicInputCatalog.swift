import CoreAudio
import Foundation

/// HAL input enumeration for Measure. Prefer this over AVCaptureDevice.DiscoverySession:
/// same UIDs as `MicRecorder` binding, and lists inputs even when AVCapture returns [].
enum MicInputCatalog {
    /// Devices with at least one input stream (built-in, USB, Continuity, etc.).
    static func listInputs() -> [MicDevice] {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var size: UInt32 = 0
        var status = AudioObjectGetPropertyDataSize(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &size
        )
        guard status == noErr else { return [] }

        let count = Int(size) / MemoryLayout<AudioObjectID>.size
        guard count > 0 else { return [] }

        var deviceIDs = [AudioObjectID](repeating: 0, count: count)
        status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &size,
            &deviceIDs
        )
        guard status == noErr else { return [] }

        var result: [MicDevice] = []
        result.reserveCapacity(count)
        var seen = Set<String>()

        for deviceID in deviceIDs {
            guard CoreAudioDeviceLookup.inputStreamCount(for: deviceID) > 0 else { continue }
            guard let uid = CoreAudioDeviceLookup.stringProperty(
                deviceID,
                kAudioDevicePropertyDeviceUID
            ), !uid.isEmpty else { continue }
            guard seen.insert(uid).inserted else { continue }

            // Skip our process-tap aggregate — not a room mic for Measure.
            if uid.hasPrefix("com.iamadi11.SpeakerMaster.agg") { continue }

            let name = CoreAudioDeviceLookup.stringProperty(
                deviceID,
                kAudioObjectPropertyName
            ) ?? uid
            result.append(MicDevice(id: uid, name: name))
        }

        return result.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}
