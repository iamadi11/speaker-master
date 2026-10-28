/// One parametric EQ section.
public struct EQBand: Hashable, Sendable, Codable, Identifiable {
    public enum FilterType: String, Sendable, Codable, CaseIterable {
        case peaking
        case lowShelf
        case highShelf
        case lowPass
        case highPass
    }

    public var id: String
    public var frequencyHz: Double
    public var gainDb: Double
    public var q: Double
    public var type: FilterType

    public init(
        id: String,
        frequencyHz: Double,
        gainDb: Double,
        q: Double,
        type: FilterType
    ) {
        self.id = id
        self.frequencyHz = frequencyHz
        self.gainDb = gainDb
        self.q = q
        self.type = type
    }

    public func sanitized() -> EQBand {
        var copy = self
        copy.frequencyHz = max(20, min(20_000, frequencyHz))
        copy.q = max(0.1, min(10, q))
        copy.gainDb = SafetyLimits.clampBandGain(gainDb, frequencyHz: copy.frequencyHz)
        return copy
    }
}
