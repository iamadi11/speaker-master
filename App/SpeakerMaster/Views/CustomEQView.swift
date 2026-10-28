import AppKit
import SpeakerMaster
import SwiftUI

struct CustomEQView: View {
    @EnvironmentObject private var model: AppModel
    @State private var bands: [EQBand] = EQCurve.flat.bands
    @State private var broadband: Double = 0
    @State private var showAdvanced = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SMTheme.spaceLG) {
                header
                basedOnRow
                intentStrip
                bandConsole
                broadbandRow
                limiterStrip
                toolbarRow
                SystemHostStatusView()
            }
            .padding(SMTheme.spaceXXL)
            .frame(maxWidth: 920, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.18), value: showAdvanced)
        .onAppear(perform: syncFromModel)
        .onChange(of: model.activeCurve) { _, _ in
            syncFromModel()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: SMTheme.spaceXS) {
            Text("Custom")
                .font(SMTheme.titleFont)
                .foregroundStyle(SMTheme.ink)
            Text("Same engine as Auto · refine with undo · safety caps stay on")
                .font(SMTheme.captionFont)
                .foregroundStyle(SMTheme.muted)
        }
    }

    private var basedOnRow: some View {
        Text(model.customBasedOnLabel)
            .font(SMTheme.captionFont)
            .foregroundStyle(SMTheme.muted)
            .accessibilityLabel(model.customBasedOnLabel)
    }

    private var intentStrip: some View {
        VStack(alignment: .leading, spacing: SMTheme.spaceSM) {
            Text("Quick feel")
                .font(SMTheme.captionFont.weight(.semibold))
                .foregroundStyle(SMTheme.tertiary)
                .textCase(.uppercase)
                .tracking(0.4)
            // Soft chips — selected = light fill + accent hairline (not solid teal bricks).
            FlowIntentChips(
                intents: CustomIntentCatalog.all,
                selectedID: model.matchedCustomIntentID
            ) { intent in
                model.applyCustomIntent(intent)
                syncFromModel()
            }
        }
    }

    private var limiterStrip: some View {
        let live = EQCurve(bands: bands, broadbandGainDb: broadband, bypassed: false).sanitized()
        let headroom = live.constructiveHeadroomDb()
        let nearCap = headroom < 1.0
        return Text(
            nearCap
                ? String(format: "Limiter on · headroom %.1f dB — further boosts scale under the ceiling", max(0, headroom))
                : String(
                    format: "Limiter on · band ≤ +%d · bass ≤ +%d · broadband ≤ +%d · total ≤ +%d · headroom %.1f dB",
                    Int(SafetyLimits.maxPerBandBoostDb),
                    Int(SafetyLimits.maxBassBoostDb),
                    Int(SafetyLimits.maxBroadbandBoostDb),
                    Int(SafetyLimits.maxTotalConstructiveGainDb),
                    headroom
                )
        )
        .font(SMTheme.captionFont)
        .foregroundStyle(nearCap ? SMTheme.warning : SMTheme.tertiary)
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityLabel(
            nearCap
                ? "Limiter on, near total constructive ceiling"
                : "Limiter on, safety caps active"
        )
    }

    private var bandConsole: some View {
        VStack(alignment: .leading, spacing: SMTheme.spaceXS) {
            HStack {
                Text("Tone bands")
                    .font(SMTheme.captionFont.weight(.semibold))
                    .foregroundStyle(SMTheme.muted)
                Spacer()
                Toggle("Q / type", isOn: $showAdvanced)
                    .toggleStyle(.switch)
                    .controlSize(.small)
                    .labelsHidden()
                    .accessibilityLabel("Show Q and filter type")
                Text("Q / type")
                    .font(SMTheme.captionFont)
                    .foregroundStyle(SMTheme.muted)
            }

            magnitudePreview

            HStack(alignment: .bottom, spacing: 8) {
                ForEach($bands) { $band in
                    bandColumn(band: $band)
                }
            }
            .padding(.vertical, 4)
        }
        .padding(SMTheme.spaceSM)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: SMTheme.radiusPanel, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: SMTheme.radiusPanel, style: .continuous)
                .strokeBorder(SMTheme.border.opacity(0.55), lineWidth: 0.5)
        )
    }

    private var magnitudePreview: some View {
        let freqs: [Double] = [60, 120, 250, 500, 1000, 2000, 4000, 8000, 12000]
        let curve = EQCurve(bands: bands, broadbandGainDb: broadband, bypassed: false).sanitized()
        let autoBase = model.customAutoBase.sanitized()
        let showGhost = autoBase != curve
        return VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Shape preview")
                    .font(SMTheme.captionFont.weight(.semibold))
                    .foregroundStyle(SMTheme.muted)
                Spacer(minLength: 0)
                if showGhost {
                    Text("Ghost = Auto base")
                        .font(SMTheme.captionFont)
                        .foregroundStyle(SMTheme.muted)
                }
            }
            HStack(alignment: .bottom, spacing: 3) {
                ForEach(freqs, id: \.self) { hz in
                    let mag = curve.approximateMagnitudeDb(atFrequencyHz: hz, sampleRate: 48_000)
                    let baseMag = autoBase.approximateMagnitudeDb(atFrequencyHz: hz, sampleRate: 48_000)
                    let height = min(36, max(4, 18 + mag * 3))
                    let baseHeight = min(36, max(4, 18 + baseMag * 3))
                    ZStack(alignment: .bottom) {
                        if showGhost {
                            RoundedRectangle(cornerRadius: 2, style: .continuous)
                                .fill(SMTheme.ink.opacity(0.12))
                                .frame(width: 14, height: baseHeight)
                        }
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .fill(mag >= 0 ? SMTheme.accent.opacity(0.75) : SMTheme.muted.opacity(0.45))
                            .frame(width: 14, height: height)
                    }
                    .frame(width: 14, height: 36, alignment: .bottom)
                    .accessibilityHidden(true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            showGhost
                ? "Approximate EQ shape with Auto base ghost overlay"
                : "Approximate EQ shape preview"
        )
    }

    private var broadbandRow: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Broadband")
                    .font(SMTheme.captionFont.weight(.semibold))
                    .foregroundStyle(SMTheme.muted)
                Spacer()
                Text("\(broadband, format: .number.precision(.fractionLength(1))) dB")
                    .font(SMTheme.monoCaption)
                    .foregroundStyle(SMTheme.ink)
            }
            Slider(value: $broadband, in: -6...SafetyLimits.maxBroadbandBoostDb, step: 0.5) { editing in
                if !editing { commit() }
            }
            .tint(SMTheme.accent)
            .onChange(of: broadband) { _, _ in
                preview()
            }
            Text("≤ +\(Int(SafetyLimits.maxBroadbandBoostDb)) dB safety ceiling")
                .font(SMTheme.captionFont)
                .foregroundStyle(SMTheme.muted)
        }
    }

    private var toolbarRow: some View {
        HStack(spacing: SMTheme.spaceXS) {
            Button(model.player.isPlaying ? "Stop" : "Audition") {
                model.toggleAudition()
            }
            .smProminentButton()
            .frame(minHeight: SMTheme.minTouch)

            Button("Undo") {
                model.undoCustom()
                syncFromModel()
            }
            .smBorderedButton()
            .disabled(!model.customCanUndo)
            .frame(minHeight: SMTheme.minTouch)
            .keyboardShortcut("z", modifiers: [.command])

            Button("Reset to Auto") {
                model.resetCustomToAuto()
                syncFromModel()
            }
            .smBorderedButton()
            .frame(minHeight: SMTheme.minTouch)
            .help("Restore the last Auto Measure or Narrow curve")

            Button("Flat") {
                model.resetCustom()
                syncFromModel()
            }
            .smBorderedButton()
            .frame(minHeight: SMTheme.minTouch)

            Spacer(minLength: 0)
        }
    }

    private func bandColumn(band: Binding<EQBand>) -> some View {
        let maxBoost = SafetyLimits.maxBandBoostDb(frequencyHz: band.wrappedValue.frequencyHz)
        let atCap = band.wrappedValue.gainDb >= maxBoost - 0.01
        return VStack(spacing: 4) {
            Text(formatHz(band.wrappedValue.frequencyHz))
                .font(SMTheme.captionFont.weight(.semibold))
                .foregroundStyle(SMTheme.ink)
            Text(String(format: "%+.1f", band.wrappedValue.gainDb))
                .font(SMTheme.monoCaption)
                .foregroundStyle(atCap ? SMTheme.warning : SMTheme.muted)
            if atCap {
                Text("cap")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(SMTheme.warning)
                    .accessibilityLabel("At safety boost ceiling")
            }

            ZStack {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(SMTheme.border.opacity(0.55))
                    .frame(width: 10, height: 140)
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
                .tint(atCap ? SMTheme.warning : SMTheme.accent)
                .frame(width: 28, height: 140)
                .rotationEffect(.degrees(-90))
                .accessibilityLabel("Gain")
                .accessibilityValue(String(format: "%.1f dB", band.wrappedValue.gainDb))
            }
            .frame(width: 56, height: 150)
            .onTapGesture(count: 2) {
                band.wrappedValue.gainDb = 0
                commit()
            }
            .help("Double-click to zero this band")

            // Single-pointer alternative to the rotated drag fader (WCAG 2.2).
            HStack(spacing: 4) {
                Button {
                    nudgeGain(band, by: -0.5)
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 11, weight: .bold))
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
                .background(SMTheme.border.opacity(0.45))
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                .accessibilityLabel("Decrease \(formatHz(band.wrappedValue.frequencyHz)) gain")

                Button {
                    nudgeGain(band, by: 0.5)
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .bold))
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
                .background(SMTheme.border.opacity(0.45))
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                .accessibilityLabel("Increase \(formatHz(band.wrappedValue.frequencyHz)) gain")
            }

            if showAdvanced {
                Text("Hz")
                    .font(SMTheme.captionFont)
                    .foregroundStyle(SMTheme.muted)
                Slider(value: Binding(
                    get: { log2(max(40, band.wrappedValue.frequencyHz)) },
                    set: { logValue in
                        let hz = pow(2.0, logValue)
                        band.wrappedValue.frequencyHz = min(16_000, max(40, hz))
                        band.wrappedValue.gainDb = SafetyLimits.clampBandGain(
                            band.wrappedValue.gainDb,
                            frequencyHz: band.wrappedValue.frequencyHz
                        )
                        preview()
                    }
                ), in: log2(40)...log2(16_000)) { editing in
                    if !editing { commit() }
                }
                .frame(width: 56)
                .accessibilityLabel("Center frequency")
                .accessibilityValue(formatHz(band.wrappedValue.frequencyHz))

                Slider(value: Binding(
                    get: { band.wrappedValue.q },
                    set: {
                        band.wrappedValue.q = min(10, max(0.1, $0))
                        preview()
                    }
                ), in: 0.3...4, step: 0.1) { editing in
                    if !editing { commit() }
                }
                .frame(width: 56)
                Text("Q \(band.wrappedValue.q, format: .number.precision(.fractionLength(1)))")
                    .font(SMTheme.captionFont)
                    .foregroundStyle(SMTheme.muted)

                Picker("Type", selection: Binding(
                    get: { band.wrappedValue.type },
                    set: {
                        band.wrappedValue.type = $0
                        commit()
                    }
                )) {
                    Text("Peak").tag(EQBand.FilterType.peaking)
                    Text("LS").tag(EQBand.FilterType.lowShelf)
                    Text("HS").tag(EQBand.FilterType.highShelf)
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .frame(width: 64)
                .accessibilityLabel("Filter type")
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(
            atCap
                ? "\(formatHz(band.wrappedValue.frequencyHz)) band, at safety cap"
                : "\(formatHz(band.wrappedValue.frequencyHz)) band"
        )
        .accessibilityHint("Use plus or minus, or double-click fader to zero")
    }

    private func nudgeGain(_ band: Binding<EQBand>, by delta: Double) {
        let maxBoost = SafetyLimits.maxBandBoostDb(frequencyHz: band.wrappedValue.frequencyHz)
        let next = min(maxBoost, max(-18, band.wrappedValue.gainDb + delta))
        band.wrappedValue.gainDb = SafetyLimits.clampBandGain(
            next,
            frequencyHz: band.wrappedValue.frequencyHz
        )
        commit()
    }

    private func formatHz(_ hz: Double) -> String {
        if hz >= 1000 {
            return String(format: "%.1fk", hz / 1000)
        }
        return "\(Int(hz))"
    }

    private func syncFromModel() {
        bands = model.activeCurve.bands
        broadband = model.activeCurve.broadbandGainDb
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

/// Soft intent chips (modern minimal — no solid accent bricks).
private struct FlowIntentChips: View {
    let intents: [CustomIntent]
    let selectedID: String?
    let onSelect: (CustomIntent) -> Void

    var body: some View {
        // Simple wrapping via adaptive grid keeps dependency-free layout.
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 88), spacing: SMTheme.spaceSM)],
            alignment: .leading,
            spacing: SMTheme.spaceSM
        ) {
            ForEach(intents) { intent in
                let selected = selectedID == intent.id
                Button {
                    onSelect(intent)
                } label: {
                    Text(intent.title)
                        .font(SMTheme.captionFont.weight(selected ? .semibold : .medium))
                        .foregroundStyle(selected ? SMTheme.accent : SMTheme.ink)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .frame(maxWidth: .infinity, minHeight: SMTheme.minTouch)
                        .background(
                            selected ? SMTheme.accentSoft : Color.clear,
                            in: RoundedRectangle(cornerRadius: SMTheme.radiusControl, style: .continuous)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: SMTheme.radiusControl, style: .continuous)
                                .strokeBorder(
                                    selected ? SMTheme.accent.opacity(0.7) : SMTheme.border.opacity(0.5),
                                    lineWidth: 0.5
                                )
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(intent.title)
                .accessibilityHint(intent.summary)
                .accessibilityAddTraits(selected ? .isSelected : [])
                .help(intent.summary)
            }
        }
    }
}
