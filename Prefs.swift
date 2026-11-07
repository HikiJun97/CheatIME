import SwiftUI

struct Pref<Value>: AnyPref {
    let key: String
    let value: Value

    init(_ key: String, _ value: Value) {
        self.key = key
        self.value = value
    }

    var stored: Any { (value as? any RawRepresentable)?.rawValue ?? value }
}

protocol AnyPref {
    var key: String { get }
    var stored: Any { get }
}

extension UserDefaults {
    subscript<V>(_ p: Pref<V>) -> V {
        get {
            let raw = object(forKey: p.key)
            guard let type = V.self as? any RawRepresentable.Type else { return raw as? V ?? p.value }
            return decode(type, raw) as? V ?? p.value
        }
        set { set((newValue as? any RawRepresentable)?.rawValue ?? newValue, forKey: p.key) }
    }
}

private func decode<R: RawRepresentable>(_ type: R.Type, _ raw: Any?) -> R? {
    (raw as? R.RawValue).flatMap { R(rawValue: $0) }
}

func savedSettings() -> [String: Any] {
    UserDefaults.standard.persistentDomain(forName: Bundle.main.bundleIdentifier ?? ProcessInfo.processInfo.processName) ?? [:]
}

extension AppStorage {
    init(_ p: Pref<Value>) where Value == Bool { self.init(wrappedValue: p.value, p.key) }
    init(_ p: Pref<Value>) where Value == Int { self.init(wrappedValue: p.value, p.key) }
    init(_ p: Pref<Value>) where Value == Double { self.init(wrappedValue: p.value, p.key) }
    init(_ p: Pref<Value>) where Value == String { self.init(wrappedValue: p.value, p.key) }
    init(_ p: Pref<Value>) where Value: RawRepresentable, Value.RawValue == String {
        self.init(wrappedValue: p.value, p.key)
    }
}

enum Mode: String, CaseIterable {
    case fixed, pointer, caret
}

enum DisplayMode: String {
    case all, mouse, selected
}

enum HAlign: String {
    case left, center, right
}

enum VAlign: String {
    case top, middle, bottom
}

enum BadgeContent: String {
    case text, flag
}

enum BadgeShape: String {
    case rounded, capsule, circle, dot, custom
}

enum BorderStyle: String {
    case none, solid, dashed, dotted
}

enum K {
    static let visible = Pref("visible", true)
    static let displayMode = Pref("displayMode", DisplayMode.all)
    static let displays = Pref("displays", "")
    static let appFilter = Pref("appFilter", false)
    static let filterApps = Pref("filterApps", "")
    static let rules = Pref("rules", "[]")
    static let sound = Pref("sound", false)
    static let soundName = Pref("soundName", "Tink")
    static let hAlign = Pref("hAlign", HAlign.left)
    static let vAlign = Pref("vAlign", VAlign.bottom)
    static let marginX = Pref("marginX", 12.0)
    static let marginY = Pref("marginY", 12.0)
    static let snapToEdges = Pref("snapToEdges", true)
    static let caretFallback = Pref("caretFallback", true)
    static let toggleKey = Pref("toggleKey", -1)
    static let toggleModifiers = Pref("toggleModifiers", 0)
    static let settingsTab = Pref("settingsTab", "badge")
    static let styleTarget = Pref("styleTarget", "default")
    static let badgeLanguages = "badgeLanguages"
    static let badgeSizeMigrated = "badgeSizeMigrated"
    static let positionMode = "positionMode"

    static let content = Pref("content", BadgeContent.text)
    static let shape = Pref("shape", BadgeShape.rounded)
    static let fontSize = Pref("fontSize", 16.0)
    static let badgeSize = Pref("badgeSize", 29.0)
    static let dotSize = Pref("dotSize", 12.0)
    static let badgeWidth = Pref("badgeWidth", 0.0)
    static let cornerRadius = Pref("cornerRadius", 22.0)
    static let opacity = Pref("opacity", 0.9)
    static let glass = Pref("glass", false)
    static let border = Pref("border", BorderStyle.none)
    static let borderWidth = Pref("borderWidth", 2.0)
    static let borderColor = Pref("borderColor", "#FFFFFF")
    static let flashOnly = Pref("flashOnly", false)
    static let flashDuration = Pref("flashDuration", 1200.0)
    static let styleKeys: [any AnyPref] = [content, shape, fontSize, badgeSize, dotSize, badgeWidth, cornerRadius, opacity, glass, border, borderWidth, borderColor, flashOnly, flashDuration]
    static let scopes = ["default"] + Mode.allCases.map(\.rawValue)

    static func styleKey(_ scope: String, _ key: String) -> String { "\(scope).\(key)" }
    static func style<V>(_ scope: String, _ p: Pref<V>) -> Pref<V> { Pref(styleKey(scope, p.key), p.value) }
    static func useDefault(_ mode: Mode) -> Pref<Bool> { Pref("\(mode.rawValue).useDefault", true) }
    static func show(_ mode: Mode) -> Pref<Bool> {
        switch mode {
        case .fixed: Pref("showFixed", true)
        case .pointer: Pref("showPointer", false)
        case .caret: Pref("showCaret", false)
        }
    }
    static func direction(_ mode: Mode) -> Pref<String> { Pref("\(mode.rawValue).direction", mode == .caret ? "right" : "bottomRight") }
    static func gapX(_ mode: Mode) -> Pref<Double> { Pref("\(mode.rawValue).gapX", mode == .caret ? 6.0 : 16.0) }
    static func gapY(_ mode: Mode) -> Pref<Double> { Pref("\(mode.rawValue).gapY", mode == .caret ? 6.0 : 16.0) }
    static func flip(_ mode: Mode) -> Pref<Bool> { Pref("\(mode.rawValue).flip", false) }
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

    static let portable: [String: Any] = {
        var prefs: [any AnyPref] = [visible, displayMode, displays, appFilter, filterApps, rules, sound, soundName,
                                    hAlign, vAlign, marginX, marginY, snapToEdges, caretFallback, toggleKey, toggleModifiers]
        for mode in Mode.allCases {
            prefs += [useDefault(mode), show(mode), direction(mode), gapX(mode), gapY(mode), flip(mode)] as [any AnyPref]
        }
        var all: [String: Any] = [:]
        for p in prefs { all[p.key] = p.stored }
        for p in styleKeys {
            all[p.key] = p.stored
            for scope in scopes { all[styleKey(scope, p.key)] = p.stored }
        }
        all[badgeLanguages] = ""
        all[badgeSizeMigrated] = false
        all[positionMode] = ""
        return all
    }()
}

func migrate() {
    let d = UserDefaults.standard
    var saved = savedSettings()
    if let mode = saved[K.positionMode] as? String {
        for m in Mode.allCases where saved[K.show(m).key] == nil {
            d.set(m.rawValue == mode, forKey: K.show(m).key)
        }
        d.removeObject(forKey: K.positionMode)
    }
    let ownStyle = ["default"] + Mode.allCases.filter { !(saved[K.useDefault($0).key] as? Bool ?? true) }.map(\.rawValue)
    for p in K.styleKeys {
        guard let legacy = saved[p.key] else { continue }
        for scope in ownStyle where saved[K.styleKey(scope, p.key)] == nil {
            d.set(legacy, forKey: K.styleKey(scope, p.key))
        }
        d.removeObject(forKey: p.key)
    }
    saved = savedSettings()
    if !(saved[K.badgeSizeMigrated] as? Bool ?? false) {
        for scope in K.scopes {
            let badgeSize = K.styleKey(scope, K.badgeSize.key)
            if saved[badgeSize] == nil, let fontSize = saved[K.styleKey(scope, K.fontSize.key)] as? Double {
                d.set((fontSize * 1.8).rounded(), forKey: badgeSize)
            }
        }
        d.set(true, forKey: K.badgeSizeMigrated)
    }
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

    init(mode: Mode) {
        let d = UserDefaults.standard
        self.init(direction: d[K.direction(mode)], gapX: d[K.gapX(mode)], gapY: d[K.gapY(mode)], flip: d[K.flip(mode)])
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

func styleScope(_ mode: Mode) -> String {
    UserDefaults.standard[K.useDefault(mode)] ? "default" : mode.rawValue
}

func copyDefaultStyle(to mode: Mode) {
    let d = UserDefaults.standard
    let saved = savedSettings()
    for p in K.styleKeys where saved[K.styleKey(mode.rawValue, p.key)] == nil {
        d.set(d.object(forKey: K.styleKey("default", p.key)) ?? p.stored, forKey: K.styleKey(mode.rawValue, p.key))
    }
}
