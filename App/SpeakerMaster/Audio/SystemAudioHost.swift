import AppKit
import Foundation
import SpeakerMaster

/// System-wide EQ host: Core Audio process tap + private aggregate (macOS 14.2+).
/// Falls back to honest in-app-only status if TCC denies or start fails.
@MainActor
final class SystemAudioHost: ObservableObject, AudioTapHosting {
    enum Status: Equatable {
        case inactive
        case starting
        case readyPendingPermission
        case activeInAppOnly
        case activeSystemWide
        case failed(String)
    }

    @Published private(set) var status: Status = .inactive
    @Published private(set) var detail: String =
        "System-wide EQ uses a Core Audio process tap. Grant Screen & System Audio Recording when prompted."
    @Published private(set) var phase: AudioTapHostPhase = .inactive

    private var currentCurve: EQCurve = .flat
    private var outputUID: String = ""
    private var engine: ProcessTapEngine?
    private var startGeneration = 0

    func setOutputUID(_ uid: String) {
        guard uid != outputUID else { return }
        outputUID = uid
        if status == .activeSystemWide || status == .starting || status == .readyPendingPermission {
            activate(curve: currentCurve)
        }
    }

    func activate(curve: EQCurve) {
        currentCurve = curve.sanitized()
        startGeneration += 1
        let generation = startGeneration
        let uid = outputUID.isEmpty ? OutputDeviceMonitor.currentDefaultOutput().outputUID : outputUID
        outputUID = uid

        status = .starting
        phase = .starting
        detail = "Starting system-wide EQ…"

        let previous = engine
        let next = ProcessTapEngine()
        engine = next
        let curveSnapshot = currentCurve

        Task.detached(priority: .userInitiated) {
            previous?.stop()
            do {
                try next.start(outputUID: uid, curve: curveSnapshot)
                await MainActor.run {
                    guard generation == self.startGeneration else {
                        next.stop()
                        return
                    }
                    self.status = .activeSystemWide
                    self.phase = .activeSystemWide
                    self.detail =
                        "System-wide EQ on — Spotify, YouTube, and other apps use this curve. Hold Bypass to A/B."
                }
            } catch let error as ProcessTapCapture.CaptureError {
                await MainActor.run {
                    guard generation == self.startGeneration else { return }
                    self.handleStartFailure(error)
                }
            } catch {
                await MainActor.run {
                    guard generation == self.startGeneration else { return }
                    self.status = .activeInAppOnly
                    self.phase = .activeInAppOnly
                    self.detail =
                        "System-wide start failed (\(error.localizedDescription)). In-app audition still works."
                }
            }
        }
    }

    func update(curve: EQCurve) {
        currentCurve = curve.sanitized()
        engine?.apply(curve: currentCurve)
        if status == .inactive {
            activate(curve: currentCurve)
        }
    }

    func bypass(_ on: Bool) {
        var curve = currentCurve
        curve.bypassed = on
        currentCurve = curve
        engine?.apply(curve: curve)
    }

    func deactivate() {
        startGeneration += 1
        let stopping = engine
        engine = nil
        Task.detached {
            stopping?.stop()
        }
        status = .inactive
        phase = .inactive
        detail = "Processing off."
    }

    func retrySystemWide() {
        activate(curve: currentCurve)
    }

    func openPrivacySettings() {
        if let url = URL(string: SystemAudioPermissionCopy.settingsURLString) {
            NSWorkspace.shared.open(url)
        }
    }

    private func handleStartFailure(_ error: ProcessTapCapture.CaptureError) {
        switch error {
        case .permissionDenied:
            status = .readyPendingPermission
            phase = .needsPermission
            detail = SystemAudioPermissionCopy.grantSteps
        case .unsupportedOS:
            status = .activeInAppOnly
            phase = .activeInAppOnly
            detail = error.localizedDescription + " In-app audition still works."
        case .coreAudio(let op, let statusCode):
            if statusCode == -60005 || statusCode == -54 {
                status = .readyPendingPermission
                phase = .needsPermission
                detail = SystemAudioPermissionCopy.grantSteps
            } else {
                status = .failed("\(op) (\(statusCode))")
                phase = .failed
                detail =
                    "System-wide EQ failed: \(op) (\(statusCode)). In-app audition still works. See docs/system-wide-audio.md."
            }
        }
    }
}
