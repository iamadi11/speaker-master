import Testing
@testable import SpeakerMaster

@Suite("System EQ empty-state copy")
struct SystemEQCopyTests {
    @Test("permission empty state has title, body, and primary action")
    func permissionEmptyState() throws {
        let copy = try #require(SystemEQEmptyStateCopy.forPhase(.needsPermission))
        #expect(!copy.title.isEmpty)
        #expect(copy.body.contains("Screen & System Audio Recording"))
        #expect(copy.primaryActionTitle == "Open Privacy Settings")
        #expect(copy.secondaryActionTitle == "Retry system EQ")
    }

    @Test("inactive empty state explains next step without panic")
    func inactiveEmptyState() throws {
        let copy = try #require(SystemEQEmptyStateCopy.forPhase(.inactive))
        #expect(copy.title == "System EQ off")
        #expect(copy.body.contains("Auto") || copy.body.contains("Custom"))
        #expect(copy.primaryActionTitle == nil)
    }

    @Test("in-app-only empty state offers retry")
    func inAppOnlyEmptyState() throws {
        let copy = try #require(SystemEQEmptyStateCopy.forPhase(.activeInAppOnly))
        #expect(copy.title.contains("audition"))
        #expect(copy.primaryActionTitle == "Retry system EQ")
    }

    @Test("active system-wide is not an empty state")
    func activeNotEmpty() {
        #expect(SystemEQEmptyStateCopy.forPhase(.activeSystemWide) == nil)
        #expect(SystemEQEmptyStateCopy.forPhase(.starting) == nil)
    }
}
