import SwiftUI

/// Navy + emerald utility chrome (ui-ux-pro-max design-system for pro audio console).
/// Explicitly rejects purple-on-white, OLED-default black, Inter/Roboto stacks.
enum SMTheme {
    static let background = Color(red: 0.973, green: 0.980, blue: 0.988) // #F8FAFC
    static let surface = Color.white
    static let ink = Color(red: 0.118, green: 0.227, blue: 0.373) // #1E3A5F navy
    static let muted = Color(red: 0.278, green: 0.333, blue: 0.412) // #475569
    static let border = Color(red: 0.894, green: 0.906, blue: 0.922) // #E4E7EB
    static let accent = Color(red: 0.020, green: 0.588, blue: 0.412) // #059669 emerald
    static let accentSoft = Color(red: 0.020, green: 0.588, blue: 0.412).opacity(0.12)
    static let danger = Color(red: 0.863, green: 0.149, blue: 0.149) // #DC2626
    static let bypass = Color(red: 0.720, green: 0.420, blue: 0.090)
    static let warning = Color(red: 0.710, green: 0.400, blue: 0.090)

    /// Dense console spacing (design dial density 8).
    static let spaceXS: CGFloat = 6
    static let spaceSM: CGFloat = 10
    static let spaceMD: CGFloat = 14
    static let spaceLG: CGFloat = 20

    static let titleFont = Font.system(size: 26, weight: .bold, design: .default)
    static let headlineFont = Font.system(size: 17, weight: .semibold, design: .default)
    static let bodyFont = Font.system(.body, design: .default)
    static let captionFont = Font.system(.caption, design: .default)
    static let monoCaption = Font.system(.caption, design: .monospaced)

    static func panelBackground() -> some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(surface)
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(border, lineWidth: 1)
            )
    }
}
