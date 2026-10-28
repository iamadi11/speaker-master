import Testing
@testable import SpeakerMaster

@Suite("Safety limits")
struct SafetyLimitsTests {
    @Test("clamps per-band boost to +6 dB")
    func clampsPerBandBoost() {
        #expect(SafetyLimits.clampBandGain(8, frequencyHz: 1000) == 6)
    }

    @Test("clamps bass-region boost to +4 dB")
    func clampsBassBoost() {
        #expect(SafetyLimits.clampBandGain(6, frequencyHz: 80) == 4)
        #expect(SafetyLimits.clampBandGain(3, frequencyHz: 100) == 3)
    }

    @Test("allows deep cuts without floor")
    func allowsDeepCuts() {
        #expect(SafetyLimits.clampBandGain(-24, frequencyHz: 200) == -24)
    }

    @Test("clamps broadband boost to +3 dB")
    func clampsBroadband() {
        #expect(SafetyLimits.clampBroadbandGain(5) == 3)
        #expect(SafetyLimits.clampBroadbandGain(1.5) == 1.5)
    }

    @Test("reports when constructive gain exceeds total ceiling")
    func detectsConstructiveOverCap() {
        #expect(SafetyLimits.constructiveGainWithinCap(atFrequencyHz: 1000, overlappingBoostsDb: [4, 3]) == false)
        #expect(SafetyLimits.constructiveGainWithinCap(atFrequencyHz: 1000, overlappingBoostsDb: [3, 2]) == true)
    }
}
