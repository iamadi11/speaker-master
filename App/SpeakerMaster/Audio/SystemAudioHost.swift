import Foundation
import SpeakerMaster

/// System-wide EQ host seam.
///
/// Target: Core Audio process tap + private aggregate on macOS 14.2+ / 26.x.
/// v1 ships a documented readiness state; in-app `InAppEQPlayer` remains the
/// guaranteed audible path until tap permissions + aggregate wiring are verified
/// on this Mac. No BlackHole / GPL virtual devices.
@MainActor
final class SystemAudioHost: ObservableObject {
    enum Status: Equatable {
        case inactive
        case readyPendingPermission
        case activeInAppOnly
        case activeSystemWide
        case failed(String)
    }

    @Published private(set) var status: Status = .inactive
    @Published private(set) var detail: String =
        "v1 uses in-app audition for EQ proof. System-wide process tap is next."

    private var currentCurve: EQCurve = .flat

    func activate(curve: EQCurve) {
        currentCurve = curve.sanitized()
        // Process-tap aggregate wiring is intentionally staged:
        // requiring Screen & System Audio Recording TCC + private aggregate.
        // Until that path is verified here, mark in-app-only so UX stays honest.
        status = .activeInAppOnly
        detail = "EQ active for in-app audition. System-wide tap: enable in a follow-up once Screen & System Audio Recording is granted."
    }

    func update(curve: EQCurve) {
        currentCurve = curve.sanitized()
        if status == .inactive {
            activate(curve: currentCurve)
        }
    }

    func bypass(_ on: Bool) {
        var curve = currentCurve
        curve.bypassed = on
        currentCurve = curve
    }

    func deactivate() {
        status = .inactive
        detail = "Processing off."
    }
}
