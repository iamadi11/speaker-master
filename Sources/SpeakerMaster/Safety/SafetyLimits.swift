/// Frozen numeric ceilings from `docs/safety-limits.md` (phase-1 sheet).
public enum SafetyLimits: Sendable {
    public static let maxBroadbandBoostDb: Double = 3
    public static let maxPerBandBoostDb: Double = 6
    public static let maxBassBoostDb: Double = 4
    public static let bassRegionCeilingHz: Double = 120
    public static let maxTotalConstructiveGainDb: Double = 6
    public static let truePeakCeilingDbTP: Double = -1.0
    public static let maxMakeupAfterLimiterDb: Double = 1
    /// Soft revision string stored with profiles; bump only via ADR.
    public static let revision = "safety-v1-2026-10-28"

    public static func maxBandBoostDb(frequencyHz: Double) -> Double {
        frequencyHz <= bassRegionCeilingHz ? maxBassBoostDb : maxPerBandBoostDb
    }

    public static func clampBandGain(_ gainDb: Double, frequencyHz: Double) -> Double {
        let maxBoost = maxBandBoostDb(frequencyHz: frequencyHz)
        if gainDb > maxBoost { return maxBoost }
        return gainDb
    }

    public static func clampBroadbandGain(_ gainDb: Double) -> Double {
        min(gainDb, maxBroadbandBoostDb)
    }

    public static func constructiveGainWithinCap(
        atFrequencyHz _: Double,
        overlappingBoostsDb: [Double]
    ) -> Bool {
        let sum = overlappingBoostsDb.filter { $0 > 0 }.reduce(0, +)
        return sum <= maxTotalConstructiveGainDb
    }
}
