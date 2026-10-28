/// Day-one Narrow presets — cut-first, under `SafetyLimits`. Honesty: not Measure.
public struct NarrowPreset: Hashable, Sendable, Codable, Identifiable {
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

public enum NarrowCatalog: Sendable {
    public static let all: [NarrowPreset] = [
        NarrowPreset(
            id: "bt-portable",
            title: "Bluetooth box",
            summary: "Tame one-note boom; slight clarity. Quick improve — not a mic calibration.",
            curve: curve(
                gains: [-2.5, -1.5, 0.5, 1.5, -1.0],
                broadband: 0
            )
        ),
        NarrowPreset(
            id: "echo-class",
            title: "Echo / Alexa",
            summary: "Soften harsh top; control mid-bass thump.",
            curve: curve(
                gains: [-1.5, -2.0, 0, -1.0, -2.5],
                broadband: 0
            )
        ),
        NarrowPreset(
            id: "sony-ult-portable",
            title: "Sony portable / ULT",
            summary: "Respect small drivers — cut mud, light presence. Not a ULT-button clone.",
            curve: curve(
                gains: [-3.0, -2.0, 0.5, 2.0, -0.5],
                broadband: 0
            )
        ),
        NarrowPreset(
            id: "desktop-nearfield",
            title: "Desk speaker",
            summary: "Mild desk-boundary bass cut; even mids.",
            curve: curve(
                gains: [-2.0, -0.5, 0.5, 0.5, -0.5],
                broadband: 0
            )
        ),
        NarrowPreset(
            id: "generic-safe",
            title: "Just make it safer",
            summary: "Almost flat with a gentle harshness cut. Never embarrassing.",
            curve: curve(
                gains: [-0.5, 0, 0, -0.5, -1.5],
                broadband: 0
            )
        ),
    ]

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
        if name.contains("echo") || name.contains("alexa") || name.contains("amazon") {
            return "echo-class"
        }
        if name.contains("bluetooth") || name.contains(" bt") || name.hasPrefix("bt ") {
            return "bt-portable"
        }
        return "bt-portable"
    }

    public static func looksLikeHeadphones(deviceName: String) -> Bool {
        let name = deviceName.lowercased()
        let markers = ["airpods", "headphone", "headset", "beats ", "wh-1000", "iem", "earphone"]
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
