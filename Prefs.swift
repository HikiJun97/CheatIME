import SwiftUI

enum K {
    static let visible = "visible"
    static let positionMode = "positionMode"
    static let displayMode = "displayMode"
    static let displays = "displays"
    static let shape = "shape"
    static let fontSize = "fontSize"
    static let badgeSize = "badgeSize"
    static let badgeSizeMigrated = "badgeSizeMigrated"
    static let dotSize = "dotSize"
    static let border = "border"
    static let borderWidth = "borderWidth"
    static let borderColor = "borderColor"
    static let opacity = "opacity"
    static let glass = "glass"
    static let appFilter = "appFilter"
    static let filterApps = "filterApps"
    static let badgeLanguages = "badgeLanguages"
    static let rules = "rules"
    static let sound = "sound"
    static let soundName = "soundName"
    static let hAlign = "hAlign"
    static let vAlign = "vAlign"
    static let marginX = "marginX"
    static let marginY = "marginY"
    static let settingsTab = "settingsTab"
    static let showFixed = "showFixed"
    static let showPointer = "showPointer"
    static let showCaret = "showCaret"
    static let caretFallback = "caretFallback"
    static let flashOnly = "flashOnly"
    static let flashDuration = "flashDuration"
    static let styleTarget = "styleTarget"
    static let modes = ["fixed", "pointer", "caret"]
    static let styleKeys = [shape, fontSize, badgeSize, dotSize, opacity, glass, border, borderWidth, borderColor, flashOnly, flashDuration]
    static func style(_ scope: String, _ key: String) -> String { "\(scope).\(key)" }
    static func useDefault(_ mode: String) -> String { "\(mode).useDefault" }
    static func show(_ mode: String) -> String {
        switch mode {
        case "fixed": showFixed
        case "pointer": showPointer
        default: showCaret
        }
    }
    static func label(_ lang: String) -> String { "lang.\(lang).label" }
    static func bg(_ lang: String) -> String { "lang.\(lang).bg" }
    static func fg(_ lang: String) -> String { "lang.\(lang).fg" }
    static func hidden(_ lang: String) -> String { "lang.\(lang).hidden" }
}

func registerDefaults() {
    let d = UserDefaults.standard
    let mode = d.string(forKey: K.positionMode) ?? "fixed"
    var defaults: [String: Any] = [
        K.visible: true, K.displayMode: "all", K.displays: "", K.sound: false, K.rules: "[]", K.appFilter: false,
        K.filterApps: "", K.soundName: "Tink", K.hAlign: "left", K.vAlign: "bottom", K.marginX: 12.0, K.marginY: 12.0,
        K.settingsTab: "badge", K.styleTarget: "default",
        K.showFixed: mode == "fixed", K.showPointer: mode == "pointer", K.showCaret: mode == "caret", K.caretFallback: true,
    ]
    let style: [String: Any] = [
        K.shape: "rounded", K.fontSize: 16.0, K.badgeSize: 29.0, K.dotSize: 12.0, K.opacity: 0.9, K.glass: false,
        K.border: "none", K.borderWidth: 2.0, K.borderColor: "#FFFFFF", K.flashOnly: false, K.flashDuration: 1200.0,
    ]
    let migrateBadgeSize = !d.bool(forKey: K.badgeSizeMigrated)
    for scope in ["default"] + K.modes {
        for (key, value) in style { defaults[K.style(scope, key)] = d.object(forKey: key) ?? value }
        let badgeSize = K.style(scope, K.badgeSize)
        if migrateBadgeSize, d.object(forKey: badgeSize) == nil,
           let fontSize = (d.object(forKey: K.style(scope, K.fontSize)) ?? d.object(forKey: K.fontSize)) as? Double {
            d.set((fontSize * 1.8).rounded(), forKey: badgeSize)
        }
    }
    d.set(true, forKey: K.badgeSizeMigrated)
    for m in K.modes { defaults[K.useDefault(m)] = true }
    d.register(defaults: defaults)
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

func systemSounds() -> [String] {
    let files = (try? FileManager.default.contentsOfDirectory(atPath: "/System/Library/Sounds")) ?? []
    return files.map { ($0 as NSString).deletingPathExtension }.sorted()
}

func styleScope(_ mode: String) -> String {
    UserDefaults.standard.bool(forKey: K.useDefault(mode)) ? "default" : mode
}

func copyDefaultStyle(to mode: String) {
    let d = UserDefaults.standard
    let saved = d.persistentDomain(forName: Bundle.main.bundleIdentifier ?? ProcessInfo.processInfo.processName) ?? [:]
    for key in K.styleKeys where saved[K.style(mode, key)] == nil {
        d.set(d.object(forKey: K.style("default", key)), forKey: K.style(mode, key))
    }
}
