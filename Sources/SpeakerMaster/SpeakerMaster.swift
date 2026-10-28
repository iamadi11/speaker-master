/// Speaker Master — domain library (DSP, safety, Narrow, Measure, profiles).
///
/// Product: MacBook system-wide EQ.
/// Auto = Measure | Narrow; Custom = pro console.
public enum SpeakerMaster {
    public static let productName = "Speaker Master"
    public static let minimumMacOSMajor = 14

    /// Auto path the user can choose for a connected speaker.
    public enum AutoMode: String, Sendable, Codable, CaseIterable {
        case measure
        case narrow
    }
}

/// Identity key for per-speaker persistence (Narrow / Measure profiles).
public struct SpeakerIdentity: Hashable, Sendable, Codable {
    public var outputUID: String
    public var displayName: String

    public init(outputUID: String, displayName: String) {
        self.outputUID = outputUID
        self.displayName = displayName
    }
}

/// Narrow profiles persist until Retry or a new speaker identity.
public struct NarrowPersistencePolicy: Sendable {
    public init() {}

    public func shouldReuseProfile(
        stored: SpeakerIdentity,
        current: SpeakerIdentity
    ) -> Bool {
        stored.outputUID == current.outputUID
    }
}
