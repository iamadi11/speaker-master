import Testing
@testable import SpeakerMaster

@Suite("Narrow catalog")
struct NarrowCatalogTests {
    @Test("all presets obey safety caps")
    func presetsWithinCaps() {
        for preset in NarrowCatalog.all {
            let curve = preset.curve.sanitized()
            #expect(curve.broadbandGainDb <= SafetyLimits.maxBroadbandBoostDb)
            for band in curve.bands {
                let maxBoost = SafetyLimits.maxBandBoostDb(frequencyHz: band.frequencyHz)
                #expect(band.gainDb <= maxBoost)
            }
        }
    }

    @Test("taxonomy covers every preset exactly once per category listing")
    func taxonomyCoverage() {
        let listed = NarrowCatalog.categoriesInOrder.flatMap { NarrowCatalog.presets(in: $0) }
        #expect(listed.count == NarrowCatalog.all.count)
        #expect(Set(listed.map(\.id)) == Set(NarrowCatalog.all.map(\.id)))
        #expect(NarrowCatalog.preset(id: "bt-portable")?.category == .portable)
        #expect(NarrowCatalog.preset(id: "echo-class")?.category == .smartSpeaker)
        #expect(NarrowCatalog.preset(id: "desktop-nearfield")?.category == .desk)
        #expect(NarrowCatalog.preset(id: "generic-safe")?.category == .fallback)
    }

    @Test("suggests sony-ult for ULT Field name")
    func suggestsSonyULT() {
        let id = NarrowCatalog.suggestedPresetID(deviceName: "ULT Field 1")
        #expect(id == "sony-ult-portable")
    }

    @Test("suggests echo-class for Echo name")
    func suggestsEcho() {
        #expect(NarrowCatalog.suggestedPresetID(deviceName: "Echo Dot") == "echo-class")
    }

    @Test("suggests desk speaker for MacBook / built-in")
    func suggestsDesk() {
        #expect(NarrowCatalog.suggestedPresetID(deviceName: "MacBook Pro Speakers") == "desktop-nearfield")
        #expect(NarrowCatalog.suggestedPresetID(deviceName: "Built-in Output") == "desktop-nearfield")
        #expect(NarrowCatalog.looksLikeDeskSpeaker(deviceName: "iMac Speakers"))
    }

    @Test("falls back to bt-portable for unknown BT")
    func fallbackBT() {
        #expect(NarrowCatalog.suggestedPresetID(deviceName: "Some Bluetooth Speaker") == "bt-portable")
    }

    @Test("flags headphone-looking names")
    func flagsHeadphones() {
        #expect(NarrowCatalog.looksLikeHeadphones(deviceName: "AirPods Pro"))
        #expect(!NarrowCatalog.looksLikeHeadphones(deviceName: "ULT Field 1"))
        #expect(NarrowCatalog.suggestedPresetID(deviceName: "AirPods Pro") == "generic-safe")
    }
}
