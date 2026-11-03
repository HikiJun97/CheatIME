import SwiftUI

enum K {
    static let visible = "visible"
    static let displayMode = "displayMode"
    static let displays = "displays"
    static let shape = "shape"
    static let fontSize = "fontSize"
    static let opacity = "opacity"
    static let glass = "glass"
    static let hAlign = "hAlign"
    static let vAlign = "vAlign"
    static let marginX = "marginX"
    static let marginY = "marginY"
    static func label(_ lang: String) -> String { "lang.\(lang).label" }
    static func bg(_ lang: String) -> String { "lang.\(lang).bg" }
    static func fg(_ lang: String) -> String { "lang.\(lang).fg" }
    static func hidden(_ lang: String) -> String { "lang.\(lang).hidden" }
}

func registerDefaults() {
    UserDefaults.standard.register(defaults: [
        K.visible: true, K.displayMode: "all", K.displays: "", K.shape: "rounded",
        K.fontSize: 15.0, K.opacity: 0.9, K.glass: false,
        K.hAlign: "right", K.vAlign: "bottom", K.marginX: 12.0, K.marginY: 12.0,
    ])
}

func langDefaults(_ lang: String) -> (label: String, bg: String, fg: String) {
    switch lang {
    case "ko": return ("한", "#E53935", "#FFFFFF")
    case "ja": return ("あ", "#8E44AD", "#FFFFFF")
    case "en": return ("EN", "#404040", "#FFFFFF")
    default: return (String(lang.prefix { $0 != "-" }).uppercased(), "#808080", "#FFFFFF")
    }
}

extension Color {
    init(hex: String) {
        let v = Int(hex.dropFirst(), radix: 16) ?? 0
        self.init(.sRGB, red: Double(v >> 16 & 0xFF) / 255,
                  green: Double(v >> 8 & 0xFF) / 255, blue: Double(v & 0xFF) / 255)
    }

    var hex: String {
        guard let c = NSColor(self).usingColorSpace(.sRGB) else { return "#000000" }
        return String(format: "#%02X%02X%02X", Int(round(c.redComponent * 255)),
                      Int(round(c.greenComponent * 255)), Int(round(c.blueComponent * 255)))
    }
}
