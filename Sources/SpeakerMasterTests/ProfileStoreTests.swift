import Foundation
import Testing
@testable import SpeakerMaster

@Suite("Profile store")
struct ProfileStoreTests {
    @Test("saves and reclamps on load")
    func saveLoad() {
        let store = InMemoryProfileStore()
        let identity = SpeakerIdentity(outputUID: "uid-a", displayName: "ULT Field 1")
        let hot = EQCurve(
            bands: [EQBand(id: "b", frequencyHz: 80, gainDb: 9, q: 1, type: .peaking)],
            broadbandGainDb: 0,
            bypassed: false
        )
        store.save(SpeakerProfile(identity: identity, source: .narrow, narrowPresetID: "sony-ult-portable", curve: hot))
        let loaded = store.profile(forOutputUID: "uid-a")
        #expect(loaded != nil)
        #expect(loaded?.curve.bands.first?.gainDb == 4)
        #expect(loaded?.narrowPresetID == "sony-ult-portable")
    }

    @Test("retry removes profile")
    func retryClears() {
        let store = InMemoryProfileStore()
        let identity = SpeakerIdentity(outputUID: "uid-b", displayName: "Echo")
        store.save(SpeakerProfile(identity: identity, source: .measure, curve: .flat))
        store.remove(outputUID: "uid-b")
        #expect(store.profile(forOutputUID: "uid-b") == nil)
    }
}
