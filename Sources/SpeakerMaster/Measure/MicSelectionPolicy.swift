import Foundation

/// Pure Measure mic selection rules (Built-in first; Continuity never sticky).
/// Continuity / iPhone mics often return empty buffers on first-pass Measure.
public enum MicSelectionPolicy: Sendable {
    public struct Device: Sendable, Equatable {
        public var id: String
        public var name: String

        public init(id: String, name: String) {
            self.id = id
            self.name = name
        }
    }

    public static func looksLikeContinuityMic(name: String) -> Bool {
        let lower = name.lowercased()
        return lower.contains("iphone") || lower.contains("ipad") || lower.contains("continuity")
    }

    /// Do not persist Continuity across launches — Built-in is the reliable default.
    public static func shouldPersistAsLastMic(name: String) -> Bool {
        !looksLikeContinuityMic(name: name)
    }

    /// Prefer Built-in / MacBook mic; Continuity last.
    public static func preferredInputID(from list: [Device]) -> String? {
        if let builtIn = list.first(where: { $0.id == "BuiltInMicrophoneDevice" }) {
            return builtIn.id
        }
        if let macBook = list.first(where: {
            let name = $0.name.lowercased()
            return name.contains("macbook") && name.contains("microphone")
        }) {
            return macBook.id
        }
        if let local = list.first(where: { !looksLikeContinuityMic(name: $0.name) }) {
            return local.id
        }
        return list.first?.id
    }

    /// Resolve selection after a HAL refresh.
    /// - Keeps an in-session choice (including Continuity) while the device is still present.
    /// - Honors remembered UID only when it is **not** Continuity.
    /// - Otherwise falls back to `preferredInputID` (Built-in over Continuity).
    public static func resolveSelection(
        devices: [Device],
        rememberedID: String?,
        currentID: String?
    ) -> String? {
        if let currentID, devices.contains(where: { $0.id == currentID }) {
            return currentID
        }
        if let rememberedID,
           let remembered = devices.first(where: { $0.id == rememberedID }),
           shouldPersistAsLastMic(name: remembered.name)
        {
            return rememberedID
        }
        return preferredInputID(from: devices)
    }
}
