import Foundation

/// Persisted Auto/Custom result keyed by Core Audio output UID.
public struct SpeakerProfile: Hashable, Sendable, Codable {
    public enum Source: String, Sendable, Codable {
        case measure
        case narrow
        case custom
    }

    public var identity: SpeakerIdentity
    public var source: Source
    public var narrowPresetID: String?
    public var curve: EQCurve
    public var safetyRevision: String
    public var appliedAt: Date

    public init(
        identity: SpeakerIdentity,
        source: Source,
        narrowPresetID: String? = nil,
        curve: EQCurve,
        safetyRevision: String = SafetyLimits.revision,
        appliedAt: Date = Date()
    ) {
        self.identity = identity
        self.source = source
        self.narrowPresetID = narrowPresetID
        self.curve = curve.sanitized()
        self.safetyRevision = safetyRevision
        self.appliedAt = appliedAt
    }

    /// Re-clamp on load so old profiles obey current sheet.
    public func reclamped() -> SpeakerProfile {
        var copy = self
        copy.curve = curve.sanitized()
        copy.safetyRevision = SafetyLimits.revision
        return copy
    }
}

/// In-memory / UserDefaults-backed profile store (seam for tests).
public protocol SpeakerProfileStore: Sendable {
    func profile(forOutputUID uid: String) -> SpeakerProfile?
    func save(_ profile: SpeakerProfile)
    func remove(outputUID: String)
}

public final class InMemoryProfileStore: SpeakerProfileStore, @unchecked Sendable {
    private var storage: [String: SpeakerProfile] = [:]
    private let lock = NSLock()

    public init() {}

    public func profile(forOutputUID uid: String) -> SpeakerProfile? {
        lock.lock(); defer { lock.unlock() }
        return storage[uid]?.reclamped()
    }

    public func save(_ profile: SpeakerProfile) {
        lock.lock(); defer { lock.unlock() }
        storage[profile.identity.outputUID] = profile.reclamped()
    }

    public func remove(outputUID: String) {
        lock.lock(); defer { lock.unlock() }
        storage.removeValue(forKey: outputUID)
    }
}

public final class UserDefaultsProfileStore: SpeakerProfileStore, @unchecked Sendable {
    private let defaults: UserDefaults
    private let prefix = "speaker-master.profile."

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func profile(forOutputUID uid: String) -> SpeakerProfile? {
        guard let data = defaults.data(forKey: prefix + uid) else { return nil }
        guard let profile = try? JSONDecoder().decode(SpeakerProfile.self, from: data) else {
            return nil
        }
        return profile.reclamped()
    }

    public func save(_ profile: SpeakerProfile) {
        let safe = profile.reclamped()
        guard let data = try? JSONEncoder().encode(safe) else { return }
        defaults.set(data, forKey: prefix + safe.identity.outputUID)
    }

    public func remove(outputUID: String) {
        defaults.removeObject(forKey: prefix + outputUID)
    }
}
