/// Custom L0 named intents from `docs/paper-ux-flows.md` — cut-first, under `SafetyLimits`.
public struct CustomIntent: Hashable, Sendable, Codable, Identifiable {
    public var id: String
    public var title: String
    public var summary: String
    public var curve: EQCurve

    public init(id: String, title: String, summary: String, curve: EQCurve) {
        self.id = id
        self.title = title
        self.summary = summary
        self.curve = curve.sanitized()
    }
}

public enum CustomIntentCatalog: Sendable {
    public static let all: [CustomIntent] = [
        CustomIntent(
            id: "balanced",
            title: "Balanced",
            summary: "Near-flat starting point within safety caps.",
            curve: curve(gains: [0, 0, 0, 0, 0], broadband: 0)
        ),
        CustomIntent(
            id: "warmer",
            title: "Warmer",
            summary: "Gentle low-end body; soft harshness cut. Not a bass booster.",
            curve: curve(gains: [2.0, 1.0, 0, -0.5, -1.5], broadband: 0)
        ),
        CustomIntent(
            id: "clearer",
            title: "Clearer",
            summary: "Cut mud, lift presence. Stays under per-band caps.",
            curve: curve(gains: [-1.5, -1.0, 0.5, 2.0, 0.5], broadband: 0)
        ),
        CustomIntent(
            id: "bass-tamed",
            title: "Bass tamed",
            summary: "Prefer cuts on boom — safer for small drivers.",
            curve: curve(gains: [-3.0, -1.5, 0, 0.5, 0], broadband: 0)
        ),
    ]

    public static func intent(id: String) -> CustomIntent? {
        all.first { $0.id == id }
    }

    /// Returns a catalog id only when the sanitized curve exactly matches an intent.
    public static func matchingIntentID(for curve: EQCurve) -> String? {
        let sanitized = curve.sanitized()
        return all.first { $0.curve == sanitized }?.id
    }

    private static func curve(gains: [Double], broadband: Double) -> EQCurve {
        precondition(gains.count == EQCurve.defaultBandScaffold.count)
        let bands = zip(EQCurve.defaultBandScaffold, gains).map { scaffold, gain in
            EQBand(
                id: scaffold.id,
                frequencyHz: scaffold.hz,
                gainDb: gain,
                q: scaffold.q,
                type: .peaking
            )
        }
        return EQCurve(bands: bands, broadbandGainDb: broadband, bypassed: false).sanitized()
    }
}
