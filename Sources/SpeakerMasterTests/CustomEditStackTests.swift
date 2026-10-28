import Testing
@testable import SpeakerMaster

@Suite("Custom edit stack")
struct CustomEditStackTests {
    @Test("undo restores prior committed curve")
    func undoRestoresPrior() {
        var stack = CustomEditStack(base: .flat)
        #expect(!stack.canUndo)

        let warmer = CustomIntentCatalog.intent(id: "warmer")!.curve
        stack.commit(warmer)
        #expect(stack.current == warmer.sanitized())
        #expect(stack.canUndo)

        let clearer = CustomIntentCatalog.intent(id: "clearer")!.curve
        stack.commit(clearer)
        #expect(stack.undo() == warmer.sanitized())
        #expect(stack.current == warmer.sanitized())
        #expect(stack.undo() == .flat.sanitized())
        #expect(!stack.canUndo)
        #expect(stack.undo() == nil)
    }

    @Test("identical commit does not grow history")
    func identicalCommitNoOp() {
        var stack = CustomEditStack(base: .flat)
        stack.commit(.flat)
        #expect(!stack.canUndo)
        let warmer = CustomIntentCatalog.intent(id: "warmer")!.curve
        stack.commit(warmer)
        stack.commit(warmer)
        #expect(stack.historyDepth == 1)
    }

    @Test("resetToBase clears undo and restores base")
    func resetToBase() {
        var stack = CustomEditStack(base: .flat)
        stack.commit(CustomIntentCatalog.intent(id: "warmer")!.curve)
        let restored = stack.resetToBase()
        #expect(restored == .flat.sanitized())
        #expect(!stack.canUndo)
        #expect(stack.current == .flat.sanitized())
    }

    @Test("replaceBase keeps current edit but updates reset target")
    func replaceBase() {
        let measure = CustomIntentCatalog.intent(id: "clearer")!.curve
        var stack = CustomEditStack(base: measure)
        stack.commit(CustomIntentCatalog.intent(id: "warmer")!.curve)
        let newBase = CustomIntentCatalog.intent(id: "bass-tamed")!.curve
        stack.replaceBase(newBase)
        #expect(stack.resetToBase() == newBase.sanitized())
    }
}
