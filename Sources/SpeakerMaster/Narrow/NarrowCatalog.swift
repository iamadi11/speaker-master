/// Day-one Narrow presets — cut-first, under `SafetyLimits`. Honesty: not Measure.

/// Taxonomy groups for Narrow tiles (`docs/narrow-presets-sketch.md`).
public enum NarrowCategory: String, Sendable, Codable, CaseIterable, Identifiable {
    case portable
    case smartSpeaker
    case desk
    case fallback

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .portable: "Portable"
        case .smartSpeaker: "Smart speaker"
        case .desk: "Desk"
        case .fallback: "Safe fallback"
        }
    }

    public var sortOrder: Int {
        switch self {
        case .portable: 0
        case .smartSpeaker: 1
        case .desk: 2
        case .fallback: 3
        }
    }
}

public struct NarrowPreset: Hashable, Sendable, Codable, Identifiable {
    public var id: String
    public var title: String
    public var summary: String
    public var category: NarrowCategory
    public var curve: EQCurve

    public init(
        id: String,
        title: String,
        summary: String,
        category: NarrowCategory,
        curve: EQCurve
    ) {
        self.id = id
        self.title = title
        self.summary = summary
        self.category = category
        self.curve = curve.sanitized()
    }
}

public enum NarrowCatalog: Sendable {
    public static let all: [NarrowPreset] = [
        NarrowPreset(
            id: "bt-portable",
            title: "Bluetooth box",
            summary: "Tame one-note boom; slight clarity. Quick improve — not a mic calibration.",
            category: .portable,
            curve: curve(
                gains: [-2.5, -1.5, 0.5, 1.5, -1.0],
                broadband: 0
            )
        ),
        NarrowPreset(
            id: "echo-class",
            title: "Echo / Alexa",
            summary: "Soften harsh top; control mid-bass thump.",
            category: .smartSpeaker,
            curve: curve(
                gains: [-1.5, -2.0, 0, -1.0, -2.5],
                broadband: 0
            )
        ),
        NarrowPreset(
            id: "sony-ult-portable",
            title: "Sony portable / ULT",
            summary: "Respect small drivers — cut mud, light presence. Not a ULT-button clone.",
            category: .portable,
            curve: curve(
                gains: [-3.0, -2.0, 0.5, 2.0, -0.5],
                broadband: 0
            )
        ),
        NarrowPreset(
            id: "desktop-nearfield",
            title: "Desk speaker",
            summary: "Mild desk-boundary bass cut; even mids.",
            category: .desk,
            curve: curve(
                gains: [-2.0, -0.5, 0.5, 0.5, -0.5],
                broadband: 0
            )
        ),
        NarrowPreset(
            id: "party-portable",
            title: "Party portable",
            summary: "JBL / UE-class boom boxes — cut one-note thump; light clarity. Not a party booster.",
            category: .portable,
            curve: curve(
                gains: [-3.0, -2.0, 0, 1.5, -1.0],
                broadband: 0
            )
        ),
        NarrowPreset(
            id: "homepod-class",
            title: "HomePod / Nest",
            summary: "Soften room boom and harsh presence for smart speakers. Quick improve — not Measure.",
            category: .smartSpeaker,
            curve: curve(
                gains: [-2.0, -1.5, 0.5, -1.5, -2.0],
                broadband: 0
            )
        ),
        NarrowPreset(
            id: "generic-safe",
            title: "Just make it safer",
            summary: "Almost flat with a gentle harshness cut. Never embarrassing.",
            category: .fallback,
            curve: curve(
                gains: [-0.5, 0, 0, -0.5, -1.5],
                broadband: 0
            )
        ),
    ]

    public static var categoriesInOrder: [NarrowCategory] {
        NarrowCategory.allCases.sorted { $0.sortOrder < $1.sortOrder }
    }

    public static func presets(in category: NarrowCategory) -> [NarrowPreset] {
        all.filter { $0.category == category }
    }

    public static func preset(id: String) -> NarrowPreset? {
        all.first { $0.id == id }
    }

    public static func suggestedPresetID(deviceName: String) -> String {
        let name = deviceName.lowercased()
        if looksLikeHeadphones(deviceName: deviceName) {
            return "generic-safe"
        }
        if name.contains("ult field") || name.contains("ultfield") || name.contains("srs-ult")
            || name.contains("ult ")
        {
            return "sony-ult-portable"
        }
        if name.contains("homepod") || name.contains("nest mini") || name.contains("nest audio")
            || name.contains("google home") || name.contains("google nest")
        {
            return "homepod-class"
        }
        if name.contains("echo") || name.contains("alexa") || name.contains("amazon") {
            return "echo-class"
        }
        if looksLikePartyPortable(deviceName: deviceName) {
            return "party-portable"
        }
        if looksLikeDeskSpeaker(deviceName: deviceName) {
            return "desktop-nearfield"
        }
        if name.contains("bluetooth") || name.contains(" bt") || name.hasPrefix("bt ") {
            return "bt-portable"
        }
        return "bt-portable"
    }

    public static func looksLikePartyPortable(deviceName: String) -> Bool {
        let name = deviceName.lowercased()
        let markers = [
            "jbl ", "jbl-", "flip ", "charge ", "xtreme", "boombox",
            "ue boom", "wonderboom", "megaboom", "anker sound", "soundcore",
        ]
        return markers.contains { name.contains($0) }
    }

    public static func looksLikeHeadphones(deviceName: String) -> Bool {
        let name = deviceName.lowercased()
        let markers = ["airpods", "headphone", "headset", "beats ", "wh-1000", "iem", "earphone"]
        return markers.contains { name.contains($0) }
    }

    public static func looksLikeDeskSpeaker(deviceName: String) -> Bool {
        let name = deviceName.lowercased()
        let markers = [
            "macbook", "built-in", "builtin", "imac", "display audio",
            "computer speaker", "desktop", "nearfield", "studio monitor",
        ]
        return markers.contains { name.contains($0) }
    }

    private static func curve(gains: [Double], broadband: Double) -> EQCurve {
        precondition(gains.count == EQCurve.defaultBandScaffold.count)
        let bands = zip(EQCurve.defaultBandScaffold, gains).map { scaffold, gain in
            EQBand(id: scaffold.id, frequencyHz: scaffold.hz, gainDb: gain, q: scaffold.q, type: .peaking)
        }
        return EQCurve(bands: bands, broadbandGainDb: broadband, bypassed: false).sanitized()
    }
}
