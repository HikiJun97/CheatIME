import Cocoa
import Carbon

func property<T>(_ src: TISInputSource, _ key: CFString) -> T? {
    guard let ptr = TISGetInputSourceProperty(src, key) else { return nil }
    return Unmanaged<AnyObject>.fromOpaque(ptr).takeUnretainedValue() as? T
}

func currentLanguage() -> String {
    let src = TISCopyCurrentKeyboardInputSource().takeRetainedValue()
    let langs: [String] = property(src, kTISPropertyInputSourceLanguages) ?? []
    return langs.first ?? ""
}

func enabledLanguages() -> [String] {
    let list = TISCreateInputSourceList(nil, false).takeRetainedValue() as! [TISInputSource]
    var langs: [String] = []
    for src in list {
        let category: String? = property(src, kTISPropertyInputSourceCategory)
        let selectable: Bool = property(src, kTISPropertyInputSourceIsSelectCapable) ?? false
        let srcLangs: [String] = property(src, kTISPropertyInputSourceLanguages) ?? []
        guard category == kTISCategoryKeyboardInputSource as String, selectable,
              let lang = srcLangs.first, !langs.contains(lang) else { continue }
        langs.append(lang)
    }
    return langs
}

struct InputSourceInfo: Hashable {
    let id: String
    let name: String
    let lang: String
}

func enabledInputSources() -> [InputSourceInfo] {
    let list = TISCreateInputSourceList(nil, false).takeRetainedValue() as! [TISInputSource]
    return list.compactMap { src in
        let category: String? = property(src, kTISPropertyInputSourceCategory)
        let selectable: Bool = property(src, kTISPropertyInputSourceIsSelectCapable) ?? false
        guard category == kTISCategoryKeyboardInputSource as String, selectable,
              let id: String = property(src, kTISPropertyInputSourceID) else { return nil }
        let langs: [String] = property(src, kTISPropertyInputSourceLanguages) ?? []
        return InputSourceInfo(id: id, name: property(src, kTISPropertyLocalizedName) ?? id, lang: langs.first ?? "")
    }
}

func currentInputSourceID() -> String {
    property(TISCopyCurrentKeyboardInputSource().takeRetainedValue(), kTISPropertyInputSourceID) ?? ""
}

func selectInputSource(_ id: String) {
    guard id != currentInputSourceID() else { return }
    let filter = [kTISPropertyInputSourceID as String: id] as CFDictionary
    let list = TISCreateInputSourceList(filter, false).takeRetainedValue() as! [TISInputSource]
    if let src = list.first { TISSelectInputSource(src) }
}

extension NSScreen {
    var uuid: String {
        let id = deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as! CGDirectDisplayID
        guard let cf = CGDisplayCreateUUIDFromDisplayID(id)?.takeRetainedValue() else { return "\(id)" }
        return CFUUIDCreateString(nil, cf) as String
    }
}
