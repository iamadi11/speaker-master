import Foundation

/// Seam for the system-wide EQ host (process tap + private aggregate).
/// App adapters implement this; unit tests can stub it.
@MainActor
public protocol AudioTapHosting: AnyObject {
    func activate(curve: EQCurve)
    func update(curve: EQCurve)
    func bypass(_ on: Bool)
    func deactivate()
}

/// High-level host readiness for UI copy (mapped by the app adapter).
public enum AudioTapHostPhase: String, Sendable, Equatable {
    case inactive
    case starting
    case activeSystemWide
    case activeInAppOnly
    case needsPermission
    case failed
}

/// User-facing guidance for Screen & System Audio Recording TCC.
public enum SystemAudioPermissionCopy {
    public static let usageIntent =
        "Speaker Master processes system audio so Auto and Custom EQ apply to Spotify, YouTube, and other apps — not only in-app audition."

    public static let grantSteps = """
    Grant access: System Settings → Privacy & Security → Screen & System Audio Recording → enable Speaker Master.
    Then tap Retry system EQ in the app.
    """

    public static let settingsURLString =
        "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"
}
