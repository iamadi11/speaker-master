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

    @Test("suggests sony-ult for ULT Field name")
    func suggestsSonyULT() {
        let id = NarrowCatalog.suggestedPresetID(deviceName: "ULT Field 1")
        #expect(id == "sony-ult-portable")
    }

    @Test("suggests echo-class for Echo name")
    func suggestsEcho() {
        #expect(NarrowCatalog.suggestedPresetID(deviceName: "Echo Dot") == "echo-class")
    }

    @Test("falls back to bt-portable for unknown BT")
    func fallbackBT() {
        #expect(NarrowCatalog.suggestedPresetID(deviceName: "Some Bluetooth Speaker") == "bt-portable")
    }

    @Test("flags headphone-looking names")
    func flagsHeadphones() {
        #expect(NarrowCatalog.looksLikeHeadphones(deviceName: "AirPods Pro"))
        #expect(!NarrowCatalog.looksLikeHeadphones(deviceName: "ULT Field 1"))
    }
}
