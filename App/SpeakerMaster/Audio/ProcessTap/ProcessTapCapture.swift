import AudioToolbox
import CoreAudio
import Foundation
import os.log

/// Single-clock process tap + private aggregate + one IOProc.
///
/// Topology (macOS 14.2+): device-scoped muted tap + physical output in ONE private
/// aggregate (output = clock master, max drift compensation on tap). Prevents the
/// Bluetooth pitch-warble of two-clock ring designs. Crash-safe: destroying the tap
/// restores normal playback (no stuck virtual device).
///
/// Architecture reference: Apple “Capturing system audio with Core Audio taps”
/// sample + public MIT CoreAudioTapKit single-clock design notes.
nonisolated final class ProcessTapCapture {
    enum CaptureError: Error, LocalizedError {
        case unsupportedOS
        case permissionDenied
        case coreAudio(String, OSStatus)

        var errorDescription: String? {
            switch self {
            case .unsupportedOS:
                return "System-wide EQ needs macOS 14.2 or newer."
            case .permissionDenied:
                return "Screen & System Audio Recording permission is required."
            case .coreAudio(let op, let status):
                return "\(op) failed (\(status))"
            }
        }
    }

    protocol RenderTarget: AnyObject {
        func handleUnifiedRender(
            inputData: UnsafePointer<AudioBufferList>,
            outputData: UnsafeMutablePointer<AudioBufferList>,
            tapStreamCount: Int
        )
    }

    private let logger = Logger(subsystem: "com.iamadi11.SpeakerMaster", category: "ProcessTap")

    nonisolated(unsafe) private var tapID: AudioObjectID = AudioObjectID(kAudioObjectUnknown)
    nonisolated(unsafe) private var aggregateDeviceID: AudioObjectID = AudioObjectID(kAudioObjectUnknown)
    nonisolated(unsafe) private var aggregateIOProcID: AudioDeviceIOProcID?
    nonisolated(unsafe) private var aggregateIOBlock: AudioDeviceIOBlock?
    nonisolated(unsafe) private var tapInputStreamCount: Int = 0
    nonisolated(unsafe) private var isCapturing = false

    /// Blocking: call off the main thread.
    nonisolated func start(outputDeviceID: AudioObjectID, renderTarget: RenderTarget) throws {
        guard #available(macOS 14.2, *) else { throw CaptureError.unsupportedOS }

        stop()

        let outputUID = try CoreAudioDeviceLookup.uid(for: outputDeviceID)
        let excluded = currentProcessObjectIDs()

        let tapUUID = UUID()
        let tapDescription = CATapDescription(
            excludingProcesses: excluded,
            deviceUID: outputUID,
            stream: 0
        )
        tapDescription.uuid = tapUUID
        tapDescription.name = "Speaker Master System Tap"
        tapDescription.isPrivate = true
        tapDescription.muteBehavior = .muted

        tapID = AudioObjectID(kAudioObjectUnknown)
        let createTapStatus = AudioHardwareCreateProcessTap(tapDescription, &tapID)
        if createTapStatus == SoftPermissionStatus.tccDenied || createTapStatus == SoftPermissionStatus.tccDeniedAlt {
            throw CaptureError.permissionDenied
        }
        try mapStatus(createTapStatus, operation: "AudioHardwareCreateProcessTap")

        let aggregateUID = "com.iamadi11.SpeakerMaster.agg.\(UUID().uuidString)"
        let aggregateDescription: [String: Any] = [
            kAudioAggregateDeviceNameKey: "Speaker Master Aggregate",
            kAudioAggregateDeviceUIDKey: aggregateUID,
            kAudioAggregateDeviceIsPrivateKey: true,
            kAudioAggregateDeviceIsStackedKey: false,
            kAudioAggregateDeviceTapAutoStartKey: true,
            kAudioAggregateDeviceMainSubDeviceKey: outputUID,
            kAudioAggregateDeviceSubDeviceListKey: [
                [kAudioSubDeviceUIDKey: outputUID],
            ],
            kAudioAggregateDeviceTapListKey: [
                [
                    kAudioSubTapDriftCompensationKey: true,
                    kAudioSubTapDriftCompensationQualityKey: kAudioAggregateDriftCompensationMaxQuality,
                    kAudioSubTapUIDKey: tapUUID.uuidString,
                ],
            ],
        ]

        aggregateDeviceID = AudioObjectID(kAudioObjectUnknown)
        try mapStatus(
            AudioHardwareCreateAggregateDevice(aggregateDescription as CFDictionary, &aggregateDeviceID),
            operation: "AudioHardwareCreateAggregateDevice"
        )

        waitUntilAlive(aggregateDeviceID)

        let deviceInputStreams = CoreAudioDeviceLookup.inputStreamCount(for: outputDeviceID)
        let aggregateInputStreams = CoreAudioDeviceLookup.inputStreamCount(for: aggregateDeviceID)
        tapInputStreamCount = max(0, aggregateInputStreams - deviceInputStreams)

        var procID: AudioDeviceIOProcID?
        let ioBlock: AudioDeviceIOBlock = { [weak self, weak renderTarget] _, inputData, _, outputData, _ in
            guard let self, self.isCapturing, let renderTarget else {
                smZeroFillAudioBuffers(outputData)
                return
            }
            renderTarget.handleUnifiedRender(
                inputData: inputData,
                outputData: outputData,
                tapStreamCount: self.tapInputStreamCount
            )
        }
        aggregateIOBlock = ioBlock

        try mapStatus(
            AudioDeviceCreateIOProcIDWithBlock(&procID, aggregateDeviceID, nil, ioBlock),
            operation: "AudioDeviceCreateIOProcIDWithBlock"
        )
        aggregateIOProcID = procID

        isCapturing = true
        let startStatus = AudioDeviceStart(aggregateDeviceID, procID)
        if startStatus == SoftPermissionStatus.tccDenied || startStatus == SoftPermissionStatus.tccDeniedAlt {
            stop()
            throw CaptureError.permissionDenied
        }
        do {
            try mapStatus(startStatus, operation: "AudioDeviceStart")
        } catch {
            stop()
            throw error
        }

        logger.info(
            "System tap active output=\(outputUID, privacy: .public) tapStreams=\(self.tapInputStreamCount)"
        )
    }

    nonisolated func stop() {
        isCapturing = false
        if let procID = aggregateIOProcID {
            AudioDeviceStop(aggregateDeviceID, procID)
            AudioDeviceDestroyIOProcID(aggregateDeviceID, procID)
            aggregateIOProcID = nil
        }
        aggregateIOBlock = nil
        if aggregateDeviceID != AudioObjectID(kAudioObjectUnknown) {
            AudioHardwareDestroyAggregateDevice(aggregateDeviceID)
            aggregateDeviceID = AudioObjectID(kAudioObjectUnknown)
        }
        if tapID != AudioObjectID(kAudioObjectUnknown) {
            if #available(macOS 14.2, *) {
                AudioHardwareDestroyProcessTap(tapID)
            }
            tapID = AudioObjectID(kAudioObjectUnknown)
        }
        tapInputStreamCount = 0
    }

    nonisolated private func currentProcessObjectIDs() -> [AudioObjectID] {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyTranslatePIDToProcessObject,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var pid = ProcessInfo.processInfo.processIdentifier
        var processObjectID = AudioObjectID(kAudioObjectUnknown)
        var dataSize = UInt32(MemoryLayout<AudioObjectID>.size)
        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            UInt32(MemoryLayout<pid_t>.size),
            &pid,
            &dataSize,
            &processObjectID
        )
        guard status == noErr, processObjectID != AudioObjectID(kAudioObjectUnknown) else {
            return []
        }
        return [processObjectID]
    }

    nonisolated private func waitUntilAlive(_ deviceID: AudioObjectID) {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceIsAlive,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        for _ in 0..<30 {
            var isAlive: UInt32 = 0
            var dataSize = UInt32(MemoryLayout<UInt32>.size)
            let status = AudioObjectGetPropertyData(deviceID, &address, 0, nil, &dataSize, &isAlive)
            if status == noErr, isAlive != 0 { return }
            Thread.sleep(forTimeInterval: 0.1)
        }
    }

    nonisolated private func mapStatus(_ status: OSStatus, operation: String) throws {
        guard status == noErr else {
            throw CaptureError.coreAudio(operation, status)
        }
    }
}

/// Soft mapping of common TCC denial OSStatus values observed with process taps.
private enum SoftPermissionStatus {
    /// `errAuthorizationDenied` / similar HAL denials.
    static let tccDenied: OSStatus = -60005
    static let tccDeniedAlt: OSStatus = -54
}
