import Foundation

/// RBJ cookbook biquad coefficients + realtime sample processor (stereo-agnostic mono path).
public struct BiquadCoefficients: Hashable, Sendable {
    public var b0: Double
    public var b1: Double
    public var b2: Double
    public var a1: Double
    public var a2: Double

    public static let identity = BiquadCoefficients(b0: 1, b1: 0, b2: 0, a1: 0, a2: 0)

    public static func from(band: EQBand, sampleRate: Double) -> BiquadCoefficients {
        let sr = max(sampleRate, 1)
        let f0 = min(max(band.frequencyHz, 20), sr * 0.45)
        let w0 = 2 * Double.pi * f0 / sr
        let cosw = cos(w0)
        let sinw = sin(w0)
        let alpha = sinw / (2 * max(band.q, 0.1))
        let A = pow(10, band.gainDb / 40)

        switch band.type {
        case .peaking:
            let b0 = 1 + alpha * A
            let b1 = -2 * cosw
            let b2 = 1 - alpha * A
            let a0 = 1 + alpha / A
            let a1 = -2 * cosw
            let a2 = 1 - alpha / A
            return normalize(b0: b0, b1: b1, b2: b2, a0: a0, a1: a1, a2: a2)
        case .lowShelf:
            let twoSqrtAAlpha = 2 * sqrt(A) * alpha
            let b0 = A * ((A + 1) - (A - 1) * cosw + twoSqrtAAlpha)
            let b1 = 2 * A * ((A - 1) - (A + 1) * cosw)
            let b2 = A * ((A + 1) - (A - 1) * cosw - twoSqrtAAlpha)
            let a0 = (A + 1) + (A - 1) * cosw + twoSqrtAAlpha
            let a1 = -2 * ((A - 1) + (A + 1) * cosw)
            let a2 = (A + 1) + (A - 1) * cosw - twoSqrtAAlpha
            return normalize(b0: b0, b1: b1, b2: b2, a0: a0, a1: a1, a2: a2)
        case .highShelf:
            let twoSqrtAAlpha = 2 * sqrt(A) * alpha
            let b0 = A * ((A + 1) + (A - 1) * cosw + twoSqrtAAlpha)
            let b1 = -2 * A * ((A - 1) + (A + 1) * cosw)
            let b2 = A * ((A + 1) + (A - 1) * cosw - twoSqrtAAlpha)
            let a0 = (A + 1) - (A - 1) * cosw + twoSqrtAAlpha
            let a1 = 2 * ((A - 1) - (A + 1) * cosw)
            let a2 = (A + 1) - (A - 1) * cosw - twoSqrtAAlpha
            return normalize(b0: b0, b1: b1, b2: b2, a0: a0, a1: a1, a2: a2)
        case .lowPass:
            let b0 = (1 - cosw) / 2
            let b1 = 1 - cosw
            let b2 = (1 - cosw) / 2
            let a0 = 1 + alpha
            let a1 = -2 * cosw
            let a2 = 1 - alpha
            return normalize(b0: b0, b1: b1, b2: b2, a0: a0, a1: a1, a2: a2)
        case .highPass:
            let b0 = (1 + cosw) / 2
            let b1 = -(1 + cosw)
            let b2 = (1 + cosw) / 2
            let a0 = 1 + alpha
            let a1 = -2 * cosw
            let a2 = 1 - alpha
            return normalize(b0: b0, b1: b1, b2: b2, a0: a0, a1: a1, a2: a2)
        }
    }

    private static func normalize(
        b0: Double, b1: Double, b2: Double,
        a0: Double, a1: Double, a2: Double
    ) -> BiquadCoefficients {
        let inv = 1 / a0
        return BiquadCoefficients(
            b0: b0 * inv,
            b1: b1 * inv,
            b2: b2 * inv,
            a1: a1 * inv,
            a2: a2 * inv
        )
    }
}

/// Direct-form I state for one channel.
public struct BiquadProcessor: Sendable {
    private var coeffs: BiquadCoefficients
    private var x1: Double = 0
    private var x2: Double = 0
    private var y1: Double = 0
    private var y2: Double = 0

    public init(coefficients: BiquadCoefficients = .identity) {
        self.coeffs = coefficients
    }

    public mutating func setCoefficients(_ coefficients: BiquadCoefficients) {
        coeffs = coefficients
    }

    public mutating func reset() {
        x1 = 0; x2 = 0; y1 = 0; y2 = 0
    }

    public mutating func process(_ input: Float) -> Float {
        let x = Double(input)
        let y = coeffs.b0 * x + coeffs.b1 * x1 + coeffs.b2 * x2
            - coeffs.a1 * y1 - coeffs.a2 * y2
        x2 = x1; x1 = x
        y2 = y1; y1 = y
        return Float(y)
    }
}

/// Cascade of peaking/shelf bands + broadband gain + soft clip toward −1 dBTP.
public struct EQEngine: Sendable {
    private var filters: [BiquadProcessor]
    private var broadbandLinear: Double
    private var bypassed: Bool
    private let limiterCeiling: Double

    public init(sampleRate: Double = 48_000, curve: EQCurve = .flat) {
        let safe = curve.sanitized()
        self.bypassed = safe.bypassed
        self.broadbandLinear = pow(10, safe.broadbandGainDb / 20)
        self.filters = safe.bands.map {
            BiquadProcessor(coefficients: .from(band: $0, sampleRate: sampleRate))
        }
        self.limiterCeiling = pow(10, SafetyLimits.truePeakCeilingDbTP / 20)
    }

    public mutating func apply(curve: EQCurve, sampleRate: Double) {
        let safe = curve.sanitized()
        bypassed = safe.bypassed
        broadbandLinear = pow(10, safe.broadbandGainDb / 20)
        if filters.count != safe.bands.count {
            filters = safe.bands.map {
                BiquadProcessor(coefficients: .from(band: $0, sampleRate: sampleRate))
            }
        } else {
            for i in safe.bands.indices {
                filters[i].setCoefficients(.from(band: safe.bands[i], sampleRate: sampleRate))
            }
        }
    }

    public mutating func process(_ input: Float) -> Float {
        if bypassed { return input }
        let x = Double(input) * broadbandLinear
        var sample = Float(x)
        for i in filters.indices {
            sample = filters[i].process(sample)
        }
        // Soft limiter toward true-peak ceiling (Auto always on).
        let y = Double(sample)
        let limited: Double
        if abs(y) <= limiterCeiling {
            limited = y
        } else {
            limited = limiterCeiling * tanh(y / limiterCeiling)
        }
        return Float(limited)
    }

    public mutating func processBuffer(_ samples: inout [Float]) {
        for i in samples.indices {
            samples[i] = process(samples[i])
        }
    }
}
