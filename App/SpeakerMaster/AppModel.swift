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

    @Published var tab: Tab = .auto
    @Published var autoScreen: AutoScreen = .pathPicker
    @Published var activeCurve: EQCurve = .flat
    @Published var bypassed = false
    @Published var statusMessage = "Safety limits on · Hold Bypass to A/B"
    @Published var lastSource: SpeakerProfile.Source?
    @Published var lastNarrowPresetID: String?
    @Published var measureNote: String?
    @Published var headphoneWarning = false

    let output = OutputDeviceMonitor()
    let player = InAppEQPlayer()
    let mic = MicRecorder()
    let systemHost = SystemAudioHost()
    let profiles: SpeakerProfileStore

    private let persistence = NarrowPersistencePolicy()

    init(profiles: SpeakerProfileStore = UserDefaultsProfileStore()) {
        self.profiles = profiles
        restoreIfPossible()
    }

    var outputIdentity: SpeakerIdentity { output.identity }

    func restoreIfPossible() {
        output.refresh()
        headphoneWarning = NarrowCatalog.looksLikeHeadphones(deviceName: output.identity.displayName)
        if let profile = profiles.profile(forOutputUID: output.identity.outputUID),
           persistence.shouldReuseProfile(stored: profile.identity, current: output.identity)
        {
            apply(profile: profile, persist: false)
            autoScreen = .home
            statusMessage = "On for this speaker · Saved until Retry"
        } else {
            autoScreen = .pathPicker
            activeCurve = .flat
            lastSource = nil
        }
    }

    func onOutputChanged() {
        restoreIfPossible()
        pushCurveToHosts()
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
        statusMessage = "Narrow · \(preset.title) · Saved for this speaker"
        measureNote = preset.summary
    }

    func runMeasure() async {
        statusMessage = "Measuring…"
        measureNote = nil
        let ok = await mic.requestPermission()
        guard ok else {
            statusMessage = "Mic permission needed — or use Narrow"
            measureNote = "Allow Microphone in System Settings, or pick Narrow."
            return
        }
        do {
            // Flat stimulus so analysis hears the speaker/room, not our EQ.
            let capture = try await mic.recordWhilePlaying(
                duration: 2.2,
                player: player,
                stimulusCurve: .flat
            )
            let result = MeasureAnalyzer.analyze(samples: capture.samples, sampleRate: capture.sampleRate)
            switch result.quality {
            case .badTake:
                activeCurve = MeasureAnalyzer.safeFallbackCurve()
                lastSource = nil
                statusMessage = "Bad take — stayed flat + limiter"
                measureNote = result.notes
                autoScreen = .pathPicker
            case .good, .inconclusive:
                guard let correction = result.correction else {
                    activeCurve = MeasureAnalyzer.safeFallbackCurve()
                    statusMessage = "Analyze failed — flat + limiter"
                    autoScreen = .pathPicker
                    return
                }
                let profile = SpeakerProfile(
                    identity: output.identity,
                    source: .measure,
                    curve: correction
                )
                apply(profile: profile, persist: true)
                autoScreen = .home
                statusMessage = "Measure · Better sound is on"
                measureNote = result.notes
            }
        } catch {
            statusMessage = "Measure failed"
            measureNote = error.localizedDescription
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
        pushCurveToHosts()
        player.stop()
        systemHost.deactivate()
    }

    func updateCustom(_ curve: EQCurve) {
        activeCurve = curve.sanitized()
        lastSource = .custom
        let profile = SpeakerProfile(
            identity: output.identity,
            source: .custom,
            curve: activeCurve
        )
        profiles.save(profile)
        pushCurveToHosts()
        statusMessage = "Custom · Editing"
    }

    func resetCustom() {
        updateCustom(.flat)
        statusMessage = "Custom · Reset to flat"
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
        if persist {
            profiles.save(safe)
        }
        pushCurveToHosts()
        systemHost.activate(curve: safe.curve)
    }

    private func pushCurveToHosts() {
        var curve = activeCurve
        curve.bypassed = bypassed
        player.apply(curve: curve)
        systemHost.update(curve: curve)
        systemHost.bypass(bypassed)
    }
}
