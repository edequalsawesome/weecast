import AppKit
import SwiftUI

/// Pins the frozen Catppuccin Mocha and Latte semantic palette.
@main
@MainActor
struct AppearanceTests {
    static var failures = 0
    static var passes = 0

    static func check(_ label: String, _ ok: Bool, _ detail: String = "") {
        if ok {
            passes += 1
        } else {
            failures += 1
            print("FAIL  \(label)\(detail.isEmpty ? "" : ": \(detail)")")
        }
    }

    /// Quantized to the 8 bits that reach the framebuffer: `CGFloat`s carry Float error.
    static func components(_ color: Color, _ name: NSAppearance.Name) -> [Int] {
        var out: [Int] = []
        NSAppearance(named: name)!.performAsCurrentDrawingAppearance {
            let ns = NSColor(color).usingColorSpace(.sRGB)!
            out = [ns.redComponent, ns.greenComponent, ns.blueComponent, ns.alphaComponent]
                .map { Int(($0 * 255).rounded()) }
        }
        return out
    }

    static func palette(_ label: String, _ token: Color, dark: [Int], light: [Int]) {
        let actualDark = components(token, .darkAqua)
        let actualLight = components(token, .aqua)
        check("dark \(label)", actualDark == dark, "\(actualDark) != \(dark)")
        check("light \(label)", actualLight == light, "\(actualLight) != \(light)")
    }

    /// A token that resolves identically in both never adapted at all.
    static func adapts(_ label: String, _ token: Color) {
        check(
            "\(label) adapts", components(token, .darkAqua) != components(token, .aqua),
            "light resolves identically to dark")
    }

    static func composite(_ token: Color, _ appearance: NSAppearance.Name, over: [Double]) -> [Double] {
        let rgba = components(token, appearance).map { Double($0) / 255 }
        return zip(rgba.prefix(3), over).map { $0 * rgba[3] + $1 * (1 - rgba[3]) }
    }

    static func contrast(_ first: [Double], _ second: [Double]) -> Double {
        func luminance(_ rgb: [Double]) -> Double {
            let linear = rgb.map { $0 <= 0.04045 ? $0 / 12.92 : pow(($0 + 0.055) / 1.055, 2.4) }
            return linear[0] * 0.2126 + linear[1] * 0.7152 + linear[2] * 0.0722
        }
        let first = luminance(first)
        let second = luminance(second)
        return (max(first, second) + 0.05) / (min(first, second) + 0.05)
    }

    static func textContrast() {
        print("# readable text on Catppuccin Base and selected rows")
        let appearances: [(String, NSAppearance.Name, [Double])] = [
            ("Mocha", .darkAqua, [30, 30, 46]), ("Latte", .aqua, [239, 241, 245])
        ]
        for (name, appearance, bytes) in appearances {
            let base = bytes.map { $0 / 255 }
            let success = composite(Theme.Colors.success, appearance, over: base)
            check("\(name) inserted text >= 4.5:1", contrast(success, base) >= 4.5)
            for opacity in [0.16, 0.20, 0.24] {
                let fill = composite(Theme.Colors.destructive.opacity(opacity), appearance, over: base)
                let label = composite(Theme.Colors.textPrimary, appearance, over: fill)
                check("\(name) destructive button label at \(opacity) >= 4.5:1", contrast(label, fill) >= 4.5)
            }
            let rest = composite(Theme.Colors.controlSurface, appearance, over: base)
            let hoverControl = composite(Theme.Colors.controlHover, appearance, over: base)
            let pressed = composite(Theme.Colors.controlPressed, appearance, over: base)
            check("\(name) control hover differs from rest >= 1.1:1", contrast(rest, hoverControl) >= 1.1)
            check("\(name) control press differs from hover >= 1.1:1", contrast(hoverControl, pressed) >= 1.1)
            for (state, fill) in [("rest", rest), ("hover", hoverControl), ("pressed", pressed)] {
                let label = composite(Color.primary, appearance, over: fill)
                check("\(name) cancel label at \(state) >= 4.5:1", contrast(label, fill) >= 4.5)
            }
            let selected = composite(Theme.Colors.selection, appearance, over: base)
            let selectedCard = composite(Theme.Colors.cardFill, appearance, over: selected)
            for (surface, background) in [
                ("Base", base), ("selection", selected), ("selected card", selectedCard)
            ] {
                for (label, token) in [
                    ("secondary", Theme.Colors.textSecondary), ("tertiary", Theme.Colors.textTertiary)
                ] {
                    let ratio = contrast(composite(token, appearance, over: background), background)
                    check("\(name) \(label) on \(surface) >= 4.5:1", ratio >= 4.5,
                          String(format: "%.2f:1", ratio))
                }
                let border = composite(Theme.Colors.selectionBorder, appearance, over: background)
                let ratio = contrast(border, background)
                check("\(name) selection border on \(surface) >= 3:1", ratio >= 3,
                      String(format: "%.2f:1", ratio))
            }
            let hover = composite(Theme.Colors.rowHover, appearance, over: base)
            check("\(name) selection fill stays stronger than hover",
                  contrast(selected, base) > contrast(hover, base))
        }
    }

    static func main() {
        let c = Theme.Colors.self

        textContrast()
        palette("dialogDimming", c.dialogDimming, dark: [0, 0, 0, 87], light: [0, 0, 0, 87])
        palette("tooltipShadow", c.tooltipShadow, dark: [0, 0, 0, 46], light: [0, 0, 0, 46])

        print("# Catppuccin Mocha and Latte semantic tokens")
        palette("panelScrim", c.panelScrim, dark: [30, 30, 46, 184], light: [239, 241, 245, 184])
        palette("selection", c.selection, dark: [69, 71, 90, 115], light: [188, 192, 204, 115])
        palette("selectionBorder", c.selectionBorder,
                dark: [203, 166, 247, 255], light: [136, 57, 239, 255])
        palette("rowHover", c.rowHover, dark: [49, 50, 68, 148], light: [204, 208, 218, 148])
        palette("emojiCell", c.emojiCell, dark: [49, 50, 68, 148], light: [204, 208, 218, 148])
        palette("menuHover", c.menuHover, dark: [69, 71, 90, 173], light: [188, 192, 204, 173])
        palette("separator", c.separator, dark: [88, 91, 112, 140], light: [172, 176, 190, 140])
        palette("cardStroke", c.cardStroke, dark: [88, 91, 112, 140], light: [172, 176, 190, 140])
        palette("controlSurface", c.controlSurface, dark: [69, 71, 90, 158], light: [188, 192, 204, 158])
        palette("border", c.border, dark: [88, 91, 112, 199], light: [172, 176, 190, 199])
        palette("textPrimary", c.textPrimary, dark: [205, 214, 244, 255], light: [76, 79, 105, 255])
        palette("textSecondary", c.textSecondary, dark: [186, 194, 222, 255], light: [92, 95, 119, 255])
        palette("textTertiary", c.textTertiary, dark: [166, 173, 200, 255], light: [92, 95, 119, 255])
        palette("noteText", c.noteText, dark: [205, 214, 244, 230], light: [76, 79, 105, 230])
        palette("iconPlaceholder", c.iconPlaceholder, dark: [24, 24, 37, 140], light: [230, 233, 239, 140])
        palette("sheen", c.sheen, dark: [24, 24, 37, 102], light: [230, 233, 239, 102])
        palette("cardFill", c.cardFill, dark: [24, 24, 37, 133], light: [230, 233, 239, 133])
        palette("glassFrost", c.glassFrost, dark: [49, 50, 68, 82], light: [204, 208, 218, 82])
        palette("brand", c.brand, dark: [203, 166, 247, 255], light: [136, 57, 239, 255])
        palette("dropGuideArmed", c.dropGuideArmed, dark: [137, 180, 250, 255], light: [30, 102, 245, 255])
        palette("progress", c.progress, dark: [137, 180, 250, 255], light: [30, 102, 245, 255])
        palette("destructive", c.destructive, dark: [243, 139, 168, 255], light: [210, 15, 57, 255])
        palette("success", c.success, dark: [166, 227, 161, 255], light: [44, 112, 30, 255])

        print("# every surface token resolves per appearance")
        for (label, token) in [
            ("panelScrim", c.panelScrim), ("selection", c.selection), ("rowHover", c.rowHover),
            ("menuHover", c.menuHover), ("separator", c.separator),
            ("controlSurface", c.controlSurface), ("border", c.border),
            ("textPrimary", c.textPrimary), ("textSecondary", c.textSecondary),
            ("textTertiary", c.textTertiary), ("noteText", c.noteText), ("cardFill", c.cardFill),
            ("cardStroke", c.cardStroke), ("dropGuide", c.dropGuide),
            ("iconPlaceholder", c.iconPlaceholder), ("sheen", c.sheen)
        ] {
            adapts(label, token)
        }

        print("# the scrim keeps its appearance-specific Catppuccin base")
        check("light scrim is Latte Base", components(c.panelScrim, .aqua).prefix(3) == [239, 241, 245])
        check("dark scrim is Mocha Base", components(c.panelScrim, .darkAqua).prefix(3) == [30, 30, 46])

        check("frost uses Latte Surface0", components(c.glassFrost, .aqua).prefix(3) == [204, 208, 218])

        print("# .system hands the choice back to AppKit")
        check("system is nil", AppAppearance.system.nsAppearance == nil)
        check("light is aqua", AppAppearance.light.nsAppearance?.isDark == false)
        check("dark is darkAqua", AppAppearance.dark.nsAppearance?.isDark == true)
        check("an unknown stored value is rejected", AppAppearance(rawValue: "sepia") == nil)

        print("\n\(passes) passed, \(failures) failed")
        exit(failures == 0 ? 0 : 1)
    }
}
