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

/// Structured empty-state copy for System EQ phases (ui-ux-pro-max: helpful message + action).
public struct SystemEQEmptyStateCopy: Sendable, Equatable {
    public var title: String
    public var body: String
    public var primaryActionTitle: String?
    public var secondaryActionTitle: String?

    public init(
        title: String,
        body: String,
        primaryActionTitle: String? = nil,
        secondaryActionTitle: String? = nil
    ) {
        self.title = title
        self.body = body
        self.primaryActionTitle = primaryActionTitle
        self.secondaryActionTitle = secondaryActionTitle
    }

    /// Returns guidance when the phase is an empty / recovery state; nil when EQ is healthy or starting.
    public static func forPhase(_ phase: AudioTapHostPhase) -> SystemEQEmptyStateCopy? {
        switch phase {
        case .inactive:
            return SystemEQEmptyStateCopy(
                title: "System EQ off",
                body: "Apply Auto (Measure or Narrow) or edit Custom to start system-wide EQ for this output."
            )
        case .needsPermission:
            return SystemEQEmptyStateCopy(
                title: "Permission needed",
                body: SystemAudioPermissionCopy.grantSteps,
                primaryActionTitle: "Open Privacy Settings",
                secondaryActionTitle: "Retry system EQ"
            )
        case .activeInAppOnly:
            return SystemEQEmptyStateCopy(
                title: "In-app audition only",
                body: "System-wide tap is not active yet. Spotify and YouTube stay dry until permission and Retry succeed. Audition noise still proves the curve.",
                primaryActionTitle: "Retry system EQ"
            )
        case .failed:
            return SystemEQEmptyStateCopy(
                title: "System EQ failed",
                body: "The process tap could not start. In-app audition still works. Retry after checking System Settings → Privacy & Security → Screen & System Audio Recording.",
                primaryActionTitle: "Retry system EQ",
                secondaryActionTitle: "Open Privacy Settings"
            )
        case .starting, .activeSystemWide:
            return nil
        }
    }
}
