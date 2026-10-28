import Testing
@testable import SpeakerMaster

@Suite("Mic selection policy")
struct MicSelectionPolicyTests {
    private let builtIn = MicSelectionPolicy.Device(id: "BuiltInMicrophoneDevice", name: "MacBook Pro Microphone")
    private let continuity = MicSelectionPolicy.Device(id: "iPhone-Continuity-UID", name: "Aditya’s iPhone Microphone")
    private let usb = MicSelectionPolicy.Device(id: "USB-Mic", name: "USB Condenser Mic")

    @Test("Continuity name detection")
    func continuityDetection() {
        #expect(MicSelectionPolicy.looksLikeContinuityMic(name: "Aditya’s iPhone Microphone"))
        #expect(MicSelectionPolicy.looksLikeContinuityMic(name: "iPad Continuity Camera"))
        #expect(!MicSelectionPolicy.looksLikeContinuityMic(name: "MacBook Pro Microphone"))
        #expect(!MicSelectionPolicy.shouldPersistAsLastMic(name: "iPhone Microphone"))
        #expect(MicSelectionPolicy.shouldPersistAsLastMic(name: "Built-in Microphone"))
    }

    @Test("preferred input picks Built-in over Continuity")
    func preferredBuiltIn() {
        let list = [continuity, builtIn, usb]
        #expect(MicSelectionPolicy.preferredInputID(from: list) == builtIn.id)
    }

    @Test("remembered Continuity does not stick when Built-in exists")
    func continuityNotSticky() {
        let list = [continuity, builtIn]
        let resolved = MicSelectionPolicy.resolveSelection(
            devices: list,
            rememberedID: continuity.id,
            currentID: nil
        )
        #expect(resolved == builtIn.id)
    }

    @Test("remembered local mic sticks")
    func localSticky() {
        let list = [continuity, builtIn, usb]
        let resolved = MicSelectionPolicy.resolveSelection(
            devices: list,
            rememberedID: usb.id,
            currentID: nil
        )
        #expect(resolved == usb.id)
    }

    @Test("in-session Continuity choice is kept until refresh loses the device")
    func sessionContinuityKept() {
        let list = [continuity, builtIn]
        let resolved = MicSelectionPolicy.resolveSelection(
            devices: list,
            rememberedID: builtIn.id,
            currentID: continuity.id
        )
        #expect(resolved == continuity.id)
    }

    @Test("missing current falls back through remembered Continuity to Built-in")
    func dropMissingContinuity() {
        let list = [builtIn]
        let resolved = MicSelectionPolicy.resolveSelection(
            devices: list,
            rememberedID: continuity.id,
            currentID: continuity.id
        )
        #expect(resolved == builtIn.id)
    }
}
