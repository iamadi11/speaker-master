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
    /// When true, `update` must not auto-reactivate (Measure suspend window).
    private var suspendedForMeasure = false
    private var pendingRestartTask: Task<Void, Never>?
    private var autoRetryUsed = false

    func setOutputUID(_ uid: String) {
        guard uid != outputUID else { return }
        outputUID = uid
        let shouldRestart: Bool = {
            switch status {
            case .activeSystemWide, .starting, .readyPendingPermission, .failed, .activeInAppOnly:
                return true
            case .inactive:
                return false
            }
        }()
        if shouldRestart, !suspendedForMeasure {
            scheduleRestart(reason: "output changed")
        }
    }

    /// Pause the process-tap host for Measure capture so mic + audition aren't starved.
    func suspendForMeasure() {
        suspendedForMeasure = true
        pendingRestartTask?.cancel()
        pendingRestartTask = nil
        deactivateKeepingSuspendFlag()
    }

    /// Resume after Measure apply / refuse / failure.
    func resumeAfterMeasure(curve: EQCurve) {
        suspendedForMeasure = false
        autoRetryUsed = false
        activate(curve: curve)
    }

    func activate(curve: EQCurve) {
        guard !suspendedForMeasure else {
            currentCurve = curve.sanitized()
            return
        }
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
                    self.autoRetryUsed = false
                    self.status = .activeSystemWide
                    self.phase = .activeSystemWide
                    self.detail =
                        "System-wide EQ on — Spotify, YouTube, and other apps use this curve. Hold Bypass to A/B."
                }
            } catch let error as ProcessTapCapture.CaptureError {
                await MainActor.run {
                    guard generation == self.startGeneration else { return }
                    self.handleStartFailure(error, generation: generation)
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
        if status == .inactive, !suspendedForMeasure {
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
        suspendedForMeasure = false
        deactivateKeepingSuspendFlag()
    }

    func retrySystemWide() {
        autoRetryUsed = false
        activate(curve: currentCurve)
    }

    func openPrivacySettings() {
        if let url = URL(string: SystemAudioPermissionCopy.settingsURLString) {
            NSWorkspace.shared.open(url)
        }
    }

    // MARK: - Private

    private func deactivateKeepingSuspendFlag() {
        startGeneration += 1
        pendingRestartTask?.cancel()
        pendingRestartTask = nil
        let stopping = engine
        engine = nil
        Task.detached {
            stopping?.stop()
        }
        status = .inactive
        phase = .inactive
        detail = suspendedForMeasure ? "System-wide paused for Measure…" : "Processing off."
    }

    /// Coalesce rapid output-UID flips (Bluetooth reconnect storms).
    private func scheduleRestart(reason _: String) {
        pendingRestartTask?.cancel()
        pendingRestartTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 280_000_000)
            guard !Task.isCancelled, !self.suspendedForMeasure else { return }
            self.activate(curve: self.currentCurve)
        }
    }

    private func handleStartFailure(_ error: ProcessTapCapture.CaptureError, generation: Int) {
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
            } else if !autoRetryUsed {
                // One quiet retry for transient Core Audio races after Measure / device flip.
                autoRetryUsed = true
                status = .starting
                phase = .starting
                detail = "Retrying system-wide EQ…"
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 350_000_000)
                    guard generation == self.startGeneration, !self.suspendedForMeasure else { return }
                    self.activate(curve: self.currentCurve)
                }
            } else {
                status = .failed("\(op) (\(statusCode))")
                phase = .failed
                detail =
                    "System-wide EQ failed: \(op) (\(statusCode)). In-app audition still works. See docs/system-wide-audio.md."
            }
        }
    }
}
