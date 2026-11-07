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
    static let badgeWidth = "badgeWidth"
    static let cornerRadius = "cornerRadius"
    static let content = "content"
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
    static let snapToEdges = "snapToEdges"
    static let settingsTab = "settingsTab"
    static let showFixed = "showFixed"
    static let showPointer = "showPointer"
    static let showCaret = "showCaret"
    static let caretFallback = "caretFallback"
    static let flashOnly = "flashOnly"
    static let flashDuration = "flashDuration"
    static let styleTarget = "styleTarget"
    static let toggleKey = "toggleKey"
    static let toggleModifiers = "toggleModifiers"
    static let modes = ["fixed", "pointer", "caret"]
    static let styleKeys = [content, shape, fontSize, badgeSize, dotSize, badgeWidth, cornerRadius, opacity, glass, border, borderWidth, borderColor, flashOnly, flashDuration]
    static func style(_ scope: String, _ key: String) -> String { "\(scope).\(key)" }
    static func useDefault(_ mode: String) -> String { "\(mode).useDefault" }
    static func show(_ mode: String) -> String {
        switch mode {
        case "fixed": showFixed
        case "pointer": showPointer
        default: showCaret
        }
    }
    static func direction(_ mode: String) -> String { "\(mode).direction" }
    static func gapX(_ mode: String) -> String { "\(mode).gapX" }
    static func gapY(_ mode: String) -> String { "\(mode).gapY" }
    static func flip(_ mode: String) -> String { "\(mode).flip" }
    static func label(_ lang: String) -> String { "lang.\(lang).label" }
    static func bg(_ lang: String) -> String { "lang.\(lang).bg" }
    static func fg(_ lang: String) -> String { "lang.\(lang).fg" }
    static func hidden(_ lang: String) -> String { "lang.\(lang).hidden" }
    static func modeColors(_ lang: String) -> String { "lang.\(lang).modeColors" }
    static func modeLabel(_ id: String) -> String { "mode.\(id).label" }
    static func modeBg(_ id: String) -> String { "mode.\(id).bg" }
    static func modeFg(_ id: String) -> String { "mode.\(id).fg" }
    static func modeHidden(_ id: String) -> String { "mode.\(id).hidden" }
    static func modeFlag(_ id: String) -> String { "mode.\(id).flag" }
}

func registerDefaults() {
    let d = UserDefaults.standard
    let mode = d.string(forKey: K.positionMode) ?? "fixed"
    var defaults: [String: Any] = [
        K.visible: true, K.displayMode: "all", K.displays: "", K.sound: false, K.rules: "[]", K.appFilter: false,
        K.filterApps: "", K.soundName: "Tink", K.hAlign: "left", K.vAlign: "bottom", K.marginX: 12.0, K.marginY: 12.0,
        K.snapToEdges: true, K.settingsTab: "badge", K.styleTarget: "default", K.toggleKey: -1, K.toggleModifiers: 0,
        K.showFixed: mode == "fixed", K.showPointer: mode == "pointer", K.showCaret: mode == "caret", K.caretFallback: true,
        K.direction("pointer"): "bottomRight", K.gapX("pointer"): 16.0, K.gapY("pointer"): 16.0, K.flip("pointer"): false,
        K.direction("caret"): "right", K.gapX("caret"): 6.0, K.gapY("caret"): 6.0, K.flip("caret"): false,
    ]
    let style: [String: Any] = [
        K.content: "text", K.shape: "rounded", K.fontSize: 16.0, K.badgeSize: 29.0, K.dotSize: 12.0, K.badgeWidth: 0.0, K.cornerRadius: 22.0, K.opacity: 0.9, K.glass: false,
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

func defaultLabel(_ source: InputSourceInfo) -> String {
    let fallback = langDefaults(source.lang).label
    let legacy = UserDefaults.standard.string(forKey: K.label(source.lang)).flatMap { $0 == fallback ? nil : $0 }
    return legacy ?? systemLabels[source.mode] ?? fallback
}

func badgeLook(_ source: InputSourceInfo) -> (label: String, bg: String, fg: String, hidden: Bool) {
    let d = UserDefaults.standard
    let l = langDefaults(source.lang)
    let bg = d.string(forKey: K.bg(source.lang)) ?? l.bg
    let fg = d.string(forKey: K.fg(source.lang)) ?? l.fg
    let own = d.bool(forKey: K.modeColors(source.lang))
    return (d.string(forKey: K.modeLabel(source.id)) ?? defaultLabel(source),
            own ? d.string(forKey: K.modeBg(source.id)) ?? bg : bg,
            own ? d.string(forKey: K.modeFg(source.id)) ?? fg : fg,
            d.object(forKey: K.modeHidden(source.id)) as? Bool ?? d.bool(forKey: K.hidden(source.lang)))
}

func defaultRegion(_ lang: String) -> String? {
    let region = Locale(identifier: Locale.Language(identifier: lang).maximalIdentifier).region?.identifier
    return region.flatMap { flagFile($0, square: false) == nil ? nil : $0 }
}

func modeRegion(_ source: InputSourceInfo) -> String? {
    UserDefaults.standard.string(forKey: K.modeFlag(source.id)) ?? defaultRegion(source.lang)
}

private func flagFile(_ region: String, square: Bool) -> URL? {
    Bundle.main.url(forResource: region.lowercased(), withExtension: "png", subdirectory: square ? "flags/1x1" : "flags/4x3")
}

private var flagImages: [String: NSImage] = [:]

func flagImage(_ region: String, square: Bool = false, icon: Bool = false) -> NSImage? {
    let key = "\(region.lowercased()) \(square) \(icon)"
    if let image = flagImages[key] { return image }
    guard let url = flagFile(region, square: square), let image = NSImage(contentsOf: url) else { return nil }
    if icon { image.size = NSSize(width: 20, height: 15) }
    flagImages[key] = image
    return image
}

let flagRegions: [(code: String, name: String)] = Locale.Region.isoRegions
    .filter { flagFile($0.identifier, square: false) != nil }
    .map { ($0.identifier, Locale.current.localizedString(forRegionCode: $0.identifier) ?? $0.identifier) }
    .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }

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

struct Placement {
    static let directions = ["topLeft", "top", "topRight", "left", "", "right", "bottomLeft", "bottom", "bottomRight"]

    var h: Int
    var v: Int
    var gapX: Double
    var gapY: Double
    var flip: Bool

    init(direction: String, gapX: Double, gapY: Double, flip: Bool) {
        let index = Placement.directions.firstIndex(of: direction) ?? 8
        h = index % 3 - 1
        v = 1 - index / 3
        self.gapX = gapX
        self.gapY = gapY
        self.flip = flip
    }

    init(mode: String) {
        let d = UserDefaults.standard
        self.init(direction: d.string(forKey: K.direction(mode)) ?? "bottomRight", gapX: d.double(forKey: K.gapX(mode)),
                  gapY: d.double(forKey: K.gapY(mode)), flip: d.bool(forKey: K.flip(mode)))
    }

    func origin(around a: CGRect, size: CGSize) -> CGPoint {
        let x = switch h {
        case 1: a.maxX + gapX
        case -1: a.minX - gapX - size.width
        default: a.midX - size.width / 2
        }
        let y = switch v {
        case 1: a.maxY + gapY
        case -1: a.minY - gapY - size.height
        default: a.midY - size.height / 2
        }
        return CGPoint(x: x, y: y)
    }
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
