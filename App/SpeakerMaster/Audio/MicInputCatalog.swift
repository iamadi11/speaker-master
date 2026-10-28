import CoreAudio
import Foundation

/// HAL input enumeration for Measure. Prefer this over AVCaptureDevice.DiscoverySession:
/// same UIDs as `MicRecorder` binding, and lists inputs even when AVCapture returns [].
enum MicInputCatalog {
    /// Devices with at least one input stream that can act as a **room mic** for Measure.
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
        var outputTwinBases = Set<String>()

        // First pass: remember Bluetooth/USB output twin bases so speaker `:input`
        // endpoints (e.g. ULT FIELD 1) can be excluded from Measure.
        for deviceID in deviceIDs {
            guard let uid = CoreAudioDeviceLookup.stringProperty(
                deviceID,
                kAudioDevicePropertyDeviceUID
            ), !uid.isEmpty else { continue }
            if uid.hasSuffix(":output") {
                outputTwinBases.insert(String(uid.dropLast(":output".count)))
            }
        }

        for deviceID in deviceIDs {
            guard CoreAudioDeviceLookup.inputStreamCount(for: deviceID) > 0 else { continue }
            guard let uid = CoreAudioDeviceLookup.stringProperty(
                deviceID,
                kAudioDevicePropertyDeviceUID
            ), !uid.isEmpty else { continue }
            guard seen.insert(uid).inserted else { continue }

            let name = CoreAudioDeviceLookup.stringProperty(
                deviceID,
                kAudioObjectPropertyName
            ) ?? uid
            // Skip process-tap / system aggregates — not room mics for Measure.
            if uid.hasPrefix("com.iamadi11.SpeakerMaster.agg") { continue }
            if uid.hasPrefix("CADefaultDeviceAggregate") { continue }
            if name.lowercased().contains("aggregate") { continue }

            let device = MicDevice(id: uid, name: name)
            guard isMeasureMicCandidate(device, outputTwinBases: outputTwinBases) else { continue }

            result.append(device)
        }

        return result.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    /// Keep Built-in / Continuity / headset mics; drop speaker playback `:input` twins.
    static func isMeasureMicCandidate(
        _ device: MicDevice,
        outputTwinBases: Set<String>
    ) -> Bool {
        let name = device.name.lowercased()
        let uid = device.id

        if uid == "BuiltInMicrophoneDevice" { return true }
        if name.contains("microphone") || name.contains("mic ") || name.hasSuffix(" mic") {
            return true
        }
        if name.contains("airpods")
            || name.contains("headset")
            || name.contains("earbuds")
            || name.contains("buds")
        {
            return true
        }
        if name.contains("iphone") || name.contains("ipad") || name.contains("continuity") {
            return true
        }

        // I/O pair: `MAC:input` beside `MAC:output` (e.g. ULT FIELD 1). Not a room mic —
        // Measure on these yields empty/weak takes. Headset/AirPods already returned above.
        if uid.hasSuffix(":input") {
            let base = String(uid.dropLast(":input".count))
            if outputTwinBases.contains(base) { return false }
        }

        return true
    }
}
