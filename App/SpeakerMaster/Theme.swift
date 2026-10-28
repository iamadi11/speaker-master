import AppKit
import SwiftUI

/// Modern-minimal macOS chrome (macos-design + apple-design HIG).
/// Hierarchy via background levels, not heavy borders. Accent is sparse highlight only.
enum SMTheme {
    // MARK: - Color (light + dark designed independently)

    static let background = Color(nsColor: .windowBackgroundColor)
    static let surface = Color(nsColor: .controlBackgroundColor)
    static let ink = Color(nsColor: .labelColor)
    static let muted = Color(nsColor: .secondaryLabelColor)
    static let tertiary = Color(nsColor: .tertiaryLabelColor)
    static let border = Color(nsColor: .separatorColor)

    /// Quiet accent — emerald, used for primary CTA / selected outline only (never large fills).
    static let accent = Color(light: Color(red: 0.05, green: 0.52, blue: 0.40),
                              dark: Color(red: 0.30, green: 0.78, blue: 0.55))
    static let accentSoft = accent.opacity(0.10)

    static let danger = Color(light: Color(red: 0.86, green: 0.15, blue: 0.15),
                              dark: Color(red: 1.0, green: 0.27, blue: 0.23))
    static let bypass = Color(light: Color(red: 0.70, green: 0.42, blue: 0.10),
                              dark: Color(red: 1.0, green: 0.62, blue: 0.04))
    static let warning = Color(light: Color(red: 0.70, green: 0.42, blue: 0.10),
                               dark: Color(red: 1.0, green: 0.62, blue: 0.04))

    // MARK: - Spacing (8pt) + radii (macos-design)

    static let spaceXS: CGFloat = 4
    static let spaceSM: CGFloat = 8
    static let spaceMD: CGFloat = 12
    static let spaceLG: CGFloat = 16
    static let spaceXL: CGFloat = 24
    static let spaceXXL: CGFloat = 32

    static let radiusControl: CGFloat = 6
    static let radiusCard: CGFloat = 8
    static let radiusPanel: CGFloat = 10

    /// macOS body is ~13pt; prefer semantic system text styles.
    static let titleFont = Font.system(.title2, design: .default).weight(.semibold)
    static let headlineFont = Font.system(.headline, design: .default)
    static let bodyFont = Font.system(.body, design: .default)
    static let captionFont = Font.system(.caption, design: .default)
    static let monoCaption = Font.system(.caption, design: .monospaced)

    static let minTouch: CGFloat = 28
}

private extension Color {
    init(light: Color, dark: Color) {
        self.init(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
            let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            return NSColor(isDark ? dark : light)
        }))
    }
}

// MARK: - Buttons (readable solids; quiet corners)

struct SMBorderedButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.callout, design: .default).weight(.medium))
            .foregroundStyle(SMTheme.ink)
            .padding(.horizontal, 11)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: SMTheme.radiusControl, style: .continuous)
                    .fill(configuration.isPressed
                          ? SMTheme.border.opacity(0.45)
                          : Color(nsColor: .controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: SMTheme.radiusControl, style: .continuous)
                    .strokeBorder(SMTheme.border.opacity(0.65), lineWidth: 0.5)
            )
            .opacity(configuration.isPressed ? 0.9 : 1)
    }
}

struct SMProminentButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.callout, design: .default).weight(.semibold))
            .foregroundStyle(Color.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: SMTheme.radiusControl, style: .continuous)
                    .fill(configuration.isPressed ? SMTheme.accent.opacity(0.82) : SMTheme.accent)
            )
            .opacity(configuration.isPressed ? 0.92 : 1)
    }
}

extension View {
    func smBorderedButton() -> some View { buttonStyle(SMBorderedButtonStyle()) }
    func smProminentButton() -> some View { buttonStyle(SMProminentButtonStyle()) }
}
