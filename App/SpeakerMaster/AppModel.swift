import Combine
import Foundation
import SpeakerMaster
import SwiftUI

@MainActor
final class AppModel: ObservableObject {
    enum Tab: String, CaseIterable, Identifiable {
        case auto, custom
        var id: String { rawValue }
        var title: String {
            switch self {
            case .auto: "Auto"
            case .custom: "Custom"
            }
        }
    }

    enum AutoScreen: Equatable {
        case pathPicker
        case measure
        case narrow
        case home
    }

    /// Measure guided-flow phase for step indicators (ui-ux progress feedback).
    enum MeasurePhase: String, Equatable {
        case idle
        case recording
        case analyzing
        case applied
        case refused
    }

    @Published var tab: Tab = .auto
    @Published var autoScreen: AutoScreen = .pathPicker
    @Published var activeCurve: EQCurve = .flat
    @Published var bypassed = false
    @Published var statusMessage = "Safety limits on · Hold Bypass to A/B"
    @Published var lastSource: SpeakerProfile.Source?
    @Published var lastNarrowPresetID: String?
    @Published var measureNote: String?
    @Published var measurePhase: MeasurePhase = .idle
    @Published var lastMeasureQuality: MeasureAnalysisResult.Quality?
    @Published var headphoneWarning = false
    @Published var customCanUndo = false
    /// Curve Custom “Reset to Auto” restores (last Auto apply, else flat).
    @Published private(set) var customAutoBase: EQCurve = .flat

    let output = OutputDeviceMonitor()
    let player = InAppEQPlayer()
    let mic = MicRecorder()
    let systemHost = SystemAudioHost()
    let profiles: SpeakerProfileStore

    private let persistence = NarrowPersistencePolicy()
    private var customStack = CustomEditStack(base: .flat)
    private var cancellables = Set<AnyCancellable>()
    /// In-flight Measure task — cancelled by `cancelMeasure()` (paper §2.3 Sweep cancelled).
    private var measureTask: Task<Void, Never>?
    private var lastAnnouncedHostPhase: AudioTapHostPhase?
    /// Tracks last known output UID so new-speaker copy stays honest after device flips.
    private var trackedOutputUID: String = ""

    init(profiles: SpeakerProfileStore = UserDefaultsProfileStore()) {
        self.profiles = profiles
        // Nested ObservableObjects do not invalidate EnvironmentObject views on their own.
        mic.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
        output.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
        player.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
        systemHost.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
                self?.syncSystemEQStatusHonesty()
            }
            .store(in: &cancellables)
        restoreIfPossible()
        trackedOutputUID = output.identity.outputUID
    }

    /// True while a Measure capture/analyze is in flight (UI disables competing CTAs).
    var isMeasureRunning: Bool {
        measurePhase == .recording || measurePhase == .analyzing
    }

    var outputIdentity: SpeakerIdentity { output.identity }

    var customBasedOnLabel: String {
        switch lastSource {
        case .measure:
            return "Based on: Measure · \(outputIdentity.displayName)"
        case .narrow:
            let name = lastNarrowPresetID.flatMap { NarrowCatalog.preset(id: $0)?.title } ?? "Narrow"
            return "Based on: Narrow · \(name)"
        case .custom:
            return "Based on: Custom edits · \(outputIdentity.displayName)"
        case .none:
            return "Based on: Safe default · \(outputIdentity.displayName)"
        }
    }

    var matchedCustomIntentID: String? {
        CustomIntentCatalog.matchingIntentID(for: activeCurve)
    }

    func restoreIfPossible() {
        output.refresh()
        systemHost.setOutputUID(output.identity.outputUID)
        headphoneWarning = NarrowCatalog.looksLikeHeadphones(deviceName: output.identity.displayName)
        if let profile = profiles.profile(forOutputUID: output.identity.outputUID),
           persistence.shouldReuseProfile(stored: profile.identity, current: output.identity)
        {
            apply(profile: profile, persist: false)
            autoScreen = .home
            statusMessage = "On for this speaker · Stays until Retry or a different speaker"
        } else {
            autoScreen = .pathPicker
            activeCurve = .flat
            lastSource = nil
            lastNarrowPresetID = nil
            measureNote = nil
            measurePhase = .idle
            lastMeasureQuality = nil
            resetCustomStack(base: .flat)
            // Honest empty / new-speaker strip — never leave stale “On for…” copy.
            statusMessage = "No EQ yet — pick Measure or Narrow"
        }
    }

    func onOutputChanged() {
        let previousUID = trackedOutputUID
        restoreIfPossible()
        let currentUID = output.identity.outputUID
        trackedOutputUID = currentUID
        pushCurveToHosts()
        if autoScreen == .pathPicker, !previousUID.isEmpty, previousUID != currentUID {
            statusMessage = "New speaker — pick Measure or Narrow"
        }
    }

    func applyNarrow(preset: NarrowPreset) {
        let profile = SpeakerProfile(
            identity: output.identity,
            source: .narrow,
            narrowPresetID: preset.id,
            curve: preset.curve
        )
        apply(profile: profile, persist: true)
        autoScreen = .home
        statusMessage = "Narrow · \(preset.title) · Stays until Retry or a different speaker"
        measureNote = "\(preset.summary) · Not calibrated — Measure later for a better match."
    }

    func runMeasure() async {
        measureTask?.cancel()
        let task = Task { @MainActor in
            await self.performMeasure()
        }
        measureTask = task
        await task.value
        if measureTask == task {
            measureTask = nil
        }
    }

    /// Abort in-flight Measure; prior good profile kept (paper §2.3).
    func cancelMeasure() {
        measureTask?.cancel()
    }

    private func performMeasure() async {
        statusMessage = "Measuring…"
        measureNote = nil
        lastMeasureQuality = nil
        measurePhase = .idle
        let ok = await mic.requestPermission()
        guard !Task.isCancelled else {
            handleMeasureCancelled(hostWasActive: false, previousBypass: bypassed)
            return
        }
        guard ok else {
            statusMessage = "Mic permission needed — or use Narrow"
            measureNote = "Allow Microphone in System Settings, or pick Narrow."
            measurePhase = .refused
            return
        }
        mic.refreshDevices()
        guard mic.selectedDeviceID != nil else {
            statusMessage = "No mic selected"
            measureNote = "Pick an input above, or use Narrow."
            measurePhase = .refused
            return
        }

        // Bypass system EQ during capture so the room hears a flat stimulus,
        // not a previous Narrow/Measure/Custom curve (mic = room measure; tap = host).
        // Suspend the process-tap host entirely — two heavy Core Audio clients plus
        // an input engine often starve Built-in mic buffers on personal Macs.
        let previousBypass = bypassed
        let hostWasActive = systemHost.status == .activeSystemWide || systemHost.status == .activeInAppOnly
            || systemHost.status == .starting
        setBypass(true)
        if hostWasActive {
            systemHost.suspendForMeasure()
        }
        measurePhase = .recording

        do {
            // Longer sweep + MicRecorder pre/post settle → better Built-in SNR in quiet rooms.
            let capture = try await mic.recordWhilePlaying(
                duration: 2.8,
                player: player,
                stimulusCurve: .flat
            )
            try Task.checkCancellation()
            setBypass(previousBypass)
            measurePhase = .analyzing
            statusMessage = "Analyzing…"

            let result = MeasureAnalyzer.analyze(
                samples: capture.samples,
                sampleRate: capture.sampleRate
            )
            try Task.checkCancellation()
            lastMeasureQuality = result.quality
            switch MeasurePipeline.decision(from: result) {
            case .apply(let correction, let notes):
                let profile = SpeakerProfile(
                    identity: output.identity,
                    source: .measure,
                    curve: correction
                )
                apply(profile: profile, persist: true)
                autoScreen = .home
                measurePhase = .applied
                statusMessage = result.quality == .good
                    ? "Measure · Better sound is on · Stays until Retry or a different speaker"
                    : "Measure · Applied (cautious) · Stays until Retry or a different speaker"
                let bands = MeasureAnalyzer.bandCorrectionSummary(from: result)
                measureNote = bands.isEmpty ? notes : "\(notes)\nBands: \(bands)"
            case .refuse(let notes):
                // Do not overwrite a prior good profile with a hot guess.
                statusMessage = "Bad take — nothing new applied"
                measureNote = notes
                measurePhase = .refused
                autoScreen = .measure
                setBypass(previousBypass)
                if hostWasActive {
                    systemHost.resumeAfterMeasure(curve: activeCurve)
                }
            }
        } catch MicRecorderError.cancelled {
            handleMeasureCancelled(hostWasActive: hostWasActive, previousBypass: previousBypass)
        } catch is CancellationError {
            handleMeasureCancelled(hostWasActive: hostWasActive, previousBypass: previousBypass)
        } catch {
            setBypass(previousBypass)
            if hostWasActive {
                systemHost.resumeAfterMeasure(curve: activeCurve)
            }
            statusMessage = "Measure failed"
            measureNote = error.localizedDescription
            measurePhase = .refused
            lastMeasureQuality = .badTake
            autoScreen = .measure
        }
    }

    private func handleMeasureCancelled(hostWasActive: Bool, previousBypass: Bool) {
        player.stop()
        setBypass(previousBypass)
        if hostWasActive {
            systemHost.resumeAfterMeasure(curve: activeCurve)
        }
        statusMessage = "Measure cancelled — prior profile kept"
        measureNote = "Sweep stopped. Nothing new applied. Try again when ready, or use Narrow."
        measurePhase = .idle
        lastMeasureQuality = nil
        // Do not force autoScreen — Cancel stays on Measure; Back may already have left for path picker.
    }

    /// Clear a refused/cancelled take so Play & measure is the next action again.
    func clearMeasureRefusal() {
        measurePhase = .idle
        measureNote = nil
        lastMeasureQuality = nil
        statusMessage = "Ready to measure — place mic, then Play"
    }

    /// Elevate status strip when System EQ needs attention (journey honesty).
    private func syncSystemEQStatusHonesty() {
        let phase = systemHost.phase
        guard phase != lastAnnouncedHostPhase else { return }
        lastAnnouncedHostPhase = phase
        switch phase {
        case .needsPermission:
            if !statusMessage.contains("Privacy") && !isMeasureRunning {
                statusMessage = "System EQ needs Screen & System Audio permission"
            }
        case .failed:
            if !isMeasureRunning {
                statusMessage = "System EQ failed — Retry or open Privacy settings"
            }
        case .activeInAppOnly:
            if !isMeasureRunning, lastSource != nil {
                statusMessage = "In-app audition only — system-wide not active yet"
            }
        default:
            break
        }
    }

    func retry() {
        profiles.remove(outputUID: output.identity.outputUID)
        activeCurve = .flat
        lastSource = nil
        lastNarrowPresetID = nil
        bypassed = false
        autoScreen = .pathPicker
        statusMessage = "Retry — pick Measure or Narrow"
        measureNote = nil
        measurePhase = .idle
        lastMeasureQuality = nil
        resetCustomStack(base: .flat)
        pushCurveToHosts()
        player.stop()
        systemHost.deactivate()
    }

    func applyCustomIntent(_ intent: CustomIntent) {
        commitCustom(intent.curve, status: "Custom · \(intent.title)")
    }

    func updateCustom(_ curve: EQCurve) {
        commitCustom(curve, status: "Custom · Editing")
    }

    func undoCustom() {
        guard let previous = customStack.undo() else { return }
        activeCurve = previous
        customCanUndo = customStack.canUndo
        persistCustomCurve(previous)
        pushCurveToHosts()
        statusMessage = "Custom · Undo"
    }

    func resetCustom() {
        commitCustom(.flat, status: "Custom · Reset to flat")
    }

    func resetCustomToAuto() {
        let target = customAutoBase.sanitized()
        customStack = CustomEditStack(base: target)
        activeCurve = target
        customCanUndo = false
        persistCustomCurve(target)
        pushCurveToHosts()
        statusMessage = "Custom · Reset to Auto"
    }

    func setBypass(_ on: Bool) {
        bypassed = on
        pushCurveToHosts()
    }

    func toggleAudition() {
        if player.isPlaying {
            player.stop()
        } else {
            do {
                var curve = activeCurve
                curve.bypassed = bypassed
                try player.start(mode: .noise, curve: curve)
                statusMessage = "Audition playing — toggle Bypass to A/B"
            } catch {
                statusMessage = "Could not start audition: \(error.localizedDescription)"
            }
        }
    }

    private func apply(profile: SpeakerProfile, persist: Bool) {
        let safe = profile.reclamped()
        activeCurve = safe.curve
        lastSource = safe.source
        lastNarrowPresetID = safe.narrowPresetID
        bypassed = false
        if safe.source == .measure || safe.source == .narrow {
            resetCustomStack(base: safe.curve)
        } else if safe.source == .custom {
            customStack = CustomEditStack(base: customAutoBase)
            customStack.commit(safe.curve)
            customCanUndo = customStack.canUndo
            activeCurve = customStack.current
        }
        if persist {
            profiles.save(safe)
        }
        pushCurveToHosts()
        // Measure / Narrow apply always wants a clean host start (clears suspend).
        systemHost.resumeAfterMeasure(curve: safe.curve)
    }

    private func commitCustom(_ curve: EQCurve, status: String) {
        customStack.commit(curve)
        activeCurve = customStack.current
        customCanUndo = customStack.canUndo
        lastSource = .custom
        persistCustomCurve(activeCurve)
        pushCurveToHosts()
        statusMessage = status
    }

    private func persistCustomCurve(_ curve: EQCurve) {
        let profile = SpeakerProfile(
            identity: output.identity,
            source: .custom,
            curve: curve
        )
        profiles.save(profile)
    }

    private func resetCustomStack(base: EQCurve) {
        let safe = base.sanitized()
        customAutoBase = safe
        customStack = CustomEditStack(base: safe)
        customCanUndo = false
    }

    private func pushCurveToHosts() {
        var curve = activeCurve
        curve.bypassed = bypassed
        player.apply(curve: curve)
        systemHost.update(curve: curve)
        systemHost.bypass(bypassed)
    }
}
