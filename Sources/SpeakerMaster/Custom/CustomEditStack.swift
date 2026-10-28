/// Pure undo seam for Custom console commits (Matt Pocock: test at public boundary).
public struct CustomEditStack: Sendable, Equatable {
    public private(set) var base: EQCurve
    public private(set) var current: EQCurve
    private var past: [EQCurve]

    public init(base: EQCurve) {
        let safe = base.sanitized()
        self.base = safe
        self.current = safe
        self.past = []
    }

    public var canUndo: Bool { !past.isEmpty }

    /// Number of undo steps available (not including current).
    public var historyDepth: Int { past.count }

    public mutating func commit(_ curve: EQCurve) {
        let next = curve.sanitized()
        guard next != current else { return }
        past.append(current)
        current = next
    }

    @discardableResult
    public mutating func undo() -> EQCurve? {
        guard let previous = past.popLast() else { return nil }
        current = previous
        return previous
    }

    @discardableResult
    public mutating func resetToBase() -> EQCurve {
        past.removeAll()
        current = base
        return base
    }

    /// Updates the Reset target (e.g. after Auto Measure/Narrow) without clearing current edits.
    public mutating func replaceBase(_ curve: EQCurve) {
        base = curve.sanitized()
    }
}
