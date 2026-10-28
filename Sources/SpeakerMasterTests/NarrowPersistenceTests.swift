import Testing
@testable import SpeakerMaster

@Suite("Narrow persistence")
struct NarrowPersistenceTests {
    @Test("reuses profile when output UID matches")
    func reusesSameSpeaker() {
        let policy = NarrowPersistencePolicy()
        let a = SpeakerIdentity(outputUID: "uid-1", displayName: "ULT Field 1")
        let b = SpeakerIdentity(outputUID: "uid-1", displayName: "Sony ULT Field 1")
        #expect(policy.shouldReuseProfile(stored: a, current: b))
    }

    @Test("invalidates profile when output UID changes")
    func invalidatesNewSpeaker() {
        let policy = NarrowPersistencePolicy()
        let stored = SpeakerIdentity(outputUID: "uid-1", displayName: "ULT Field 1")
        let current = SpeakerIdentity(outputUID: "uid-2", displayName: "Echo")
        #expect(!policy.shouldReuseProfile(stored: stored, current: current))
    }
}
