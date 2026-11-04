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

func badgeLanguages() -> [String] {
    (UserDefaults.standard.string(forKey: K.badgeLanguages) ?? "").split(separator: ",").map(String.init)
}

final class InputSources: ObservableObject {
    static let shared = InputSources()
    @Published private(set) var sources = enabledInputSources()

    private init() {
        if UserDefaults.standard.string(forKey: K.badgeLanguages) == nil {
            addLanguages(languages)
        }
        DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name(kTISNotifyEnabledKeyboardInputSourcesChanged as String),
            object: nil, queue: .main
        ) { _ in
            MainActor.assumeIsolated {
                let shared = InputSources.shared
                let old = shared.languages
                shared.sources = enabledInputSources()
                shared.addLanguages(shared.languages.filter { !old.contains($0) })
            }
        }
    }

    private var languages: [String] {
        var langs: [String] = []
        for source in sources where !source.lang.isEmpty && !langs.contains(source.lang) {
            langs.append(source.lang)
        }
        return langs
    }

    func reload() {
        sources = enabledInputSources()
        addLanguages(languages)
    }

    private func addLanguages(_ langs: [String]) {
        let list = badgeLanguages()
        let missing = langs.filter { !list.contains($0) }
        guard !missing.isEmpty else { return }
        UserDefaults.standard.set((list + missing).joined(separator: ","), forKey: K.badgeLanguages)
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
