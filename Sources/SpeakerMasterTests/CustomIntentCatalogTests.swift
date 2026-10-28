import Testing
@testable import SpeakerMaster

@Suite("Custom intent catalog")
struct CustomIntentCatalogTests {
    @Test("paper L0 intents are present")
    func paperIntentsPresent() {
        let ids = Set(CustomIntentCatalog.all.map(\.id))
        #expect(ids == ["balanced", "warmer", "clearer", "bass-tamed"])
    }

    @Test("every intent curve obeys safety caps")
    func intentsWithinCaps() {
        for intent in CustomIntentCatalog.all {
            let curve = intent.curve.sanitized()
            #expect(curve.broadbandGainDb <= SafetyLimits.maxBroadbandBoostDb)
            for band in curve.bands {
                let maxBoost = SafetyLimits.maxBandBoostDb(frequencyHz: band.frequencyHz)
                #expect(band.gainDb <= maxBoost)
            }
        }
    }

    @Test("balanced is near-flat")
    func balancedNearFlat() {
        let curve = CustomIntentCatalog.intent(id: "balanced")!.curve
        #expect(curve.bands.allSatisfy { abs($0.gainDb) <= 1.0 })
        #expect(abs(curve.broadbandGainDb) < 0.01)
    }

    @Test("bass-tamed cuts bass region")
    func bassTamedCutsBass() {
        let curve = CustomIntentCatalog.intent(id: "bass-tamed")!.curve
        let bass = curve.bands.first { $0.frequencyHz <= SafetyLimits.bassRegionCeilingHz }!
        #expect(bass.gainDb < 0)
    }

    @Test("matches intent when curve equals catalog")
    func matchesExactIntent() {
        let warmer = CustomIntentCatalog.intent(id: "warmer")!
        #expect(CustomIntentCatalog.matchingIntentID(for: warmer.curve) == "warmer")
        // Flat scaffold equals Balanced — UI can highlight that chip.
        #expect(CustomIntentCatalog.matchingIntentID(for: .flat) == "balanced")
    }
}
