import SpeakerMaster
import SwiftUI

struct CustomEQView: View {
    @EnvironmentObject private var model: AppModel
    @State private var bands: [EQBand] = EQCurve.flat.bands
    @State private var broadband: Double = 0
    @State private var showAdvanced = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Custom")
                        .font(SMTheme.titleFont)
                        .foregroundStyle(SMTheme.ink)
                    Text("Same engine as Auto. Caps from the safety sheet. Progressive depth — bands first.")
                        .font(SMTheme.bodyFont)
                        .foregroundStyle(SMTheme.muted)
                }
                Spacer()
                BypassButton()
            }

            HStack(spacing: 12) {
                Button(model.player.isPlaying ? "Stop audition" : "Play audition") {
                    model.toggleAudition()
                }
                .buttonStyle(.borderedProminent)
                .tint(SMTheme.accent)

                Button("Reset") {
                    bands = EQCurve.flat.bands
                    broadband = 0
                    commit()
                    model.resetCustom()
                }
                .buttonStyle(.bordered)

                Toggle("Show Q / type", isOn: $showAdvanced)
                    .toggleStyle(.switch)
                    .frame(width: 160)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .bottom, spacing: 18) {
                    ForEach($bands) { $band in
                        bandColumn(band: $band)
                    }
                }
                .padding(.vertical, 8)
            }
            .frame(maxHeight: .infinity)

            VStack(alignment: .leading, spacing: 6) {
                Text("Broadband \(broadband, format: .number.precision(.fractionLength(1))) dB (≤ +\(Int(SafetyLimits.maxBroadbandBoostDb)))")
                    .font(SMTheme.captionFont)
                    .foregroundStyle(SMTheme.muted)
                Slider(value: $broadband, in: -6...SafetyLimits.maxBroadbandBoostDb, step: 0.5) { editing in
                    if !editing { commit() }
                }
                .tint(SMTheme.accent)
                .onChange(of: broadband) { _, _ in
                    // Live preview while dragging
                    preview()
                }
            }

            SystemHostStatusView()

            Text("Limiter stays on. Expert overrides above Auto caps are not enabled in v1.")
                .font(SMTheme.captionFont)
                .foregroundStyle(SMTheme.muted)
        }
        .padding(28)
        .onAppear {
            bands = model.activeCurve.bands
            broadband = model.activeCurve.broadbandGainDb
        }
    }

    private func bandColumn(band: Binding<EQBand>) -> some View {
        let maxBoost = SafetyLimits.maxBandBoostDb(frequencyHz: band.wrappedValue.frequencyHz)
        return VStack(spacing: 8) {
            Text(formatHz(band.wrappedValue.frequencyHz))
                .font(SMTheme.captionFont.weight(.semibold))
                .foregroundStyle(SMTheme.ink)
            Text(String(format: "%+.1f dB", band.wrappedValue.gainDb))
                .font(SMTheme.captionFont)
                .foregroundStyle(SMTheme.muted)
                .monospacedDigit()

            Slider(value: Binding(
                get: { band.wrappedValue.gainDb },
                set: { newValue in
                    band.wrappedValue.gainDb = SafetyLimits.clampBandGain(
                        newValue,
                        frequencyHz: band.wrappedValue.frequencyHz
                    )
                    preview()
                }
            ), in: -18...maxBoost, step: 0.5) { editing in
                if !editing { commit() }
            }
            .frame(width: 36, height: 180)
            // Vertical feel via rotation
            .rotationEffect(.degrees(-90))
            .frame(width: 72, height: 200)

            if showAdvanced {
                Slider(value: Binding(
                    get: { band.wrappedValue.q },
                    set: {
                        band.wrappedValue.q = min(10, max(0.1, $0))
                        preview()
                    }
                ), in: 0.3...4, step: 0.1) { editing in
                    if !editing { commit() }
                }
                .frame(width: 72)
                Text("Q \(band.wrappedValue.q, format: .number.precision(.fractionLength(1)))")
                    .font(SMTheme.captionFont)
                    .foregroundStyle(SMTheme.muted)
            }
        }
        .padding(10)
        .background(SMTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(SMTheme.border, lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(formatHz(band.wrappedValue.frequencyHz)) band")
    }

    private func formatHz(_ hz: Double) -> String {
        if hz >= 1000 {
            return String(format: "%.1fk", hz / 1000)
        }
        return "\(Int(hz)) Hz"
    }

    private func preview() {
        let curve = EQCurve(bands: bands, broadbandGainDb: broadband, bypassed: model.bypassed).sanitized()
        model.player.apply(curve: curve)
    }

    private func commit() {
        let curve = EQCurve(bands: bands, broadbandGainDb: broadband, bypassed: false).sanitized()
        bands = curve.bands
        broadband = curve.broadbandGainDb
        model.updateCustom(curve)
    }
}
