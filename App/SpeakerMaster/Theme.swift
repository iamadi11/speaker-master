import SwiftUI

/// Light graphite + teal utility chrome (ui-ux-pro-max search adapted;
/// rejected purple-on-white / OLED-default / Inter biases).
enum SMTheme {
    static let background = Color(red: 0.96, green: 0.97, blue: 0.97) // #F5F7F7
    static let surface = Color.white
    static let ink = Color(red: 0.10, green: 0.14, blue: 0.16) // #1A2429
    static let muted = Color(red: 0.35, green: 0.42, blue: 0.45)
    static let border = Color(red: 0.86, green: 0.89, blue: 0.90)
    static let accent = Color(red: 0.05, green: 0.58, blue: 0.53) // teal #0D9488
    static let accentSoft = Color(red: 0.05, green: 0.58, blue: 0.53).opacity(0.12)
    static let danger = Color(red: 0.75, green: 0.22, blue: 0.17)
    static let bypass = Color(red: 0.72, green: 0.45, blue: 0.10)

    static let titleFont = Font.system(.largeTitle, design: .rounded).weight(.bold)
    static let headlineFont = Font.system(.title2, design: .rounded).weight(.semibold)
    static let bodyFont = Font.system(.body, design: .default)
    static let captionFont = Font.system(.caption, design: .default)
}
