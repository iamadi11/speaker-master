import CoreAudio
import Foundation

enum CoreAudioDeviceLookup {
    enum LookupError: Error, LocalizedError {
        case deviceNotFound(String)
        case propertyFailed(String, OSStatus)

        var errorDescription: String? {
            switch self {
            case .deviceNotFound(let uid):
                return "Audio device not found: \(uid)"
            case .propertyFailed(let op, let status):
                return "\(op) failed (\(status))"
            }
        }
    }

    static func resolveDeviceID(uid: String) throws -> AudioObjectID {
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
        guard status == noErr else {
            throw LookupError.propertyFailed("devices size", status)
        }
        let count = Int(size) / MemoryLayout<AudioObjectID>.size
        var devices = [AudioObjectID](repeating: 0, count: count)
        status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &size,
            &devices
        )
        guard status == noErr else {
            throw LookupError.propertyFailed("devices list", status)
        }
        for device in devices {
            if stringProperty(device, kAudioDevicePropertyDeviceUID) == uid {
                return device
            }
        }
        throw LookupError.deviceNotFound(uid)
    }

    static func uid(for deviceID: AudioObjectID) throws -> String {
        guard let uid = stringProperty(deviceID, kAudioDevicePropertyDeviceUID) else {
            throw LookupError.propertyFailed("device UID", -1)
        }
        return uid
    }

    static func sampleRate(for deviceID: AudioObjectID) -> Double {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyNominalSampleRate,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var rate: Float64 = 0
        var size = UInt32(MemoryLayout<Float64>.size)
        let status = AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, &rate)
        return status == noErr ? rate : 0
    }

    static func inputStreamCount(for deviceID: AudioObjectID) -> Int {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreams,
            mScope: kAudioObjectPropertyScopeInput,
            mElement: kAudioObjectPropertyElementMain
        )
        var size: UInt32 = 0
        let status = AudioObjectGetPropertyDataSize(deviceID, &address, 0, nil, &size)
        guard status == noErr else { return 0 }
        return Int(size) / MemoryLayout<AudioObjectID>.size
    }

    static func stringProperty(
        _ device: AudioObjectID,
        _ selector: AudioObjectPropertySelector
    ) -> String? {
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

    static func check(_ status: OSStatus, operation: String) throws {
        guard status == noErr else {
            throw LookupError.propertyFailed(operation, status)
        }
    }
}
